# vSphere Pods for Agent Workloads — Honest Evaluation & Product Plan

**Owner:** Sachi Bhatt, VCF Workloads and Consumption Product Management
**Date:** September 2026
**Status:** Draft for internal review — grounded in live Confluence/Jira/GitHub pulls (2026-09-15) plus the Aug 2026 GTM plan and leadership brief. Every claim below is sourced; items I could not confirm are marked ⚠️ rather than smoothed over.
**Related:** `agent-sandbox-gtm.md`, `agent-sandbox-leadership-brief.md` (Aug 2026 GTM), `supervisor-2.0-rearchitecture.md`, `supervisor-2.0-customer-value-by-release.md`

---

## 0. The one finding that changes the plan

**The roadmap-commitment decision has not been made.** The Aug 2026 leadership brief said: *"Commit a roadmap slot and engineering investment in VCF 9.1.2... Decision needed before Explore Las Vegas (Aug 31)."* Checking the actual tracking ticket today:

- **VGL-68198**, "vSphere Agent Sandbox Runtime with vSphere pods" — status **Proposed**, no fixVersion, last updated **2026-09-08**. A sibling ticket VGL-68199 (same title, created same day) is **Canceled**.

Six weeks past the stated decision deadline, there is still no committed fixVersion. Everything in Section 3 (GTM) and most of Section 4 (improve vSphere Pods) is downstream of this not having happened. This isn't a new risk — it's the risk the leadership brief already named, now materialized. **Forcing this decision is the single highest-leverage action in this document**, ahead of any technical work below.

---

## 1. Where vSphere Pods stands today, honestly

### What actually works
- CRX-based hardware isolation on ESXi, running as a native Supervisor Service — no nested virtualization, which is a real structural advantage over Kata-on-VKS (nesting a hypervisor inside a VM has real performance/capability cost that vSphere Pods simply don't pay).
- A working demo: warm pool, claim, and suspend, running today against the upstream `kubernetes-sigs/agent-sandbox` v0.5.2 operator as a Carvel-packaged Supervisor Service (`vcf/agent-sandbox` repo). This is real, not a mockup.
- Native DRA request-side compatibility is architecturally clean: because a PodVM *is* a pod, it references a `ResourceClaim` exactly like any other pod — no special request-surface work needed, unlike VM Service (confirmed in the "Phase-3: DRA for PodVMs" design, Confluence 2529993876).

### What doesn't — and hasn't moved since August
- **Hibernation and resume: still not built.** I found zero Jira tickets and zero GitHub commits addressing this. The `vcf/agent-sandbox` repo's last commit was Aug 25, 2026 ("Sandbox proxy") — nothing in three weeks, and nothing in the commit history ever mentions hibernation or resume. This is the single capability the Aug plan said the durable-agent pitch depends on most, and it is not visibly being worked.
- **Backup/DR: nominally exists, confirmed broken in practice.** Contrary to my own earlier note that "vSphere Pods have no backup story at all" — that was too strong. Velero-for-vSphere *can* target Supervisor workloads including PodVMs, and it's listed on the community Supervisor-Services catalog. But a first-hand internal engineer's install log (Confluence 2381581333, dated Dec 2025) found the required **Data Mover component "not fit for purpose"**: old Photon OS 3.0 base, a hard DHCP requirement, incorrect vendor documentation, and container security issues needing manual workarounds — concluding *"without a Data Mover, it will not be possible to do backup/restore of supervisor workloads for the foreseeable."* An embedded replacement Data Mover is rumored for ~9.1.1 but I found no confirmation it shipped. Velero also isn't listed as a Supervisor Service in the official docs at all — the same public-catalog/reality mismatch pattern found elsewhere (ArgoCD).
- **No continuous log streaming.** The logfetcher path is pull-only (`kubectl logs`-style, on-demand), not a continuous stream a DevOps persona could wire into Fluent Bit or similar. Unchanged from prior research.
- **GPU/device access today = static only.** On the current platform (Supervisor 1.0 / PodVM v1), DRA claim *resolution* is native, but the actual GPU driver is baked into a pre-built image — there is no dynamic, per-claim driver provisioning. Fine for a known, fixed device/driver combination; not viable for flexible AI workloads that need different accelerators per claim.
- **Cold boot remains 9–18s** against Firecracker competitors at 5–30ms. The Aug plan's call to stop competing on speed and lead with durability stands — but durability's centerpiece (hibernation/resume) is the thing not moving.
- **Roadmap commitment: still open** (Section 0).

### Competitive position, unchanged in substance
Red Hat shipped a Technology-Preview build of upstream Agent Sandbox with Kata isolation in July 2026 and remains the most urgent on-prem competitor, though their own operator not yet being GA likely widens the window versus the original "2-4 quarters" estimate. Firecracker (under AWS AgentCore and E2B) has two real 2026 CVEs (CVE-2026-5747, CVE-2026-1386) — useful, concrete evidence that microVM isolation isn't immune to host-escape-class bugs either. GCP's GKE Agent Sandbox + air-gapped GDC remains a medium-term tripwire, not an active fire.

**Bottom line on "how effectively can I run an agent on VCF with vSphere Pods today":** you can run a short-to-medium-lived, CPU-only agent workload with real hardware isolation and a working warm-pool/claim/suspend lifecycle. You cannot yet run a durable, GPU-backed, backed-up, observable agent workload — every one of those four things is either unbuilt, broken, or static-only. The pitch in the Aug GTM plan ("we win on durability") is currently a claim about direction, not present capability.

---

## 2. Post-9.2 (PodVM v2 + Supervisor 2.0): what actually changes

Grounded in the **PodVM v2 Overall Architecture** doc (Confluence 2429236635, status "ready for review and sign-off" as of today, target VCF 9.2).

### Real, credible gains
- PodVM moves off CRX to a regular VM with `directBoot` (tied to new virtual hardware version HWv23, ESXi 9.2+) — this is what unlocks vMotion, HA, and eventually BYOK.
- The **virtual node** abstraction (one virtual node = one vCenter cluster, not one ESXi host) is the mechanism that makes vMotion/HA possible without breaking Kubernetes' "a pod doesn't change nodes" rule.
- DRA's request side needs no new work for PodVMs specifically, because a PodVM is already a pod — the architecture explicitly aims for **one DRA object model shared across VM Service, PodVMs, and VKS pods** (Confluence 2529993876). This is the real technical seed of the "VKS + vSphere Pods" unified story — see Section 4C.

### Real new costs, stated plainly in the architecture doc itself — not spin
- **Per-pod memory overhead increases.** CRX page-sharing (sharing memory pages between PodVMs on the same host) cannot be preserved once OS images live on datastore instead of ESXi's in-memory filesystem. The doc calls this out directly and defers the fix to "the future."
- **DaemonSet semantics change.** "One pod per node" now means one pod per *virtual node* (i.e., per vCenter cluster), not per ESXi host. Any workload depending on true per-host daemon placement can no longer be satisfied.
- **Node-aware schedulers are explicitly flagged as at-risk.** The doc names RunAI (with KAI Scheduler) and Volcano by name as operators that could be "negatively impacted" by the virtual-node abstraction, since they reason about Kubernetes nodes mapping to physical hosts.
- **Concurrent v1/v2 support is unavoidable and adds real scheduling complexity** during the upgrade window (mixed ESXi versions), including a sub-optimal fallback scheduling path based on stale `allocatable` capacity rather than live DRS scoring.

### What 9.2 does **not** solve — despite being adjacent to it
- **GPU/DRA is a Phase-3 *proposal*, not a shipping capability**, and it is honest about that. It depends on components that **do not exist yet**: an "AH Consolidated Entry Point" needing separate team commitment, a new shared "DRA Device Translator Controller," and an extended `PlaceVmsXCluster` DRS contract. It has **named, unsolved problems**: the "GPU-operator-equivalent" driver-staging/matching problem, the from-VKS resolution path (VKS's own scheduler can't see Supervisor's virtual nodes today), and anti-fragmentation scoring is explicitly "out of scope, noted as future work." Scope is also hard-limited to **attach-at-power-on only** (no hot-add/remove) and **single-vCenter only**. This is architecturally sound but multiple committed dependencies away from production.
- **Backup/restore is not redesigned.** A page literally titled "PodVM v2 backup info" contains no backup-specific design — it's general v2 architecture notes. Backup/restore for v2 remains a stated goal to reach *v1 parity*, and v1's actual backup story is the broken Data Mover from Section 1.
- **Multi-vCenter support for PodVMs is still deferred, and the two source documents don't fully agree on where.** The customer-value doc lists it as a 9.2 non-goal "deferred to the separate PodVM v2 effort"; the PodVM v2 architecture doc says multi-VC is "out of scope for this architecture, dealt with as part of Supervisor 2.0." Read together: **neither document currently owns landing this**, and it should not be assumed solved at 9.2 GA.
- **Whether the general VKS Add-on catalog (Velero, cert-manager, Harbor, etc.) becomes reachable for vSphere Pod workloads is unconfirmed either way** — I found no page or ticket addressing it directly. Treat as still open, not closed.
- **Virtual-node granularity is a configurable property with no assigned owner or exposed UX.** The architecture doc fixes "1 virtual node = 1 vCenter cluster" for 9.2 but explicitly says the design is kept flexible to map a node to a different set of hosts "in the future" — i.e., this boundary is meant to be configurable, eventually. The doc never says who sets it or how. This isn't a hypothetical persona question: the choice directly determines what a Platform/Provider Admin sees as node capacity, DaemonSet behavior, and scheduler behavior (per the doc's own persona-impact section), while the underlying hosts/clusters being grouped are VI Admin's domain. Same unresolved seam as the Supervisor activation Northstar work (`Supervisor Activation Northstar - One Pager.md`) — a config decision straddling both personas with no structured input surface for either, today defaulting silently to 1:1 with no visibility for whoever isn't the one who happens to click it.

**Net honest read:** 9.2/PodVM v2 is a real, necessary architectural unlock (mobility, ESXi decoupling, a shared DRA object model) that also introduces new regressions (memory overhead, DaemonSet/scheduler compatibility) and does **not** by itself deliver GPU-backed, backed-up, multi-vCenter-resilient agent workloads. Those require additional, currently uncommitted work layered on top.

---

## 2A. Competitive intelligence: hard numbers (snapshot 2026-09-15, not continuously monitored)

| Dimension | vSphere Pods v1 (today) | vSphere Pods v2 (post-9.2) | Firecracker (E2B / AWS AgentCore) | Kata Containers (Red Hat Agent Sandbox) | gVisor (GKE Agent Sandbox) |
|---|---|---|---|---|---|
| **Memory overhead/pod** | No published number. CRX page-sharing reduces per-host overhead but nothing quantified externally | No published number — architecture doc confirms overhead **increases** (page-sharing lost), direction known, magnitude not | ≤5 MiB VMM overhead officially; 2026 benchmarks show 5–15MB/instance | 100–200MiB/pod for guest kernel+agent alone; real-world total 600–1200MB per container vs. 200–600MB for runc | ~130–200MB/pod in one benchmark; separately, <1% CPU overhead for 70% of workloads |
| **Backup/restore** | Nominal Velero path; Data Mover confirmed broken internally (stale OS, DHCP dependency) — no working backup today | Not redesigned — still targets v1 parity, i.e. the same broken component | No K8s-level backup concept; sandboxes are ephemeral by design | Ordinary K8s pod to Velero/CSI — standard backup, zero special integration | Same as Kata — ordinary pod semantics, standard backup, no special integration |
| **HA / failure recovery** | None — host failure = pod lost, cold reschedule elsewhere | **vMotion + HA — genuine live migration**, no restart. New failure mode: control-channel TCP session drops and must reconnect via a new VC ticket post-migration | None — restart-from-snapshot elsewhere, not live migration | **None** — live migration has been an open GitHub issue (kata-containers #1690) since inception; CRIU checkpoint/restore not supported at the runtime level either | None — same reschedule-and-restart; no VM to migrate |
| **Cold-start / TTE** | ~9–18s (internal figure only, no external benchmark) | Not yet measurable, unshipped | ≤125ms to userspace officially; 5–30ms with snapshot-restore (E2B managed), ~150ms in one methodology | 150–300ms boot overhead beyond standard container start; ~125ms specifically with Firecracker VMM | 100–300ms in one source; a differently-configured benchmark shows 444–684ms — slower than Docker's 378–571ms in that same test |
| **Warm-pool mitigated start** | Internal claim: "closes much of the gap," no external number | n/a | Snapshot-restore already serves this role | Red Hat's own claim: "near-instant... milliseconds" | Sub-second to a few seconds; Google claims 300 sandboxes/sec sub-second |

**Memory:** no number to put in a deck, and the one thing we do know is it's moving the wrong direction in v2. Firecracker's single-digit-MB overhead is not a fight any VM-based approach wins, including ours — that's architecture, not execution.

**Backup:** the sharpest structural gap, not just a bug. A vSphere Pod is a real VMDK-backed VM under the hood, so it needs a VMware-specific Data Mover to get data to a backup target — and that specific piece is confirmed broken. Kata and gVisor pods are indistinguishable from any other Kubernetes pod to Velero — zero special integration, ever. Fixing the Data Mover gets us to parity at best; we will never have Kata/gVisor's "it's just a pod" simplicity here, because we aren't just a pod.

**HA:** the one dimension where v2 is set up to be genuinely ahead, not behind. Live migration exists in no competitor's product today — Kata's live-migration request has been open since inception, and none of Firecracker/Kata/gVisor do anything beyond "throw it away and start a new one." If PodVM vMotion proves reliable, this is a real, hard-to-copy differentiator — but it's unshipped, and our own architecture doc already flags a new reconnect failure mode that needs proving before this goes external.

**Cold-start:** the least favorable comparison, and it isn't close. 9–18s is roughly 30–150x slower than Firecracker's raw boot and still an order of magnitude behind Kata's VM-based 150–300ms. Every competitor already closes most of this gap with warm pools, same as us — but the underlying architecture is heavier by a wide margin, and nothing in the PodVM v2 design targets boot speed (its priorities are mobility and ESXi decoupling).

Sources: [Firecracker SPECIFICATION.md](https://github.com/firecracker-microvm/firecracker/blob/main/SPECIFICATION.md), [AgentCore Firecracker boot analysis](https://www.akshayparkhi.net/2026/Mar/11/how-firecracker-microvms-power-agentcore-runtime-from-125ms-boot/), [Kata vs gVisor — Northflank](https://northflank.com/blog/kata-containers-vs-gvisor), [Kata performance measurements](https://github.com/c3d/kata-performance-measurements), [Pod Overhead and RuntimeClass deep dive](https://adhdecode.com/containers-kubernetes/pods/pod-overhead-runtimeclass/), [gVisor Performance Guide](https://gvisor.dev/docs/architecture_guide/performance/), [gVisor usenix cost study](https://www.usenix.org/system/files/hotcloud19-paper-young.pdf), [Velero CSI docs](https://velero.io/docs/v1.6/csi/), [Kata live migration issue #1690](https://github.com/kata-containers/kata-containers/issues/1690), [Kata CRIU discussion](https://github.com/kata-containers/kata-containers/discussions/10385), [E2B breakdown](https://memo.d.foundation/breakdown/e2b), [PandaStack Firecracker boot](https://www.pandastack.ai/blog/how-firecracker-boots-fast/), [Red Hat build of Agent Sandbox](https://developers.redhat.com/articles/2026/07/15/red-hat-build-agent-sandbox-isolated-workload-management-kubernetes), [Red Hat two-sandbox benchmark data](https://developers.redhat.com/articles/2026/07/23/why-your-ai-agent-needs-two-sandboxes-benchmark-data), [GKE Agent Sandbox docs](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/machine-learning/agent-sandbox), [InfoQ GKE Agent Sandbox announcement](https://www.infoq.com/news/2026/05/gke-agent-sandbox-hypercluster/).

---

## 2B. Can we leverage VM Fork / Instant Clone for faster provisioning? Not OOB.

Checked directly against the "PodVM V2 VM Features" design doc (Confluence 2464569676, backing Jira epics **PI-263** "Add DirectBoot Support to Regular VM" and **VMCOMM-206** "Secure Communication channel for outside ESXi to VM" — both P0-Blocker, In Progress, VCF 9.2).

- **Instant Clone is on an unproven interop test list, not a committed capability.** It's grouped with vMotion/svMotion/xVMotion, linked clone, checkpoint save/restore, and FT as operations that still need to be *tested* against the new directBoot/HWv23 model. The doc's own words: *"If any of these operations are found to not be compatible with directBoot VMs, are not straightforward to fix, and are not required by PodVM v2, then we will block them."* — engineering's stated fallback is to disable it, not force it through, if it's hard.
- **One known behavior is already a gap, not a green light.** For vMotion, the guest-side vsock proxy connection is checkpointed and restored automatically at the destination. For Instant Clone specifically: *"the VMCI connection will be disconnected at the destination"* — a cloned child does not inherit the parent's live connection; it needs a fresh one.
- **Neither backing epic (PI-263, VMCOMM-206) is scoped around Instant Clone** — it's a line item inside broader DirectBoot/proxy-channel work, no dedicated ticket or owner.
- **Beyond base compatibility, actually using it as a warm-pool provisioning mechanism (à la Horizon's instant-clone VDI desktops) is a separate, larger, unscoped effort**: virtual node controller/schedext/image controller would need a new "fork from running parent" provisioning path, and Instant Clone's standard guest-customization flow relies on VMware Tools re-configuring network identity post-fork — PodVM's minimal directBoot init+agent stack isn't a standard guest OS with Tools, so the in-guest agent would likely need new Instant-Clone-aware logic itself.

**Bottom line:** two layers of unbuilt work, neither committed — (1) prove/fix base VM-op compatibility, currently unconfirmed and could be blocked, and (2) build the PodVM-specific integration to use it as a fast-provisioning primitive, not scoped anywhere. Don't assume this is available for the cold-start problem in Section 2A without a dedicated ask.

---

## 3. Part A — Expose vSphere Pods as Agent Sandbox

The Aug 2026 GTM plan and leadership brief already lay out a sound two-track structure (Track A: product/GTM on our release train; Track B: community/standards on the upstream project's calendar, gated only by A4's native-K8s work landing before B4's recognition ask). That structure holds. What's changed since August:

1. **The roadmap slot has not been secured** (Section 0) — this blocks A3 (productize for 9.1.2) and therefore A4/A5 and the entire community-recognition dependency chain in Track B. Recommend re-raising this as a forcing decision now, not a re-pitch — the technology hasn't regressed, the internal clock has just run past the date leadership itself set.
2. **Positioning discipline still holds and should be reinforced, not revisited:** lead with durability (pause/snapshot/compliance-boundary/existing-infra), not speed; keep the nested-virtualization argument as the headline differentiator against Kata-on-VKS; keep community recognition in Track B with no ship date attached.
3. **A new, sharper argument for urgency:** the gap between what we're *saying* (durable, hibernation-capable agent sandbox) and what's *built* (no hibernation, broken backup, static-only GPU) is now wider than it was in August, not narrower — every month the roadmap slot doesn't land, the credibility cost of the eventual launch claim goes up, not down.
4. **Business model decision is still open** and still blocking the 9.1.2 launch review per the leadership brief — no new information found here; still needs a call before launch.

---

## 4. Part B — Improve vSphere Pods: a concrete backlog

Ranked by what's actually blocking the Agent Sandbox pitch, using the specific gaps found above rather than generic hardening language:

1. **Hibernation and resume.** No visible engineering movement. This is the top item — without it, the "durable agent" positioning has no product behind it. Needs its own committed workstream, not a line item inside a broader productization ask.
2. **A real backup path — an owner and a funded initiative already exist, but scope needs confirming.** **VSPDP-46111** ("Enable 3P backup vendors to take VM service VM & VKS workload backup on VCF," P0-Blocker, fixVersion 9.1.3.0, owned by **Jatin Jindal**) is actively targeting exactly the broken component — its stated requirement is literally "Data mover placement in supervisor." A related initiative, **IDEAS-6046** (VKS backup via native vSAN snapshots, flagged internally as Adoption-Blocker/Deal-breaker with a named customer, United Airlines), is also his. **But neither ticket names vSphere Pods or PodVM anywhere — both are explicitly scoped to "VKS workload" and "VM service VM."** Don't assume PodVM backup rides along with this work just because it's the same underlying Data Mover component — that's the same "assumed covered, wasn't" pattern found elsewhere in this research (VGL-12694, VGL-69195). The concrete ask: confirm directly with Jatin's team whether VSPDP-46111's Data Mover scope covers or can be extended to cover PodVM backup specifically; if not, PodVM backup needs its own line item inside that same initiative, not a new one from scratch.
3. **GPU/DRA to production, named piece by piece.** The Phase-3 design is sound but lists its own missing dependencies explicitly — use that list as the backlog: (a) commit the AH team to build the Consolidated Entry Point, (b) build the shared DRA Device Translator Controller, (c) solve the from-VKS claim-resolution problem (VKS scheduler seeing Supervisor's virtual nodes), (d) solve GPU driver staging/matching ("the GPU-operator-equivalent problem"). Don't let this get positioned as "coming in 9.2" — it depends on 9.2 but isn't part of it.
4. **Continuous log streaming**, replacing the pull-only logfetcher — unchanged ask from prior research, still real.
5. **Warm pool / productization hardening** (controller hardening for production load, host-level image caching, upgrade/lifecycle handling, documented scale limits) — I found no tracked Jira evidence either confirming or denying progress here; needs a direct status check with engineering rather than being assumed done or not-started.
6. **Node-aware scheduler compatibility for the virtual-node model.** RunAI/KAI Scheduler and Volcano are named at-risk in the architecture doc itself — if either matters to target agent-platform customers (many AI/ML platform teams already run one of these), this needs an explicit compatibility plan before 9.2 GA, not a post-GA surprise.
7. **Assign an owner and a UX surface for virtual-node granularity.** Right now this is a configurable property (per the architecture doc's own stated future-flexibility goal) with no named persona and no exposed configuration path. Push this back to the PodVM v2 architecture team as a structured input question — VI Admin supplies the cluster topology, Platform/Provider Admin should own the granularity decision, mirroring the persona split proposed for Supervisor activation generally.
8. **Scope VM Fork/Instant Clone as its own ask, adjacent to PI-263.** Not currently OOB or committed (Section 2B) — base compatibility with directBoot is unproven and could be blocked by engineering's own stated fallback, and using it as an actual warm-pool provisioning primitive is a separate, unscoped integration effort on top. Worth a dedicated feasibility spike given the size of the cold-start gap in Section 2A, but shouldn't be assumed as a free win.

---

## 5. Part C — The VKS + vSphere Pods unified story

This has a firmer technical foundation than it did in August. The Aug plan's A5 ("converge pods and VM Service into one substrate... one ESXi-native runtime with two API surfaces") was framed as a future aspiration. The **Phase-3 DRA architecture makes this concrete today**: it explicitly designs **one shared object model — `ResourceClaim`, `ResourceSlice`, `DeviceClass` — across VM Service VMs, PodVMs, and VKS pods**, with a single Translator Controller serving all three. That's not marketing language; it's a cited, in-progress design decision.

Recommended framing for the unified story:
- **Today's pitch:** VKS gives you a full Kubernetes cluster experience; vSphere Pods give you hardware-isolated, cluster-less pods directly on Supervisor. Different consumption shapes, same substrate.
- **The 9.2+ pitch, backed by the DRA design:** a platform engineer requests a device the same way — one `DeviceClass`, one `ResourceClaim` — whether the workload lands as a VKS pod, a PodVM, or eventually a VM Service VM. The device inventory, the admin-defined device types, and (per the design) eventually the driver/environment provisioning are unified underneath. This is the "one platform, multiple API surfaces" story, and unlike in August, there's now a specific architecture doc to point to rather than a direction to promise.
- **Caveat to carry into any customer-facing version of this:** the from-VKS half of this story (creating a PodVM with a device claim *from inside* a VKS cluster) is explicitly the harder, still-unsolved half of the design — don't let the pitch imply parity between the two creation paths until that's actually resolved.

---

## 6. Risks

1. **The roadmap-commitment decision keeps not happening.** This is no longer a hypothetical risk from the Aug brief — it's an observed fact six weeks past the stated deadline. If it doesn't get forced now, everything else in this document is contingent planning for work that may never be funded.
2. **Positioning-reality gap widening.** The durability pitch depends on hibernation/resume, which shows no visible progress. Continuing to lead with durability externally while this stays unbuilt increases the credibility risk the Aug brief already warned about.
3. **GPU story is easy to oversell.** The Phase-3 design is genuinely good architecture, but it names its own unbuilt dependencies and open problems. Any customer- or leadership-facing summary of "GPU support is coming" needs the same precision the design doc itself uses — don't let "designed" become "planned" become "shipping" through successive retellings.
4. **Backup path can be miscommunicated as solved because a funded initiative exists.** VSPDP-46111 (Jatin Jindal, P0-Blocker, 9.1.3.0) is real and actively targeting the Data Mover — but its explicit scope is VKS and VM Service VM, not PodVM. Treat "backup is being fixed" as true only for those two workload types until PodVM is explicitly confirmed in scope.
5. **Virtual-node scheduler compatibility could surface late.** RunAI/Volcano risk is flagged in the architecture doc but has no owner or mitigation plan yet that I could find.

---

## 7. Recommended immediate next steps

1. **Force the roadmap-commitment decision on VGL-68198** — it's the blocker upstream of everything else here. Bring the "six weeks past your own deadline" fact directly to whoever owns that call.
2. **Ask Jatin Jindal's team directly whether VSPDP-46111 covers or can be extended to cover PodVM backup** — its current stated scope is VKS and VM Service VM only. Confirm before repeating "backup is being fixed" for vSphere Pods anywhere.
3. **Get hibernation/resume onto a tracked ticket with an owner** — right now it exists only as a stated gap in a slide deck, not as engineering work I could find evidence of.
4. **Scope the GPU/DRA dependency list (Section 4.3) as its own cross-team ask** to the AH team and DRS team, since the design doc itself says this needs their commitment to even start.
5. **Ask the RunAI/Volcano compatibility question explicitly** to whoever owns Supervisor 2.0 scheduling — before it's discovered by a customer.

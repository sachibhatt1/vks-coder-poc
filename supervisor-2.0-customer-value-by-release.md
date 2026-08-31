# Supervisor 2.0 — Customer-Facing Value by Persona and Release

**Owner:** Sachi Bhatt, VCF Workloads and Consumption Product Management
**Audience:** Customer-facing (VI Admin, Platform Engineering, cross-cutting/multi-vCenter)
**Companion doc:** [supervisor-2.0-rearchitecture.md](./supervisor-2.0-rearchitecture.md) (slide-deck version of this same content)
**Sources:** VMware Confluence, WCP space — retrieved 2026-08-10 directly via live search/page-fetch (not from a prior pasted table). Cited inline per row.
**Status:** Grounded in source pages below. Items marked ⚠️ need your confirmation before this goes external.

---

## How to read this

- **9.2** content comes from the Supervisor 2.0 architecture one-pager and its sub-documents. This is the committed scope for the CAPI/VKS rearchitecture.
- **9.1.3** content is a *separate, adjacent* initiative — control-plane efficiency/resilience work on the *existing* (pre-rearchitecture) Supervisor control plane. It is **not** part of Supervisor 2.0. Per its own source page, the 9.1.3 items are "deliberately not filed yet" as Jira stories and scope is still pending confirmation once the 9.1.2 cycle closes — treat this column as **proposed/roadmap, not committed**, until you confirm otherwise.
- Only **VI Admin** has 9.1.3-scoped content. I found nothing 9.1.3-scoped for Platform Engineering or the multi-vCenter capability — every source page for those scopes the work explicitly to VCF 9.2. This isn't a gap in my search; it's what the source says.

---

## Executive summary

| Persona | 9.1.3 | 9.2 |
|---|---|---|
| **VI Admin** | Control-plane efficiency/resilience hardening (⚠️ proposed, not yet committed) | Declarative CAPI upgrades, `supervisor-adm` CLI, automated credential/service-account management |
| **Platform Engineering** | — (nothing found) | Kubernetes-native config (K8s API is source of truth), native GitOps, VKS Addons for all controllers, Worker VM K8s nodes |
| **Cross-cutting: Multi-vCenter** | — (nothing found) | Supervisor control plane spans multiple vCenters; VC-agnostic Storage/VM Image/Zone abstractions; single-VC outage no longer takes down the whole control plane |

---

## VI Admin

### 9.2 — Supervisor 2.0 rearchitecture

Source: *[One-Pager] Supervisor 2.0* (Confluence 2420129172), *[One Pager] Supervisor 2.0 compatibility* (2474483024)

| Capability | Supervisor 1.0 (before) | Supervisor 2.0 (after) |
|---|---|---|
| Upgrade mechanism | `wcpsvc`/EAM-driven, bespoke scripts | Bump the K8s version in the Supervisor's CAPI `Cluster` CR — VKS rolls out new Control Plane and Worker VMs the same way it upgrades any VKS workload cluster |
| Admin interface | `wcpsvc` VAPI only | `supervisor-adm` — a new component that is the front end for one-shot admin operations (**Enable, Disable, Recover, RegisterVC, UnregisterVC, support-bundle collection**). Packaged with VCSA for the single-VC case, but independently hostable; core logic ships as reusable Go packages so it can be embedded in the VAPI handler, a VCF CLI plugin, or run standalone |
| Credential handling | — | CPVM root credentials for break-glass operations are held in VC (single-VC case) or a fleet-level VCF layer (multi-VC case) — not scripted around |
| VC trust establishment | Manual | `supervisor-adm` orchestrates initial mutual trust (VC LookupService registration); a new `supervisor-agent` daemon runs per-VC, watches Supervisor K8s resources that need VC-side realization (e.g. service accounts, AZ resource pools), validates CR signatures, and realizes them locally |
| Brownfield upgrade (1.0 → 2.0) | N/A | Requires VC 9.2 and a minimum starting Supervisor 1.0 version (**"SV1.5"**). `wcpsvc` instructs EAM to relinquish existing CPVMs; a "Brownfielder" job performs "VKSification" — creates a CAPI `Cluster`, adopts the existing CPVMs as CAPI nodes, then rolls a normal upgrade to Supervisor 2.0 images |
| Config source of truth | VCDB | Migrating toward the Supervisor's own K8s API (see Platform Engineering section — this is the same underlying shift) |

**Non-goals explicitly confirmed for 9.2** (so nothing overpromises to customers): no multi-SDDC admin UI; no administration via `wcpsvc`/VAPI alone (must go through `supervisor-adm` + direct K8s APIs); no upgrade path from a VC older than 9.2; no bootstrap directly on ESXi without a VC.

### 9.1.3 — Control-Plane Efficiency & Resilience (⚠️ adjacent initiative — proposed, not Supervisor 2.0)

Source: *Control-Plane Efficiency & Resilience — Release Roadmap (9.1.2 / 9.1.3)* (Confluence 2538316245)

This is a separate, non-Supervisor-2.0 initiative hardening the **existing** control plane. It's included here because it's the only genuinely 9.1.3-scoped, VI-Admin-relevant customer value I could find in source material — not because it's part of the CAPI rearchitecture. The source page is deep internal engineering detail (Jira-ticket-level); I've translated it to customer-facing framing below, but **the underlying Jira stories for 9.1.3 are explicitly not filed yet** — the page states 9.1.3 scope will be "confirmed against what the 9.1.2 measurements show" only after the 9.1.2 cycle closes.

| Capability | Value (customer framing) | Source detail |
|---|---|---|
| Reduced etcd/control-plane bloat *(already landed in 9.1.2, foundation for 9.1.3)* | Smaller, healthier etcd footprint under normal operation | A single policy fix cut the etcd database size **from 400+ MB to 76 MB (~97% reduction)** by removing a Kyverno reload policy that was the largest single source of etcd fragmentation |
| Right-sized medium-cluster control planes ⚠️ proposed | Reduces risk of control-plane memory pressure/OOM as a "medium"-sized Supervisor scales — today it runs on the same memory budget as "small" despite ~2× the load | Adds a dedicated `medium` sizing branch (apiserver memory limit/`GOMEMLIMIT`, corrected memory *requests*) instead of sharing "small"'s budget |
| Custom traffic prioritization (APF tuning) ⚠️ proposed | Lowers the chance that a burst of control-plane traffic starves critical operations (e.g. leader election) during high load | Introduces VMSP-specific `FlowSchema`/`PriorityLevelConfiguration` objects so the control plane's own traffic is isolated from generic upstream defaults |
| Fewer per-node watches ⚠️ proposed | Reduces steady-state control-plane load driven purely by node count | Addresses kubelet holding a live watch per mounted ConfigMap/Secret per node — currently 35–39% of all long-running watches on HA clusters |
| Bounded resource growth ⚠️ proposed | Prevents unbounded growth in etcd/watch-cache size from accumulated completed workloads | Adds a bound on terminated-pod garbage collection (currently unset, so pods accumulate indefinitely) |
| Reduced Secret data cached on node disk ⚠️ proposed, flagged for security review in-source | Narrows a data-at-rest exposure — full Secret payloads are currently cached to node-local disk outside etcd encryption | Adds filtering/stripping to the per-node agent's local object cache |

---

## Platform Engineering

### 9.2 — Kubernetes-native, GitOps-ready control plane

Source: *[One-Pager] Supervisor 2.0* (Confluence 2420129172)

| Capability | Supervisor 1.0 (before) | Supervisor 2.0 (after) |
|---|---|---|
| Config source of truth | Opaque, lives in VCDB | The Supervisor's own K8s API — `kubectl`-readable, exportable, backed by a full audit trail |
| GitOps | No native path (no `kubectl` access to config) | Works natively — standard Flux/ArgoCD workflows apply directly, since config is real Kubernetes state |
| Controller/operator lifecycle | Custom EAM APIs | All Supervisor operators packaged and managed as **VKS Addons** via the VKS Addons framework — same tooling platform teams already use for VKS guest clusters |
| Cluster LCM stack | Three separate stacks (VKS/CAPI+CAPV, `wcpsvc`/EAM, `vmsp`/CAPI+CAPV in govmomi mode) | Deduplicated onto one: VKS/CAPI manages Supervisor's own lifecycle too |
| Worker nodes | PodVMs only | **Infrastructure Supervisor** adds Worker VMs joining as real Linux K8s nodes (Antrea CNI, standard node behavior) for densely-packed infra services — regular K8s pods, not PodVMs |

**Non-goals explicitly confirmed for 9.2:** a single Supervisor cannot mix Linux-K8s-pods-on-Worker-VMs with PodVMs (Worker VMs are Infrastructure-Supervisor-only in 9.2); Worker-VM-based pods are not hard-tenant-isolated, so they're not positioned for multi-tenant workloads yet.

### 9.1.3 — nothing found

I found no 9.1.3-scoped Platform Engineering content anywhere in the Supervisor 2.0 source material, and the wider 9.1.3 search turned up only unrelated items (VKS Cluster Insights, Telco Cloud, third-party VM backup). Flag if you know of a specific 9.1.3 Platform Engineering item to look up.

---

## Cross-cutting: Multi-vCenter as a platform capability

### 9.2 — Supervisor spans multiple vCenters

Source: *[One-Pager] Supervisor 2.0* (Confluence 2420129172)

| Capability | Supervisor 1.0 (before) | Supervisor 2.0 (after) |
|---|---|---|
| Topology | 1:1 with a single VC Datacenter | A VC is added to an existing Supervisor as a Day-2 `RegisterVC` operation — one Supervisor spans multiple VC Datacenters/SDDCs ⚠️ *your earlier draft stated a specific "up to 3 vCenters" cap; I could not re-locate that number in today's source search — confirm before using it in a customer deck* |
| Resilience | A single VC outage takes down the entire control plane | Goal is to "eliminate VC as a single point of failure" — Supervisor control plane VMs, VM Service VMs, PodVMs, and VKS nodes can spread across vSphere Zones from different VCs |
| Storage | StorageClass is VC-scoped | A single StorageClass can be backed by similar storage policies grouped across multiple VCs/SDDCs |
| VM Images | Content Library is VC-scoped — same content on two VCs creates duplicate image resources and pins workload placement to one VC | VM images from matching Content Library items across VCs are grouped into a single unified image resource; VM Operator resolves the correct VC-scoped item at placement time |
| Workload placement | N/A | A new **VC Placement Operator** exposes a placement API — `vm-operator` calls it to get a VC recommendation before normal DRS-based Zone/cluster selection runs |
| Networking | Requires stretched L2 across vSphere clusters | Goal is to eliminate the stretched-L2 requirement for both Supervisor management and workload networks (not NSX-overlay-dependent) |

**Non-goals explicitly confirmed for 9.2:** no multi-SDDC admin UI; a single vSphere Zone cannot span multiple vSphere clusters from different VCs; PodVMs are not supported in a multi-SDDC Supervisor (deferred to the separate PodVM v2 effort); zones with the same name can't be registered to the same Supervisor across different SDDCs.

⚠️ **Still unconfirmed (carried over from the prior draft):** whether VKS **guest-cluster** control-plane nodes (not just Supervisor's own CPVMs) also get spread across these vCenters for HA. The One-Pager documents multi-VC placement for Supervisor's own control plane and VM Operator-managed VMs, but does not explicitly extend that HA claim to VKS guest clusters.

### 9.1.3 — nothing found

Same as Platform Engineering: no 9.1.3-scoped multi-vCenter content in source material.

---

## Open items to confirm before this goes external

1. **The 9.1.3 column is proposed, not committed.** Jira stories aren't filed yet; confirm before presenting any 9.1.3 row to a customer.
2. **"Up to 3 vCenters"** — verify this cap against a current source; I couldn't re-confirm it today.
3. **VKS guest-cluster HA across multiple vCenters** — confirm with the architecture team whether this is in scope or a separate capability.
4. Additional Supervisor 2.0 source pages I did not fully read for this table (found but not fetched in depth): *Design: Control Plane Zone Selection for VKS and Supervisor 2.0* (2474411026), *Supervisor 2.0 Unified APIs* (2434528349), *VC upgrade to 9.2 with Supervisor 2.0* (2429582964), *Notes: Easy Supervisor 2.0* (2453617506), *9.2 Supervisor 2.0* (2482570238) — worth a pass if you want more depth on any single row above.
5. Jira (`vmw-jira`) was disconnected for this pass — re-run `/mcp` and I can cross-check fixVersion tags on the epics/stories behind these one-pagers for additional precision.

---

## Sources

- *[One-Pager] Supervisor 2.0* — Confluence 2420129172
- *[One Pager] Supervisor 2.0 compatibility* — Confluence 2474483024
- *Control-Plane Efficiency & Resilience — Release Roadmap (9.1.2 / 9.1.3)* — Confluence 2538316245
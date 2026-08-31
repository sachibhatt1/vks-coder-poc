# Supervisor 2.0 Rearchitecture — Customer Roadmap Deck

**Companion doc:** [supervisor-2.0-customer-value-by-release.md](./supervisor-2.0-customer-value-by-release.md) — same persona benefits, organized as a comprehensive table by release (9.1.3 / 9.2), pulled live from Confluence source
**Owner:** Sachi Bhatt, VCF Workloads and Consumption Product Management
**Audience:** Customer-facing
**Format target:** 5–6 slides max, in the VMware by Broadcom branded template
**Presentation style reference:** vSphere Pods as Agent deck (persona/value cards, before/after tables, phased timeline with release milestones)
**Content source:** Confluence WCP space — Supervisor 2.0 architecture one-pagers + decision register (retrieved Aug 5, 2026), pasted 2026-08-10

Status: **draft — grounded in your Confluence source, but a few claims need your confirmation before this is customer-ready (flagged with ⚠️ below). Nothing below is invented; anywhere I compressed or attributed a persona that your source table left blank, I marked it.**

---

## Proposed 6-slide flow

1. Title
2. Cross-cutting hook: the CVE-patching anchor (applies to every persona) — *new, see note below*
3. VI Admin value
4. Platform Engineering value
5. Multi-vCenter (cross-persona platform capability)
6. Roadmap

Your source explicitly calls out one benefit as **"applies to all personas"** — the CVE-patched control plane via VKr. That's a strong opening hook (concrete, quantifiable-sounding, affects everyone) but it pushes you to 6 slides. Options:
- **(A)** Keep as its own slide 2 (my default below), landing it before you split into personas — mirrors how the vSphere Pods deck opens with a shared "why this matters" stat slide before going persona/segment-specific.
- **(B)** Fold it into the Title slide subtitle + one callout box, keeping personas + multi-vCenter + roadmap at 4 slides (5 total).

Tell me A or B and I'll adjust.

---

## Slide 1 — Title

**Supervisor 2.0 Rearchitecture**
A CAPI-managed, VKS-powered control plane — continuously CVE-patched, resilient across vCenters, and no longer tied to your VCF upgrade cadence.

Sachi Bhatt
VCF Workloads and Consumption Product Management
[Month] 2026 · VCF 9.2

---

## Slide 2 — Every persona: a continuously CVE-patched control plane

**⚠️ CORRECTED 2026-08-10** — the row below originally named "BlackDuck + Grype scanning" and "the NoGo gate," and stated FIPS 140-3 and Kubernetes conformance certification as complete. Live research against VKS 3.7/3.8 Jira and Confluence source found: **zero mentions of Grype anywhere** (primary scanner is **Trivy**, with BlackDuck as a complementary SBOM-based integration); **no confirmation of a "NoGo gate"**; FIPS 140-3 work is real but status is **"Release Validation" (in progress)**, not complete; and **no Kubernetes conformance test-suite evidence found**. Table corrected below — don't reuse the old wording elsewhere.

**The anchor claim, stated precisely (from your source):**

Supervisor's control plane now runs on a VKS Kubernetes Release (VKr) — the same artifact VMware ships for VKS guest clusters.

| | Before (Supervisor 1.0) | After (Supervisor 2.0) |
|---|---|---|
| CVE remediation | No automated path — each of 12+ components individually scripted and independently exposed | Runs on VKr → inherits VKS's confirmed CVE pipeline: **Trivy** scanning (primary) with **BlackDuck** SBOM integration, and CVE fixes that are **backported across every actively-supported Kubernetes minor version** — a real example patched CVE-2026-31431 and CVE-2025-68121 simultaneously across 4 supported minors (1.33.13/1.34.9/1.35.6/1.36.2) |
| What an upgrade delivers | Component-by-component patching, tracked separately from VKS | Known critical CVEs **block a release from shipping** (confirmed via real `rc2-blocker` tickets tied to specific CVE fixes on VKS 3.7.0) — not a best-effort cleanup. FIPS 140-3 compliance is an active, in-progress effort (not yet a blanket certification — confirm current status before quoting to a compliance-sensitive customer). Kubernetes conformance certification status: **unconfirmed, no evidence found** — don't claim this until verified |
| Compliance reporting | Teams ran their own scanners against Supervisor independently | Supervisor inherits the same patch/scan pipeline VKS already runs for guest clusters, since Supervisor 2.0's control plane *is* a VKr — this is an architectural inference (confirmed), not a direct quote tying the CVE story specifically to Supervisor yet |

**One-line takeaway:** you stop tracking Supervisor's CVEs as a separate problem from your VKS guest clusters' CVEs — it's one pipeline now, with a real (if occasionally slipping — one tracked patch cycle ran ~3-4 weeks late) backport-and-gate discipline behind it, not just a scanning claim.

**Reality check — don't oversell cadence:** there's no stated fixed CVE-patch SLA. Say "backported across supported versions and gates the release," not "patched within X days."

---

## Slide 3 — VI Admin: faster, safer, scriptable operations

Selected from your source table (VI-admin-relevant rows; full table has more if you want to swap any in):

- **Declarative, rolling upgrades** — CAPI rolling upgrade (bump K8s version in the CAPI Cluster CR) replaces 12+ bespoke EAM/CompSync/bash/Python scripts with no coherent ordering. Node-by-node, predictable, recoverable → shorter, less disruptive upgrade windows.
- **`supervisor-adm` CLI for day-2 ops** — Enable, Disable, Recover as a real CLI (embeds in VCSA or runs standalone) instead of only via `wcpsvc` VAPI. Idempotent and composable — fits into runbook automation / CI/CD instead of custom VAPI scripting.
- **Credential hygiene** — CPVM root passwords now provisioned as hashes from VC, not plain-text in Secrets/guestinfo.
- **Automated VC service account management** — `supervisor-agent` watches the Supervisor K8s API and auto-creates/manages VC service accounts via signed CRs, instead of manual VC IAM config buried in `wcpsvc`.

**Before/after framing (optional table, mirrors vSphere Pods deck style):**

| | Supervisor 1.0 | Supervisor 2.0 |
|---|---|---|
| Upgrade mechanism | 12+ bespoke CompSync/bash/Python scripts | CAPI Cluster CR — bump K8s version, rolling update |
| Admin interface | `wcpsvc` VAPI only | `supervisor-adm` CLI, scriptable |
| VC service accounts | Manual, embedded in `wcpsvc` | Auto-managed by `supervisor-agent` |

⚠️ **Confirm:** I pulled these 4 as the VI-admin set from your table; your source table's "Persona" column was actually blank on every row (see note at bottom) — flag if any of these should move to the Platform Eng slide instead, or if there's a VI-admin benefit you want prioritized that I didn't pick.

---

## Slide 4 — Platform Engineering: Kubernetes-native, GitOps-ready control plane

- **Source of truth moves to the K8s API** — Supervisor config no longer lives opaquely in VCDB. It's `kubectl`-readable, exportable, and backup/restore-friendly, with a full audit trail.
- **GitOps works natively** — because config is real Kubernetes state, standard Flux or ArgoCD workflows apply directly to Supervisor. No more "no kubectl, no GitOps" gap.
- **Operators ship as VKS Addons** — all Supervisor controllers packaged as Carvel/kapp-controller Addons: versioned, desired-state reconciliation, same tooling platform teams already use for VKS guest clusters (not custom EAM APIs).
- **Worker VMs join as real K8s nodes** — Infrastructure Supervisor supports vanilla Linux K8s pods on Worker VMs (not just PodVMs) for densely-packed infra services — full standard Kubernetes node behavior.

⚠️ **Confirm:** same caveat — these 4 are my pick as the platform-eng set; adjust if needed.

---

## Slide 5 — Beyond personas: multi-vCenter as a platform capability

Framing line: this isn't a VI-admin feature or a platform-eng feature — it's cross-cutting, and it's where the architectural shift really pays off.

**1. Supervisor control plane spanning up to 3 vCenters** — grounded in your source:
- **Before:** Supervisor is 1:1 with a single VC Datacenter. A VC outage takes down the entire control plane. Scaling means standing up a brand-new Supervisor — no cross-VC capacity pooling.
- **After:** 1 Supervisor = N VC Datacenters (`RegisterVC` as a Day-2 operation). Storage, VM Images, and Zones gain VC-agnostic abstractions — a single StorageClass can be backed by policies across multiple VCs, a single VM Image can resolve across VC-scoped content libraries, and a VC Placement Operator picks the right VC per workload automatically.
- **Customer-facing claim:** *a single vCenter outage no longer takes down your Supervisor control plane* — because zones are VC-scoped (1 zone = 1 VC, per your decision register) and a Supervisor can span multiple zones/VCs, losing one VC no longer means losing the whole control plane.

**2. VKS control planes spanning 3 vCenters, for true HA**
⚠️ **This one I can't confirm from your pasted source.** Your source documents the *Supervisor's own* control plane (CPVMs) spanning multiple VCs via the VC Placement Operator — but doesn't explicitly say VKS **guest cluster** control-plane nodes get spread across those same VCs for HA. Is that:
- (a) the same underlying multi-VC placement mechanism, just also applied to VKS guest cluster control-plane VMs when they're placed — i.e. a natural consequence of Pillar 5, or
- (b) a distinct, separately-tracked capability I should get more detail on before it goes on a customer slide?

Given your own standard on this (catching the uncited 70% stat before it went external), I'd rather ask than write a HA claim for VKS guest clusters that isn't in the source material.

---

## Slide 6 — Roadmap

- **VCF 9.2 — target** — Supervisor 2.0 ships (VC 9.2 required for upgrade); co-designed with PodVM v2 (each is a prerequisite for the other's advanced capabilities — multi-Supervisor-per-ESXi needs PodVM v2's ESXi decoupling; PodVM v2's controllers ship as VKS Addons on Supervisor 2.0)
- **Brownfield upgrade path (1.0 → 2.0)** — minimum starting version SV1.5; `wcpsvc` → EAM relinquishes CPVMs → VKSifier creates CAPI Cluster CR, adopts existing CPVMs, rolling update. [confirm if this is its own timeline row or a footnote]
- **[your future milestone]**
- **Non-goals explicitly out of 9.2 scope** (worth a small callout so nothing overpromises): multi-SDDC admin UI, VAPI-based multi-SDDC admin, Zones spanning multiple *clusters* across different VCs, mixed PodVM+Worker-VM-pods on one Supervisor, ESXi-only bootstrap (no VC), upgrade from VC < 9.2, ordered addon upgrade in VKS.

---

## Notes on how I compressed your source

- Your "Customer-Facing Benefits by User Persona" table has 14 rows but every row's **Persona** cell was empty in what you pasted — only the standalone "CVE Patching Anchor (applies to all personas)" callout had an explicit persona label. I assigned the other 13 to VI Admin / Platform Eng by reading what each benefit actually touches (CLI/credentials/upgrades → VI Admin; kubectl/GitOps/Addons/Worker-VM-pods → Platform Eng). Rows I did **not** use on either slide, in case you want to swap one in: CVE posture published with every release, Shared CVE posture artifact, Standard addon tooling (no EAM APIs), More reliable Supervisor API server, Shorter/less disruptive upgrade windows (currently folded into Slide 3's first bullet).
- I left out the internal architecture pillars that are true but not obviously customer value on their own (state migration mechanics, `supervisor-agent` internals beyond the customer-visible effect, decision register items 2–9) — those are the "why it works" behind the slides, available if you want a backup/appendix slide for a more technical audience.

## Open questions before this is final

1. **A or B** on the CVE-anchor slide placement (own slide vs. folded into title) — see top.
2. Confirm or reassign the VI Admin / Platform Eng bullet picks (⚠️ on slides 3–4).
3. Confirm the VKS-guest-cluster-HA claim on slide 5, or tell me who to ask.
4. Release version/dates for slide 6 — yours to fill in.
5. Once content is locked, you mentioned wanting a layout visual — I can build an HTML mockup styled with the actual brand hex codes (from the template you shared) so you can see card/table layout before this goes into PowerPoint by hand. Want that next, or lock content first?
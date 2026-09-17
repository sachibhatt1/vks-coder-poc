---
marp: true
theme: default
paginate: true
header: 'Supervisor 2.0 Rearchitecture Workshop'
footer: 'VMware by Broadcom Confidential'
---

# Supervisor 2.0 Rearchitecture
## Product & Engineering Alignment Workshop
**Owner:** Sachi Bhatt, VCF Workloads and Consumption Product Management
**Date:** August 2026

---

# Agenda
1. **The North Star:** Supervisor 2.0 Vision & Goals
2. **Core Architecture & Control Plane**
3. **Lifecycle Management (LCM) & Fleet Operations**
4. **Compute & Workload Orchestration**
5. **Infrastructure Services: Storage & Networking**
6. **Platform Engineering & Developer Experience**
7. **Security, Identity & Compliance**
8. **Observability & Diagnostics**
9. **Open Discussion: The Brownfield Migration & Multi-VC**

---

# 1. Core Architecture & Control Plane
*The Foundation: Kubernetes machinery, etcd, and distributed control planes.*

**Where we stand today:**
- **Foundation Complete:** Supervisor 2.0 Bootstrap (VKAL-36985) and VCDB to etcd Foundation (VKAL-36785) are Closed.
- **VKSification:** Converting the Bootstrap machine into a VKS cluster is Accepted (VKAL-40800).

**Blindspots & Risks to Acknowledge:**
- **Control Plane HA across Zones:** Flexibility to choose the zone for VKS control plane nodes (GCM-19818) is still Proposed. We must clarify if multi-VC HA applies to guest clusters or just Supervisor CPVMs.
- **Scale Validation:** Supervisor 2.0 Scale Testing (GCM-20394) is only Proposed. We need early validation of etcd performance and API fairness under load.

---

# 2. Lifecycle Management (LCM) & Fleet Operations
*Day 0/Day 2: Upgrades, backup/restore, and maintenance.*

**Where we stand today:**
- **Upgrade Workflow:** Supervisor 1.0 to 2.0 upgrade workflow (VKAL-36338) is Closed, and core upgrade execution (VKAL-37693) is In Progress.
- **Backup & Restore:** Active development (VKAL-37689) is In Progress.

**Blindspots & Risks to Acknowledge:**
- **Precheck Gaps:** Ensuring `wcp-sv-state-checker` and ESX prechecks are Supervisor 2.0-aware (VKAL-40941, VKAL-40830) are still in Design/Proposed phases. If prechecks fail, brownfield upgrades will stall.
- **Legacy Cleanup:** Embedded Supervisor 1.0 RPM removal from VC (VKAL-41677) is Proposed. We must ensure no legacy bloat is left behind.

---

# 3. Compute & Workload Orchestration
*Execution environments, scheduling, and isolation.*

**Where we stand today:**
- **VM Service:** VMService support for Supervisor 2.0 (VMSVC-3624) is In Progress.
- **Mobility:** Mobility Operator Support (VMLM-7378) is In Review.

**Blindspots & Risks to Acknowledge:**
- **The Future of PodVMs:** "PodVM 1.0 on Supervisor 2.0" (VKAL-36856) was Reopened, while "Integrate PodVM v2 with Supervisor 2.0" (VMKUW-3185) is Proposed. We have a collision risk between maintaining 1.0 and transitioning to v2.
- **Placement Logic:** WCP support for Namespace Placement with Infra Policy (VKAL-36725) is Proposed. DRS vs. VC Placement Operator boundaries need strict definition.

---

# 4. Infrastructure Services: Storage & Networking
*Bridging Kubernetes primitives with vSphere infrastructure.*

**Where we stand today:**
- **Networking:** Dual-NIC and DHCP network support (GCM-18278) and FLB enhancements (VCFN-3991) are In Progress.
- **Storage:** CSI Changes for Worker nodes as VMs (CNAS-10991) are In Progress.

**Blindspots & Risks to Acknowledge:**
- **Non-Disruptive Import:** Retaining IP and MAC of supervisor VMs in NSX T1 and VPC topologies during non-disruptive import (VCFN-3699) is only Proposed. This is a massive customer pain point if not seamless.
- **NSX State Migration:** Moving NSX state/reconcilers from `wcpsvc` to the supervisor (VCFN-3563) is Proposed. Risk of state desync during transition.

---

# 5. Platform Engineering & Developer Experience
*Kubernetes API as source of truth, Addons, and GitOps.*

**Where we stand today:**
- **App Platform:** Supervisor Services framework changes (APPPL-4516) and VCDB to etcd App-platform prechecks (APPPL-4508) are In Progress.
- **Addon Packaging:** Helm-based addon packaging/publishing (VKD-20707) is In Progress.

**Blindspots & Risks to Acknowledge:**
- **Addon Repo Publishing:** Publishing AddonRepo/PKGR directly from Kubernetes Release (VKR) instead of AddonReleases (VKD-23270) is Proposed. We need to ensure the developer experience matches VKS guest clusters exactly.
- **Image Hardening:** Image Baker hooks for custom Photon STIG/Hardening rules (VKD-17049) is in Design. Customers will demand hardened images on Day 1.

---

# 6. Security, Identity & Compliance
*Authentication, RBAC, and data security.*

**Where we stand today:**
- **Identity & Auth:** Supervisor 2.0 Identity, Auth and Security (VKAL-39163) is In Progress.
- **Node Join:** CSR-based node join for Supervisor 2.0 (GCM-17931) is Closed.

**Blindspots & Risks to Acknowledge:**
- **Secret Distribution:** "Private keys should not be distributed via guestinfo" (GCM-20823) and "vTPM sealed encryption secret" (VKAL-39891) are Proposed. We must close the gap on data-at-rest exposures before 9.2 ships.
- **Namespace RBAC:** Supervisor 2.0 Namespace RBAC (VKAL-37785) is Proposed. Needs alignment with the new CAPI-driven model.

---

# 7. Observability & Diagnostics
*Metrics, logging, and troubleshooting.*

**Where we stand today:**
- **Testing Workflows:** Supervisor 2.0 Dev Test workflows (VKAL-37696) are In Progress.

**Blindspots & Risks to Acknowledge:**
- **Tech Debt Accumulation:** "Supervisor 2.0 Tech Debt" (VKAL-40801) is already an Epic in Proposed state. We need a strategy to pay this down before GA, not after.
- **Data Services Integration:** DSM integration with Supervisor 2.0 (CDP-6120) is To Do. We need to ensure Day 2 data services have full visibility into the new architecture.

---

# Open Discussion
## The Brownfield Migration & Multi-VC

**1. The 1.0 to 2.0 Upgrade Path**
- How do we handle customers with heavy `wcpsvc` VAPI dependencies today?
- Are we confident in the "VKSification" rollback mechanism if a brownfield upgrade fails mid-flight?

**2. The Multi-vCenter Reality**
- When a single Supervisor spans up to 3 vCenters, how do we handle a split-brain scenario if the VC Placement Operator loses contact with one VC?
- Is our single-pane-of-glass observability ready for multi-VC?

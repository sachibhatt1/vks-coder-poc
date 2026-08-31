# Supervisor UX for the Platform Engineering Persona — Internal Input Deck

**Owner:** Sachi Bhatt, VCF Workloads and Consumption Product Management
**Audience:** Internal (PM/eng input, not yet customer-facing)
**Format target:** 8 slides — title, 6 recommendation slides (1 per bullet), 1 sources/evidence appendix
**Content source:** Live web research across VMware/Broadcom field content (activation FAQ, VCF blog), Gartner Peer Insights, The Register, community.broadcom.com, and 2026 platform-engineering industry surveys — retrieved 2026-08-31. Every claim below is sourced; nothing is invented.
**Related:** [supervisor-2.0-rearchitecture.md](./supervisor-2.0-rearchitecture.md) — the customer-facing Supervisor 2.0 deck this complements. That deck covers what's shipping; this one covers what platform engineers say is still missing.

Status: **draft for internal review** — each slide pairs an observed pain point (with source) against a proposed UX direction. None of these are committed roadmap; they're candidate input for prioritization.

---

## Slide 1 — Title

**Closing the Gap: Supervisor UX for Platform Engineers**
What the field, analysts, and the broader platform-engineering industry are telling us — and six concrete UX directions in response.

Sachi Bhatt
VCF Workloads and Consumption Product Management
August 2026

---

## Slide 2 — Make the networking decision reversible, not a one-way door

**The pain point:** Customers activating VKS ask whether NSX VPCs are mandatory — confusion that traces back to a harder problem: the VDS-vs-NSX-VPC choice is made once at Supervisor enablement, and changing it later typically means tearing down and rebuilding the Supervisor. For a platform engineer standing up infrastructure other teams will depend on, an irreversible day-0 decision with unclear tradeoffs is the single biggest source of activation anxiety.

**Proposed direction:** Let platform engineers trial NSX VPC on a single namespace or zone before committing the whole Supervisor to it, or ship a supported (not "rebuild from scratch") migration path off VDS later. Lower the blast radius of the first decision.

**Evidence:**
- "Customers questioned whether NSX VPCs were mandatory... networking decisions are foundational; changing it later often requires tearing down and rebuilding the vSphere Supervisor." — [VMware VCF Blog, Top 10 VKS Activation Questions](https://blogs.vmware.com/cloud-foundation/2026/08/21/top-10-vmware-vsphere-kubernetes-service-activation-questions-asked-and-answered/)
- Gartner Peer Insights on the broader Tanzu Platform: "complexity is challenging, especially for the initial setup and integrations." — [Gartner Peer Insights, VMware Tanzu Platform](https://www.gartner.com/reviews/product/vmware-tanzu-platform)

---

## Slide 3 — Ship a preflight "doctor," not just better troubleshooting docs

**The pain point:** The overwhelming majority of failed Supervisor enablements are environmental — DNS, NTP skew, storage policy misconfiguration — not the Supervisor software itself. Today that surfaces late, as a stuck "Configuring" state, and gets resolved by working through KB troubleshooting articles after the fact.

**Proposed direction:** A `supervisor preflight` check (CLI or UI) that validates DNS, NTP, storage policy, and content-library sync *before* enablement is attempted, with copy-pasteable remediation steps inline — not a link to a separate KB article. This is the cheapest fix available for the worst first-run impression platform engineers get.

**Evidence:**
- "The overwhelming majority of failed enablements are environmental, DNS, NTP, network or storage policy, not the Supervisor software." / "Without a synced VKr content library associated with the Supervisor, the Supervisor can be perfectly healthy and still refuse to create a single cluster." — community and field troubleshooting sources, incl. [vmware/vsphere-supervisor troubleshooting guide](https://github.com/vmware/vsphere-supervisor/blob/main/supervisor-troubleshooting.md)
- Common deployment failures documented as stuck "Configuring" state resolved via DNS/routing/NTP fixes — [Broadcom Knowledge Base: Common issues with a vSphere with Tanzu Cluster deployment stuck in Configuring state](https://knowledge.broadcom.com/external/article/323411/common-issues-with-a-vsphere-with-tanzu.html)

---

## Slide 4 — Treat golden-path templates as GitOps-native objects, with API/UI parity on day one

**The pain point:** Platform engineers want to codify namespace templates, resource quotas, RBAC, and network policy tiers as versioned config they can review and promote through CI — not vCenter wizard clicks. When UI-exposed capabilities lag their API/CRD equivalents, platform teams either wait or build brittle workarounds.

**Proposed direction:** Every namespace/quota/policy capability ships with its CRD or API on the same release as its UI surface — no UI-first, API-later sequencing. Make self-service namespace templates a first-class GitOps object (already partially true via Namespace Self-Service Templates — the gap is consistency, not the concept).

**Evidence:**
- "From an experience perspective, the vSphere Supervisor resolves this friction by delivering true developer self-service backed by enterprise-grade administrative control." — [Broadcom TechDocs, Self-Service Namespace Management](https://techdocs.broadcom.com/us/en/vmware-cis/vsphere/vsphere-supervisor/8-0/vsphere-supervisor-services-and-workloads-8-0/configuring-and-managing-vsphere-namespaces/provision-a-self-service-namespace.html)
- Industry-wide critique this guards against: "Most tools sold as 'self-service Kubernetes platforms' are cluster management consoles wearing a nicer skin... developers still cannot ship a change without filing a ticket." — [Qovery, Self-Service Kubernetes Platforms Compared](https://www.qovery.com/blog/self-service-kubernetes-platforms-compared)
- "We Spent $4.2M on a Kubernetes Platform. Our Developers Still Deploy with `kubectl run`." — [Medium, 2026](https://medium.com/@sneharani2509/we-spent-4-2m-d94404404784)

---

## Slide 5 — Make BYO load balancer and ingress feel first-class, not tolerated

**The pain point:** Customers explicitly ask "can we use Citrix ADC/NetScaler instead of Avi?" — a technical question that's really a trust question, and it lands on top of a broader post-Broadcom-acquisition anxiety about being locked into bundled VMware components regardless of need.

**Proposed direction:** Equal status/health visibility for third-party load balancers inside the Supervisor UI (not just Avi), and documentation that leads with "supported alternatives" rather than "default path, alternatives buried." Low engineering cost, high trust payoff.

**Evidence:**
- "Can we use third-party load balancers like Citrix ADC/NetScaler for container workloads, or is Avi Load Balancer required?" — [VMware VCF Blog, Top 10 VKS Activation Questions](https://blogs.vmware.com/cloud-foundation/2026/08/21/top-10-vmware-vsphere-kubernetes-service-activation-questions-asked-and-answered/)
- Broader lock-in-sensitivity context: "VCF licensing is a bundled trap: you pay for components you may not need... you must pay for Compute (vSphere), Storage (vSAN), Networking (NSX)... even if you don't use VMware's networking." — [Redress Compliance, VCF Licensing Guide 2026](https://redresscompliance.com/vcf-licensing-guide-2026.html)

---

## Slide 6 — Give platform engineers native per-tenant capacity and cost visibility

**The pain point:** Platform-engineering literature is consistent: when a platform is a black box on cost and capacity, developer teams either wait on tickets or go around the platform entirely (shadow IT, siloed external clusters). Supervisor's namespace model is the natural unit for this, but that visibility isn't exposed as data platform engineers can build on.

**Proposed direction:** Per-namespace/per-tenant resource-and-cost data exposed as API/CRD, not buried in vCenter screens — so platform teams can surface it in whatever portal they already run (Backstage, internal dashboards) instead of sending users into the vSphere Client.

**Evidence:**
- "Developers... grow frustrated by delays, potentially turning to shadow IT or deploy siloed external management clusters," causing "security vulnerabilities, operational overhead, and cost inefficiencies." — [VMware VCF Blog, Operationalizing the VCF Control Plane for Kubernetes Workloads](https://blogs.vmware.com/cloud-foundation/2026/08/13/operationalizing-vmware-cloud-foundation-control-plane-for-kubernetes-workloads/)
- "Infrastructure Administrators... become overwhelmed by endless ticket queues for cluster provisioning and network changes." — same source

---

## Slide 7 — Replace lost multi-cluster governance parity after Tanzu Mission Control

**The pain point:** Teams that used Tanzu Mission Control as their unified fleet-governance layer had to relearn governance across VCF Automation when TMC's role changed — a fragmentation complaint, distinct from any feature-completeness complaint. Platform engineers want one governance model regardless of whether a cluster is Supervisor-native VKS or an attached external cluster.

**Proposed direction:** A first-class, GitOps-driven policy layer (OPA/Kyverno-style) applied uniformly across Supervisor-native and attached clusters, positioned explicitly as TMC's governance successor rather than left implicit inside VCF Automation.

**Evidence:**
- "The question about Tanzu Mission Control's disappearance reflects platform fragmentation concerns — teams lost a familiar management layer and had to relearn governance across VCF Automation." — [VMware VCF Blog, Top 10 VKS Activation Questions](https://blogs.vmware.com/cloud-foundation/2026/08/21/top-10-vmware-vsphere-kubernetes-service-activation-questions-asked-and-answered/)

---

## Slide 8 — Sources & further reading

**VMware/Broadcom field content:**
- [Top 10 VMware vSphere Kubernetes Service Activation Questions, Asked and Answered](https://blogs.vmware.com/cloud-foundation/2026/08/21/top-10-vmware-vsphere-kubernetes-service-activation-questions-asked-and-answered/)
- [Operationalizing VMware Cloud Foundation Control Plane for Kubernetes Workloads](https://blogs.vmware.com/cloud-foundation/2026/08/13/operationalizing-vmware-cloud-foundation-control-plane-for-kubernetes-workloads/)
- [More Kubernetes, Less Waiting: Upgrade vSphere Supervisor Without Updating vCenter](https://blogs.vmware.com/cloud-foundation/2025/07/13/more-kubernetes-less-waiting-upgrade-vsphere-supervisor-without-updating-vcenter/)
- [vsphere-supervisor troubleshooting guide (GitHub)](https://github.com/vmware/vsphere-supervisor/blob/main/supervisor-troubleshooting.md)
- [Broadcom KB: Common issues with a vSphere with Tanzu Cluster deployment stuck in Configuring state](https://knowledge.broadcom.com/external/article/323411/common-issues-with-a-vsphere-with-tanzu.html)

**Independent / analyst:**
- [Gartner Peer Insights — VMware Tanzu Platform](https://www.gartner.com/reviews/product/vmware-tanzu-platform)
- [The Register (2020) — "Kubernetes is 'still hard' so VMware has gone all-in..."](https://www.theregister.com/2020/03/10/vmware_kubernetes_tanzu_vsphere_7/)
- [Redress Compliance — VCF Licensing Guide 2026](https://redresscompliance.com/vcf-licensing-guide-2026.html)

**Broader platform-engineering industry (context, not VMware-specific):**
- [Qovery — Self-Service Kubernetes Platforms: 9 Options Compared](https://www.qovery.com/blog/self-service-kubernetes-platforms-compared)
- [Medium — "We Spent $4.2M on a Kubernetes Platform. Our Developers Still Deploy with kubectl run."](https://medium.com/@sneharani2509/we-spent-4-2m-d94404404784)

---

## Notes for review

- This is framed as *input*, not committed roadmap — each slide is a pain point (sourced) paired with a direction (my recommendation), so it should read as a discussion-starter with product/eng, not an announcement.
- Slides 2–7 map 1:1 to the six recommendations from the earlier research pass; order roughly follows "cheapest/fastest to address" → "requires most cross-team coordination" (preflight tooling is a near-term fix; TMC governance parity is a bigger lift).
- If you want this restyled into the VMware by Broadcom branded template (matching the Supervisor 2.0 deck), I can build the same HTML mockup pass once content is locked.

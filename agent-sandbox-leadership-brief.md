# Agent Sandbox on VCF — Leadership Brief

**Sachi Bhatt · VCF Workloads and Consumption PM · August 2026**

---

## The ask

Commit a roadmap slot and engineering investment in VCF 9.1.2 to productize the Agent Sandbox Supervisor service. Decision needed before Explore Las Vegas (Aug 31) so our public message matches what we are funded to ship.

## What we already have

A running Supervisor service on VCF demonstrating:

- Warm pool — working
- Claim — working
- Suspend — working
- Hibernation and resume — not yet built

This is not a concept pitch. The technology works. The gap is productization, not invention.

## Why now

- **Red Hat shipped July 15, 2026.** Their build of Agent Sandbox is downstream of the same upstream Kubernetes project we plan to use, with Kata isolation switchable in one field. We are roughly a quarter behind.
- **Upstream conventions are being set now.** The project's roadmap has no position on how a platform chooses between container-based and VM-based isolation. That gap is unclaimed, but not for long.
- **Explore Las Vegas is Aug 31.** We can demo today. We should not demo a capability we are not funded to ship.

## What productization requires

- Harden the warm pool controller for production load
- Build hibernation and resume
- Host-level container image caching
- Upgrade and lifecycle handling
- Observability into standard Kubernetes pipelines
- Documented, tested scale limits

## Positioning change we recommend

**Stop selling speed. Sell durability.**

We currently position vSphere Pods as "the ephemeral agent sandbox." That invites a cold-start comparison against Firecracker-based competitors who boot in 5–30ms versus our 9–18s cold. Our warm pool closes most of that gap in practice, but it is not a fight we need to pick.

We win on the durable case: agents running for hours or days, agents needing a custom OS, workloads that pause, snapshot, clone, or live-migrate, and workloads that must stay inside an existing compliance boundary. Nobody owns that segment.

**Our strongest technical argument is missing from current materials.** The obvious question is "why not just run Kata on VKS?" The answer is that Kata inside VKS worker nodes means a hypervisor inside a VM — nested virtualization, with real performance and capability cost. vSphere Pods run directly on ESXi, unnested. No competitor on our stack can match this. It should be our headline, and Kata-on-Kubernetes should be an explicit column in our comparison materials.

## Partner strategy

**E2B — pursue.** Their self-hosted stack is Terraform, Nomad, Consul, and Firecracker, and by their own description it is a serious infrastructure project rather than a simple install. The customers who need it are regulated enterprises who cannot send code to their cloud — our installed base. Their infrastructure is open source, so maintainers are a better entry point than a BD form.

**Modal — do not pursue now.** No on-prem or BYOC option by deliberate choice. Approaching them means asking them to enter a business that conflicts with their own margin.

**Trade to make deliberately:** as an E2B backend, they own the developer relationship, the DX, and the margin; we become substrate that can be swapped. That may still be worth it for distribution we cannot build organically on this timeline — but decide it, don't drift into it.

**Timeline:** two to three months for BD, legal, and exec alignment, and we have no contact yet. Explore on Tour (Sep 29 – Nov 19, London closes it) is the realistic window, not Las Vegas.

## Two tracks, run in parallel

| | Track A — Product/GTM | Track B — Community |
|---|---|---|
| Audience | VMware customers | Upstream Kubernetes project |
| Calendar | Our release train | Community's |
| Success | Pipeline and adoption | Influence over the design |
| Cost | Engineering | PM calendar time only |

Neither should gate the other. One real dependency: the native Kubernetes work in 9.2 is what makes upstream recognition credible.

**Track A:** Explore preview (now) → E2B partnership (Sep–Nov) → ship 9.1.2 (late 2026) → native K8s in 9.2 (2027) → converge pods and VM Service.

**Track B:** participate upstream (now) → submit runtime-selection design proposal (fall) → KubeCon EU 2027 submission (CFP likely opens Sep/Oct) → pursue recognition after 9.2.

## Correction to the current roadmap slide

The 9.1.2 line commits to securing official recognition of vSphere Pods as a qualified runtime class alongside gVisor and Kata. That is a community consensus outcome on our release train — we cannot schedule other people's agreement, and it will likely slip because vSphere Pods only exist on ESXi with a Supervisor. Move it to Track B with no ship date. Commit instead to submitting the proposal, which we control.

## Risks

1. **We don't get the slot.** Everything past Explore depends on it. Demoing a capability we never ship is worse than not demoing.
2. **Red Hat's lead compounds** if upstream conventions form around their implementation before we participate.
3. **Cold start** is a credibility risk in any unwarmed head-to-head.
4. **E2B may not close.** Need an Explore on Tour narrative that works without a partner logo.

## Decisions needed

| Decision | Owner | By when |
|---|---|---|
| 9.1.2 roadmap slot and engineering investment | Product leadership | Before Aug 31 |
| Las Vegas = preview only; partnership news lands on Tour | Product + marketing | Before messaging lock |
| Business model: VCF entitlement, licensed add-on, or per-sandbox-hour | Product leadership | Before 9.1.2 launch review |
| Approve E2B outreach | Product leadership + BD | This month |

## Open item

Slide 3 claims 70% of AI agents execute untrusted code, with no source. It needs a citation or it comes out before this goes to analysts or customers.

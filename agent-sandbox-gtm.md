# Agent Sandbox on VCF — Go-to-Market Plan

**Owner:** Sachi Bhatt, VCF Workloads and Consumption Product Management
**Date:** August 2026
**Status:** Draft for internal review

---

## The bet

Enterprise AI is shifting from chatbots that answer questions to agents that write and run code. That code is untrusted by definition, and standard containers share a kernel, so they are the wrong place to run it. The market needs a new compute primitive — a sandbox — and it needs one that works on-premises, because the enterprises with the most valuable data are the least able to send it to someone else's cloud.

VCF already has that primitive. vSphere Pods have delivered hardware-isolated, OCI-native workloads on ESXi for years. We do not need to build a new workload service to enter this market. We need to make vSphere Pods behave like a modern agent sandbox, get the Kubernetes community to recognize them as a legitimate isolation option, and put them in front of the developers and platform teams who are choosing sandbox infrastructure right now.

## Where we are today

This is not a concept. We have a Supervisor service running today that demonstrates the core sandbox lifecycle — warm pool, claim, and suspend all work. Hibernation and resume are the remaining gap.

That changes the nature of this plan. The hard question is not whether the technology works or whether we can build it. It is whether we get a roadmap slot and the engineering investment to turn a working proof of concept into a supportable product. Everything downstream of that — the community position, the partnership, the launch — depends on an internal commitment decision, not a technical one. This document should be read as an argument for that commitment.

## Why the timing is urgent

Red Hat shipped a downstream build of the upstream Kubernetes Agent Sandbox project on July 15, 2026. They support Kata Containers as the isolation runtime and let an administrator switch it on with a single field. They are roughly a quarter ahead of us and they are shipping against the same upstream project we plan to plug into.

That has two consequences. First, our VCF 9.1.2 launch is a fast-follow, not a first move, and we should stop describing it internally as establishing market presence. Second, and more important, the conventions for how this upstream project handles isolation runtimes are being set right now, and if we are not in that conversation, they will be set in a shape that assumes Kata and gVisor and does not accommodate what we do.

The good news is that the upstream roadmap does not currently address runtime selection at all. There is no item for choosing between container-based and VM-based isolation, and no mention of KubeVirt. That gap is ours to fill if we move.

## Who buys this, and the two ways they buy

There are two distinct customers here and they consume infrastructure in completely different ways, so we need two motions rather than one.

The first is the **AI application developer**. They want to call an API, get a sandbox, run code, and never think about infrastructure. They are choosing between E2B, Modal, Daytona, and similar services today. They do not know or care what a Supervisor is. For this buyer we sell through an SDK and a REST API, and realistically we reach them through a partner rather than directly.

The second is the **platform engineering team** standing up an internal AI platform on Kubernetes. They want Custom Resources, standard CNCF orchestration, and control. They are the ones evaluating the upstream Agent Sandbox project against Red Hat's build. For this buyer we sell through VKS and Kubernetes-native APIs, and we reach them through the community and our existing VCF relationship.

Both sit on the same foundation — vSphere Pods as microVMs on ESXi — which is why we can serve both without building two products.

## How we position, and what fight we decline

We should stop leading with speed. Our cold boot time is nine to eighteen seconds. Firecracker-based competitors boot in five to thirty milliseconds using pre-generated snapshots and warm pools. Our warm pool closes much of that gap in practice, but we will not win a cold-start benchmark against a runtime purpose-built for exactly that with years of head start. Every deck that calls vSphere Pods "the ephemeral agent sandbox" invites a comparison we do not need to have.

Where we win is the durable case. Agents that run for hours or days rather than seconds. Agents that need a custom operating system rather than a stripped container image. Workloads that need to be paused, snapshotted, cloned, or live-migrated. Workloads that have to run inside an existing compliance boundary on infrastructure the customer already owns and already knows how to operate. Nobody owns that segment today, and it is exactly where our architecture is strongest.

The single most important technical argument we are not currently making is about nested virtualization. The obvious question any sophisticated buyer or community reviewer asks is why not just run Kata Containers on VKS and be done with it. The answer is that Kata inside VKS worker nodes means running a hypervisor inside a virtual machine, and nested virtualization on ESXi carries a real performance and capability cost. vSphere Pods run directly on ESXi with no nesting. That is a structural advantage nobody else on our stack can match, and it should be the headline of our competitive positioning rather than a footnote.

We should also add Kata-on-Kubernetes as an explicit column in our comparison materials. Comparing ourselves only against standard containers and traditional VMs looks evasive to anyone who knows the space.

## Two separate tracks

There are two workstreams here and they should not be managed as one. The product and go-to-market track sells to VMware customers on our release calendar, and its success measure is pipeline and adoption. The community and standards track contributes to an upstream Kubernetes project on the community's calendar, and its success measure is influence over how the project evolves. Different audiences, different timelines, different definitions of winning.

They should run in parallel and neither should be allowed to gate the other. There is exactly one real dependency between them, noted at the end of each track: the native Kubernetes work in VCF 9.2 is what makes upstream recognition technically credible. Everything else is independent.

### Track A — Product and go-to-market

- **A1, now through Aug 31:** Technical preview at Explore Las Vegas
- **A2, Sep through Nov:** E2B partnership development, carried by Explore on Tour
- **A3, VCF 9.1.2, late 2026:** Productize the POC and ship the Supervisor service
- **A4, VCF 9.1.3 through 9.2, 2027:** Native Kubernetes integration and scale
- **A5, beyond 9.2:** Converge vSphere Pods and VM Service into one substrate

### Track B — Community and standards

- **B1, now:** Enter the upstream conversation as a participant
- **B2, fall 2026:** Submit a design proposal on runtime selection
- **B3, when the CFP opens:** KubeCon Europe 2027 submission
- **B4, 2027:** Pursue recognition once the native Kubernetes work lands

## A1 — Explore Las Vegas

Explore Las Vegas runs August 31 to September 3. Flagship event messaging is normally locked three to four weeks out, so we are at or past that line for anything new — but we do not need anything new. The Supervisor service already demonstrates warm pool, claim, and suspend. That is a genuine technical preview, not a staged mockup, and the work between now and Las Vegas is rehearsal and narrative rather than engineering.

What we should not attempt is a partnership announcement or any suggestion that this is generally available. Position it as a technical preview with a clear statement of direction.

We do need discipline on the performance claim. Our warm pool is real, so lead with it, but the slide should say warm pool rather than implying an unwarmed pod starts in milliseconds. An analyst or competitor who benchmarks us at nine to eighteen seconds cold after we implied sub-second does damage that is hard to undo, and Red Hat now has a shipped product to benchmark against. Being precise costs us nothing here because the warmed number is competitive.

One honest caveat on positioning: the durable, long-lived agent case we should be leading with depends most on hibernation and resume, which is the piece still outstanding. We can demo suspend and describe the direction credibly, but we should not describe hibernation as working.

## A2 — E2B partnership, September through November

Explore on Tour runs from late September through London on November 18 and 19. That is the realistic window for partnership news, because business development, legal, and executive alignment on both sides take two to three months and we do not have a contact yet.

The working demo changes our opening position considerably. We are not pitching a concept — we can show warm pool, claim, and suspend working on VCF today. That is worth more in a first conversation than any deck.

On partner selection, focus on E2B and defer Modal. Our earlier assumption that both wrap Kubernetes APIs for on-premises deployment does not hold. E2B's self-hosted stack is Terraform, Nomad, Consul, and Firecracker rather than Kubernetes, so there is no existing Kubernetes path for us to slot underneath. Modal has no on-premises or bring-your-own-cloud option at all; it is a managed service by deliberate choice, and asking them to enter that business means asking them to create channel conflict with their own margin.

The E2B pitch has to be narrow and honest. Their self-hosted deployment is, by their own description, a serious infrastructure project rather than a simple install. The customers who need it are regulated enterprises who cannot send code to their cloud, which is our installed base. We are offering to make their hardest segment easy to serve. Their infrastructure is open source, so the maintainers are a warmer entry point than a business development form.

We should go in knowing what we are trading. If we become a backend for E2B, they own the developer relationship, the developer experience, and the margin, and we become substrate that could be swapped later. That can still be the right deal because it buys distribution we cannot build organically on this timeline, but it should be a deliberate decision rather than one we drift into.

## A3 — VCF 9.1.2 and productization

This is the phase the whole plan actually depends on, and it is an internal commitment problem rather than a technical one. We have a working service. What we need is a roadmap slot and the engineering investment to make it supportable: hardening the warm pool controller for production load, closing hibernation and resume, host-level image caching, upgrade and lifecycle handling, observability, and documented scale limits.

Position the launch as making VCF a credible destination for agent workloads rather than as establishing market presence. Red Hat got there first and the stronger claim will not survive scrutiny.

One change to the current roadmap slide: remove community recognition from the release commitment. Securing official recognition of vSphere Pods as a qualified runtime class alongside gVisor and Kata is a community consensus outcome, and we cannot schedule other people's agreement on our release train. That belongs in Track B, where it is not tied to a ship date.

## A4 — Native Kubernetes and scale

VCF 9.2 brings the vSphere Pods 2.0 re-architecture with vMotion, native Kubernetes API compatibility with VKS, vGPU through DRA, host-level snapshots, and pod security admission. This is the release where vSphere Pods stop being a Supervisor-specific construct and become something a platform engineer can treat as a normal Kubernetes object.

This is also the one place the two tracks genuinely touch. Until this work lands, the community can reasonably ask what happens on a cluster that is not ours, and we do not have a good answer. After it lands, we do.

## A5 — Converging pods and VM Service

Once vSphere Pods 2.0 supports vMotion and behaves like a virtual machine on the stack, the architectural distance between a vSphere Pod and a VM Service virtual machine becomes very small. The end state worth arguing for is not two products that gradually converge, but one ESXi-native runtime with two API surfaces — pod-shaped for Kubernetes consumers, VM-shaped for VM Service consumers — where isolation strength and persistence become settings rather than a product choice.

## B1 — Entering the upstream conversation

We have been attending the biweekly upstream meeting without participating. The immediate action is to start participating: raise the runtime-selection question in the project's Slack channel, then at the meeting. This costs calendar time rather than engineering capacity, which is why it does not compete with anything in Track A.

The opening is real. The upstream roadmap covers warm pools, suspend and resume, and auto-suspend, but says nothing about how a platform chooses between container-based and VM-based isolation, and does not mention KubeVirt at all. That gap is unclaimed.

## B2 — A design proposal on runtime selection

The contribution worth making is a standard way to express what kind of isolation a workload needs and let the platform select the mechanism, rather than hard-coding a runtime class per deployment. Framed generically, this serves any platform with more than one isolation option — Kata, gVisor, WebAssembly, KubeVirt, or ours.

Framing matters enormously here. Asking the community to accept one more vendor-specific runtime class is a request they can decline without cost. Offering a general mechanism for expressing a continuum of isolation is a contribution that helps everyone and happens to be one we are well positioned to implement. The second version is the one that gets adopted.

## B3 — KubeCon Europe 2027

KubeCon Europe 2027 is in Barcelona from March 15 to 18. The call for proposals has not opened and, based on the previous cycle, will likely open around September or October 2026. A submission backed by a real upstream proposal is far more likely to be accepted than a vendor talk, which is why B2 comes first. This is a community credibility investment, not a marketing channel, and it should not be measured or resourced as one.

## B4 — Recognition

Recognition of vSphere Pods as a supported isolation option is an outcome of the work above rather than a task we can schedule. It becomes realistic once the native Kubernetes work in A4 lands and we have standing from B1 through B3. Treat it as a milestone we hope to reach, not a commitment we make.

## The open question on business model

We have not decided how this is priced, and we will be asked. The three options are bundling it as a VCF entitlement, which defends renewals and blunts the argument for moving agent workloads to the public cloud; selling it as a licensed add-on; or pricing it by consumption, per sandbox-hour or similar. Arguing that we can enter this market without new workload service development is a cost argument, and it does not answer the revenue question. We need a position on this before the 9.1.2 launch review.

## Risks worth naming

The largest risk is that we do not get the roadmap slot and the POC stays a POC. Everything in Track A past Explore depends on that commitment, and a working demo that never becomes a product is worse than not demoing at all, because we will have told customers we are entering a market and then not entered it.

Red Hat's head start is the second, and it compounds if upstream conventions form around their implementation before we participate. Cold-start performance remains a credibility risk in any unwarmed head-to-head. The E2B partnership may not close, in which case we should have a narrative for Explore on Tour that does not depend on a partner logo.

There is also a specific risk in the current materials: the claim that seventy percent of AI agents execute untrusted code is presented without a source. If that number goes to analysts or customers, it needs a citation or it should come out.

## What we need to decide now

The roadmap commitment for 9.1.2 is the decision everything else waits on, and it should be made before Explore rather than after, so that what we say in Las Vegas matches what we are actually funded to deliver. Alongside that, we need internal agreement that Las Vegas is preview and direction while Explore on Tour is where partnership news lands, so the expectation does not get set wrong and then walked back. We need to open the E2B conversation this month because it has the longest lead time and is the only item that dies if it slips. And we need to start participating upstream immediately, because it costs us nothing and the window to influence the design is closing.

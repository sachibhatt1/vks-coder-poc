# Agent Sandbox — Technical Landscape & Capability Gaps

**Owner:** Sachi Bhatt, VCF Workloads and Consumption Product Management
**Date:** September 2026
**Status:** Draft — items marked ⚠️ need confirmation against PodVM v2 Overall Architecture on Confluence (https://vmw-confluence.broadcom.net/spaces/WCP/pages/2429236635/PodVM+v2+Overall+Architecture and subpages)

---

## Purpose

Companion to `agent-sandbox-gtm.md` and `agent-sandbox-leadership-brief.md`. Those documents make the product/GTM case; this one stress-tests the technical claim — can we actually support `runtimeClass: agent-sandbox` on vSphere Pods, and where does the architecture fall short of the field (gVisor, Kata Containers, Firecracker-based platforms, Daytona)?

---

## 1. Public sandboxing landscape (Sept 2026)

| | gVisor | Kata Containers | Firecracker (E2B/Sprites) | Daytona | **vSphere Pods (CRX)** |
|---|---|---|---|---|---|
| Isolation model | User-space kernel, syscall interception (~68 of 350 syscalls) | Real guest kernel per pod, full VM | Real guest kernel, minimal device model | Docker/Seccomp by default, optional Kata | Real guest kernel per pod (CRX), unnested on ESXi |
| Cold start | 50–100ms | 150–300ms (some benchmarks ~480ms) | ~100–200ms cold; **5–30ms on snapshot-restore** | ~27ms via pre-warmed pools | **9–18s cold** per internal GTM doc; warm pool closes most of this |
| Memory overhead/instance | Near-zero (no guest kernel) | 50–100 MiB | ~5 MB | Backend-dependent | Claimed 75% less than a "typical VM" — no number vs. Firecracker/Kata-class |
| GPU | `nvproxy` — partial, selected driver/CUDA versions only | Full VFIO passthrough (1 GPU/pod), NVIDIA + Confidential Containers collab | VFIO passthrough, near-native | Backend-dependent | ⚠️ vGPU via DRA is a VCF 9.2 (2027) roadmap item, not shipped |
| Pause/resume | None native | No CRIU (guest kernel lacks `CONFIG_CHECKPOINT_RESTORE`); pod-level checkpoint/restore (KEP-5823) in progress, not shipped | Native snapshot-restore: pause ~4s/GiB RAM, resume ~1s, memory+disk diffed to object storage | Backend-dependent | **Hibernation/resume not built** — the named gap |
| Cross-host recovery | N/A | Live migration requested (kata-containers#1690), unresolved | Snapshot lands in object storage → resumable on any node | N/A | ⚠️ vMotion for Pods is a 9.2 roadmap item; no cross-host failover today |
| Who uses it | Modal | Red Hat Agent Sandbox, OpenShift sandboxed containers, Daytona (optional) | E2B, Sprites.dev | Daytona (multi-backend, BYO infra) | — |

**Context:** The broader Kubernetes checkpoint/restore story is younger than it looks — the Checkpoint/Restore Working Group was chartered Jan 21, 2026, and even Kata (a real-guest-kernel model like ours) has no shipped CRIU-based restore. Our hibernate/resume gap is real, but it isn't uniquely ours — it's an open problem across the field, which is also the opening for the Track B runtime-selection proposal.

---

## 2. Is vSphere Pods performant enough to claim `agent-sandbox`?

- **Startup time:** No, not against the field. 5–30ms (Firecracker) is a *resume* number against a pre-booted snapshot; our 9–18s is *cold*. The comparable number is our warm pool, and that's what should be used publicly. Kata, also a real-guest-kernel model, is 150–300ms even cold — 40–60x faster than our cold path. That gap needs an architectural explanation (CRX optimizes for density/placement on ESXi, not raw boot latency), or it reads as a weakness rather than a tradeoff.
- **Memory overhead:** We have a relative claim (75% less than "a typical VM") but nothing benchmarked against Kata's 50–100MiB or Firecracker's ~5MB. This is a gap in our own data, not just a competitive one.
- **Agent capabilities (GPU):** vGPU-via-DRA is 2027 roadmap. Kata ships full GPU passthrough today. No answer for GPU-in-sandbox until 9.2 lands.
- **Storage-backed restore after infra failure:** Our sharpest gap. E2B's model (diff memory+disk against a template, ship to object storage, resume on any node with the cache) gives sandbox-level DR today. We have no equivalent — no hibernate/resume, no cross-host mobility until vMotion for Pods 2.0 (9.2). **If an ESXi host dies today, a running agent sandbox on it is gone.** vSAN/storage policies protect data (Persistent Volume VMDKs), not running process state.

Conclusion: performant relative to a traditional VM, not performant relative to the Firecracker/gVisor field, and behind on GPU and failure-recovery today. The "durability, not speed" positioning is right, but it requires hibernate/resume *and* vMotion to actually exist — neither does yet.

---

## 3. HA story across common agentic solutions

Two different things get called "HA" here; nobody has classic active-active failover of a *live* sandbox today:

- **Sandbox-level resume** (E2B/Sprites, Firecracker-based): snapshot VM memory+disk to object storage, restore anywhere. Recovers exact process state — open file handles, in-flight computation. This is the bar our hibernate/resume work needs to clear.
- **Orchestration-level state recovery** (LangGraph-style frameworks, most enterprise agent platforms): sandbox is disposable; agent state (task graph, memory, tool history) is checkpointed externally to a DB/vector store. On failure, a new sandbox spins up and rehydrates from that external state. Recovers intent, not execution state — a mid-run subprocess is lost and re-planned.
- **Modal/gVisor, Daytona-Docker paths:** no persistence claim beyond fast re-creation (e.g., 27ms cold starts).

Nobody has full HA (state-preserving, cross-host, no data loss) for a live agent sandbox today — consistent with the GTM thesis that this segment is open, but the bar to credibly own it is hibernate/resume *and* cross-host mobility both working.

---

## 4. Is Photon OS a blocker for OCI-packaged agents?

Not the OCI image itself — containers bring their own userland, so the host's Photon OS/glibc version is largely irrelevant to compatibility (true for any container host).

The real constraint is the **CRX guest kernel**: deliberately stripped down (direct-boot, minimal paravirtualized devices, no full kernel init) for boot-speed and density. Same tradeoff every microVM design makes, but it likely means: no privileged containers, limited kernel module / eBPF / io_uring surface, no docker-in-docker, GPU passthrough requiring explicit driver support (see GPU gap above). Agent frameworks assuming a full generic Linux kernel (FUSE mounts, ptrace-based debuggers, etc.) may not run unmodified.

⚠️ **Needs confirmation from PodVM v2 architecture docs:** does PodVM v2 widen the CRX kernel surface (generic kernel vs. linux-esx kernel), and does that close the gap with Kata's fuller VM model? This is the single most concrete open question to resolve against the Confluence space.

---

## 5. Other gaps: observability, disaster recovery

Both are already named as open items in the leadership brief, not new findings:

- **Observability:** "Observability into standard Kubernetes pipelines" is a listed 9.1.2 productization requirement, not yet built. Platform engineering buyers will want per-sandbox metrics/traces/logs in their existing stack (Prometheus/OTel) before adopting — Red Hat's build inherits more maturity here by virtue of being container-shaped.
- **Disaster recovery:** No snapshot-to-object-storage equivalent, no vMotion yet. DR today would have to live at the application/orchestration layer (external state checkpointing, à la LangGraph) rather than the infrastructure layer, which undercuts an "we handle this for you" pitch.
- **Upgrade/lifecycle handling and host-level image caching** are also named gaps — they compound the DR story (an image-cache miss during failover reintroduces cold-start latency even after hibernate/resume ships).

---

## Consolidated blocker list for `runtimeClass: agent-sandbox`

1. **Hibernate/resume — not built.** Load-bearing gap; DR, durability positioning, and HA comparison all depend on it.
2. **Cross-host mobility (vMotion for Pods) — 9.2/2027 roadmap.** Without it, host failure = agent loss today.
3. **GPU via DRA — 9.2/2027 roadmap.** Kata ships this now.
4. **No public memory-overhead or cold-boot benchmark** against Firecracker/Kata-class numbers — only relative claims exist.
5. **CRX kernel surface vs. generic agent workload requirements — needs Confluence confirmation.** Possible blocker for privileged ops, exotic drivers, or full kernel features.
6. **Observability into standard K8s pipelines — not built.**
7. **No sandbox-level snapshot-to-storage DR equivalent** — protection today is at the data layer (vSAN/VMDK), not the running-process layer.
8. **Community angle:** even the comparison set (Kata/CRIU checkpoint-restore) is immature — the K8s Checkpoint/Restore WG is ~8 months old. A genuine opening for the runtime-selection proposal (Track B2), not just a gap to close.

**Next step:** confirm items 2, 3, and 5 against the PodVM v2 Overall Architecture space directly (accessible from a Claude Code session with `vmw-confluence` authenticated) rather than inferring from public roadmap language.

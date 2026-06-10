# ⭐ Polaris - Homelab Infrastructure

> *Your North Star in the Infrastructure Galaxy*

Complete homelab infrastructure managed as code using Talos OS Kubernetes cluster and FluxCD GitOps practices.

## 🎯 Overview

Polaris is a production-grade homelab environment designed for learning, experimentation, and hosting self-hosted applications. Built on modern cloud-native technologies, it serves as both a personal development platform and a portfolio showcase.

### Philosophy

- **Infrastructure as Code**: Everything is versioned and declarative
- **GitOps-driven**: Flux is the single source of truth — Git drives the cluster, not `kubectl apply`
- **Immutable Infrastructure**: Talos OS for secure, minimal Kubernetes nodes
- **Minimal Stack**: Fewer components, tightly integrated — Cilium replaces both CNI and kube-proxy
- **Scalable**: 3 controlplane + 2 worker nodes, designed to grow

### Infrastructure Stack

```
┌─────────────────────────────────────────────────────────────┐
│                      Polaris Homelab                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Controlplane (HP ProDesk 400 G2)                           │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐                │
│  │  PCP-01   │  │  PCP-02   │  │  PCP-03   │                │
│  │ Talos OS  │  │ Talos OS  │  │ Talos OS  │                │
│  └───────────┘  └───────────┘  └───────────┘                │
│                                                             │
│  Workers (Minisforum MS-01)                                 │
│  ┌───────────┐  ┌───────────┐                               │
│  │  PWR-01   │  │  PWR-02   │                               │
│  │ Talos OS  │  │ Talos OS  │                               │
│  └───────────┘  └───────────┘                               │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │            Kubernetes v1.35.0                       │    │
│  │  API: kube-vip VIP 10.10.5.10 │ CNI: Cilium (eBPF)  │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  FluxCD GitOps Engine                               │    │
│  │  ├─ Source Controller                               │    │
│  │  ├─ Kustomize Controller                            │    │
│  │  ├─ Helm Controller                                 │    │
│  │  └─ Notification Controller                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **OS** | Talos OS | Immutable, secure Kubernetes-focused OS |
| **Config** | talhelper | Declarative Talos node configuration |
| **Orchestration** | Kubernetes | Container orchestration |
| **GitOps** | FluxCD | Continuous deployment from Git |
| **Networking** | Cilium | CNI, kube-proxy replacement (eBPF), L2 LoadBalancer |
| **HA** | kube-vip | Virtual IP for the Kubernetes API endpoint |
| **Ingress** | Traefik | HTTP(S) routing and load balancing |
| **Storage** | Longhorn | Distributed persistent volume management |
| **Certificates** | cert-manager | Automated TLS certificate management |
| **Secrets (infra)** | SOPS + age | Encrypted Talos secrets in Git |
| **Secrets (apps)** | Bitwarden SM + ESO | Runtime secret injection into workloads |

## 🎯 Roadmap

- [x] Talos OS cluster with talhelper
- [x] High availability — 3 controlplane nodes with kube-vip
- [x] Cilium CNI + eBPF kube-proxy replacement + L2 LoadBalancer
- [x] FluxCD GitOps with multi-repo structure (GitLab)
- [x] SOPS + age for Talos secrets encryption
- [x] External Secrets Operator + Bitwarden Secrets Manager
- [x] Core components — Traefik, cert-manager, Longhorn
- [x] Migrate ingress to Cilium Gateway API
- [x] Monitoring stack (Prometheus + Grafana)
- [ ] Logging stack (Loki)
- [x] Renovate for automated dependency updates
- [ ] Automated backup to cloud storage

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Acknowledgments

- [Talos OS](https://www.talos.dev/) - Immutable Kubernetes OS
- [talhelper](https://budimanjojo.github.io/talhelper/) - Declarative Talos config generator
- [FluxCD](https://fluxcd.io/) - GitOps toolkit
- [Cilium](https://cilium.io/) - eBPF-based networking
- [home-ops](https://github.com/onedr0p/home-ops) - Inspiration
- The Homelab community on r/homelab

---

**Polaris Homelab** - *Where Infrastructure Meets Innovation* ⭐

Last updated: 2026-03-14

# Karakeep

Bookmark manager and read-later service: saves links, notes and images, archives the pages with a headless browser and tags them with AI.

| | |
| --- | --- |
| **Namespace** | `karakeep` |
| **Chart** | `karakeep` |
| **URL** | `https://karakeep.${CLUSTER_DOMAIN}` |
| **Auth** | OIDC with authentik only (password login disabled) |
| **Data** | `karakeep-data` (5 Gi, `longhorn-critical`), backed up with [`volsync`](../../components/README.md#volsync) daily at 04:50 |
| **Secrets** | `karakeep-secret`, `sso-client`, `openai-cred` from Bitwarden |

## Components

| Workload | Notes |
| --- | --- |
| `karakeep` | Web app and workers. **Deployment** (not the chart default StatefulSet) so the data PVC can be created by VolSync |
| `karakeep-chrome` | Headless Chrome used to crawl pages. Image from Docker Hub (`zenika/alpine-chrome`), the original registry returns 403. Runs without the Chrome sandbox: Talos enforces PodSecurity `baseline` by default, which forbids `SYS_ADMIN` |
| `karakeep-meilisearch` | Search index. Memory and indexing threads are capped explicitly: by default Meilisearch sizes itself on the node, not the container limits, and gets OOM-killed. Not backed up — the index is rebuilt from the data |

`INFERENCE_USE_MAX_COMPLETION_TOKENS` is set because recent OpenAI models reject `max_tokens`.

# hecate-app-meshview

A Hecate plugin for observing and exploring the Macula Mesh — live topology, peers, DHT, pub/sub.

MeshView is the **resident's view** of the mesh network (topology, connectivity, peers). This is distinct from the realm dashboard which is the **landlord's view** (identity, access control).

## Architecture

MeshView is a **read-only observation app** — no ReckonDB, no evoq, no CQRS. The daemon joins hecate-daemon's BEAM cluster (same cookie) and uses `erpc:call` to read mesh state from the `hecate_mesh` facade.

```
hecate-app-meshviewd ──erpc:call──> hecate-daemon (hecate_mesh)
hecate-daemon ──knows nothing about──> meshviewd
```

One-way dependency: meshviewd depends on hecate-daemon for mesh state. hecate-daemon knows nothing about meshviewd.

## Components

| Component | Path | Description |
|-----------|------|-------------|
| **meshviewd** | `hecate-app-meshviewd/` | Erlang/OTP daemon — mesh observer + HTTP API |
| **meshvieww** | `hecate-app-meshvieww/` | SvelteKit frontend — custom element plugin |

## Development

### Daemon

```bash
cd hecate-app-meshviewd
rebar3 compile
rebar3 shell
```

### Frontend

```bash
cd hecate-app-meshvieww
npm install
npm run dev          # Dev server on :5176
npm run build:lib    # Build component.js for embedding
```

### Full rebuild

```bash
./scripts/rebuild.sh
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Daemon health check |
| GET | `/manifest` | Plugin manifest for hecate-web discovery |
| GET | `/api/mesh/status` | Cached mesh snapshot (daemon, mesh, peers) |

## Deployment

OCI images are built via CI/CD (GitHub Actions) and pushed to `ghcr.io/hecate-apps/hecate-app-meshviewd`.

```bash
# Tag and push to trigger Docker build
git tag v0.1.0
git push && git push --tags
```

## License

Apache-2.0

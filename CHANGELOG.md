# Changelog

## [0.1.0] - 2026-03-01

### Added

- Initial scaffold of hecate-app-meshview
- **hecate-app-meshviewd**: Erlang/OTP daemon for mesh observation
  - `mesh_observer` gen_server — discovers hecate-daemon via BEAM clustering,
    polls mesh state every 10s via `erpc:call`, caches snapshot
  - `mesh_status_api` — GET /api/mesh/status returns cached mesh snapshot
  - Health + manifest endpoints for plugin discovery
  - Plugin registrar for hecate-daemon integration
- **hecate-app-meshvieww**: SvelteKit frontend as ES module plugin
  - MeshStatus component — connected/disconnected indicator, node ID, peer count
  - Reactive store with periodic polling
  - Custom element (`<meshview-studio>`) for embedding in hecate-web
- **Build infrastructure**: 3-stage Dockerfile, GitHub Actions CI/CD, version bump script

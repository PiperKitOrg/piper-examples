# Piper examples

Self-contained migration examples for [piper-go](../piper-go). Each folder covers one source→target direction: start Docker for those two databases only, seed a small `shop` schema, then run `inspect` → `plan` → `execute` from that directory.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose v2
- A `piper` binary on your `PATH` (build from `piper-go`: `go build -o piper ./cmd/piper` and install somewhere on `PATH`)
- Free host ports for the databases each example binds (see the table)

Credentials are supplied only via environment variables (`PIPER_SOURCE_URL`, `PIPER_TARGET_URL`, and optional password overrides). Copy each example’s `.env.example` to `.env` before running.

## Examples

| Example | Source → Target | Status | Docker services |
|---------|-----------------|--------|-----------------|
| [relational-to-relational](./relational-to-relational/) | Postgres → MySQL | Supported | Postgres + MySQL |
| [non-relational-to-non-relational](./non-relational-to-non-relational/) | Mongo → Mongo | Supported | Mongo (source) + Mongo (target) |
| [relational-to-non-relational](./relational-to-non-relational/) | Postgres → Mongo | Supported (lossy) | Postgres + Mongo |
| [non-relational-to-relational](./non-relational-to-relational/) | Mongo → Postgres | Experimental | Mongo + Postgres |

Each example README covers compose up, seeding, `./run.sh`, and what success looks like.

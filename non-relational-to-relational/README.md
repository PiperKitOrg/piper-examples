# Non-relational → relational (Mongo → Postgres)

**Status:** Experimental

Migrates the `shop` collections (users, teams, products, orders — including a users⇄teams relationship cycle) from MongoDB into Postgres. This path is experimental: sampling may miss fields, and a reviewed IR is recommended before production use.

## Prerequisites

- Docker Compose v2
- `piper` on your `PATH` (from [piper-go](../../piper-go))
- Host ports **27017** (Mongo) and **5432** (Postgres) free

## 1. Start databases

```bash
docker compose up -d
docker compose ps   # both services should be healthy
```

## 2. Seed the source

```bash
docker compose exec -T mongo mongosh --quiet -u piper -p piper --authenticationDatabase admin < seed/source.js
```

## 3. Configure credentials

```bash
cp .env.example .env
```

URLs are already filled in for the compose stack. Passwords may stay embedded in the URLs, or you can clear them from the URLs and set `PIPER_SOURCE_PASSWORD` / `PIPER_TARGET_PASSWORD` instead.

## 4. Run the migration

From this directory:

```bash
./run.sh
```

Equivalent manual steps:

```bash
set -a && source .env && set +a
piper inspect
piper plan --target postgres --cycle-mode defer_constraints
piper execute
```

`run.sh` uses `--cycle-mode defer_constraints` because the seed includes a circular relationship between `users` and `teams`. Default `strict` planning rejects that cycle.

Artifacts land in `./.piper/` (project root is the current working directory).

## Expected result

- `inspect` writes IR under `.piper/runs/<run-id>/`
- `plan` produces a Postgres migration plan that defers the cycle edges
- `execute` creates tables and loads rows into `shop_target` on Postgres

Because this path is **experimental**, review the generated IR before relying on the result — Mongo sampling can miss optional fields present only in some documents.

Spot-check the target:

```bash
docker compose exec postgres psql -U piper -d shop_target -c "\dt" -c "SELECT COUNT(*) AS users FROM users;" -c "SELECT COUNT(*) AS orders FROM orders;"
```

You should see `teams`, `users`, `products`, and `orders`, with 2 users and 2 orders.

## Tear down

```bash
docker compose down -v
```

# Relational → non-relational (Postgres → Mongo)

**Status:** Supported (lossy)

Migrates the `shop` schema (users, teams, products, orders — including a users⇄teams FK cycle) from Postgres into MongoDB. FK enforcement is not preserved on the Mongo target.

## Prerequisites

- Docker Compose v2
- `piper` on your `PATH` (from [piper-go](../../piper-go))
- Host ports **5432** (Postgres) and **27017** (Mongo) free

## 1. Start databases

```bash
docker compose up -d
docker compose ps   # both services should be healthy
```

## 2. Seed the source

```bash
docker compose exec -T postgres psql -U piper -d shop_source < seed/source.sql
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
piper plan --target mongo --cycle-mode defer_constraints
piper execute
```

`run.sh` uses `--cycle-mode defer_constraints` because the seed includes a circular FK between `users` and `teams`. Default `strict` planning rejects that cycle.

Artifacts land in `./.piper/` (project root is the current working directory).

## Expected result

- `inspect` writes IR under `.piper/runs/<run-id>/`
- `plan` produces a Mongo migration plan that defers the cycle edges
- `execute` creates collections and loads documents into `shop_target` on Mongo

Because this path is **lossy**, relational constraints (foreign keys, unique indexes beyond what Mongo recreates) are not enforced on the target.

Spot-check the target:

```bash
docker compose exec mongo mongosh --quiet -u piper -p piper --authenticationDatabase admin shop_target --eval "db.getCollectionNames(); db.users.countDocuments(); db.orders.countDocuments();"
```

You should see `teams`, `users`, `products`, and `orders`, with 2 users and 2 orders.

## Tear down

```bash
docker compose down -v
```

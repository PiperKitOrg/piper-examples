# Relational → relational (Postgres → MySQL)

**Status:** Supported

Migrates the `shop` schema (users, teams, products, orders — including a users⇄teams FK cycle) from Postgres into MySQL.

## Prerequisites

- Docker Compose v2
- `piper` on your `PATH` (from [piper-go](../../piper-go))
- Host ports **5432** (Postgres) and **3306** (MySQL) free

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
piper plan --target mysql --cycle-mode defer_constraints
piper execute
```

`run.sh` uses `--cycle-mode defer_constraints` because the seed includes a circular FK between `users` and `teams`. Default `strict` planning rejects that cycle.

Artifacts land in `./.piper/` (project root is the current working directory).

## Expected result

- `inspect` writes IR under `.piper/runs/<run-id>/`
- `plan` produces a MySQL migration plan that defers the cycle edges
- `execute` creates tables and loads rows into `shop_target` on MySQL

Spot-check the target:

```bash
docker compose exec mysql mysql -upiper -ppiper shop_target -e "SHOW TABLES; SELECT COUNT(*) AS users FROM users; SELECT COUNT(*) AS orders FROM orders;"
```

You should see `teams`, `users`, `products`, and `orders`, with 2 users and 2 orders.

## Tear down

```bash
docker compose down -v
```

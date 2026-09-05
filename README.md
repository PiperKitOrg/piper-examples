# Piper examples

Hands-on, self-contained migrations you can run on your laptop.

Each folder is one source → target direction. You start just those two databases, seed a tiny `shop` dataset, and let [Piper](https://github.com/PiperKitOrg/piper-go) walk through `inspect` → `plan` → `execute`. No extra services, no accounts — just Docker and a `piper` binary.

If you have not used Piper yet, this repo is a friendly place to start.

## What you will need

- [Docker](https://docs.docker.com/get-docker/) with Compose v2
- A `piper` binary on your `PATH`

Install Piper from a [release](https://github.com/piperkit/piper/releases), Homebrew (`brew install piperkit/tap/piper`), or build it from [piper-go](https://github.com/PiperKitOrg/piper-go):

```bash
go build -o piper ./cmd/piper
# then move `piper` somewhere on your PATH
```

Credentials never live in the compose files. Copy each example’s `.env.example` to `.env` before you run anything.

Run **one example at a time**. They share host ports (Postgres `5432`, MySQL `3306`, Mongo `27017`), so two stacks at once will collide.

## Pick an example

| Folder | What it does | Status | Ports |
|--------|----------------|--------|-------|
| [relational-to-relational](./relational-to-relational/) | Postgres → MySQL | Supported | `5432`, `3306` |
| [non-relational-to-non-relational](./non-relational-to-non-relational/) | Mongo → Mongo | Supported | `27017`, `27018` |
| [relational-to-non-relational](./relational-to-non-relational/) | Postgres → Mongo | Supported (lossy) | `5432`, `27017` |
| [non-relational-to-relational](./non-relational-to-relational/) | Mongo → Postgres | Experimental | `27017`, `5432` |

**Lossy** means foreign keys and some unique constraints do not survive on Mongo. **Experimental** means Mongo sampling can miss optional fields — peek at the generated IR before you trust the result.

Every example README has the exact seed command, `./run.sh` usage, and a spot-check query for that pair.

## Try one now (Postgres → MySQL)

This is the shortest path from “clone” to “rows on the other side.”

```bash
cd relational-to-relational

docker compose up -d
docker compose ps          # both services should be healthy

docker compose exec -T postgres psql -U piper -d shop_source < seed/source.sql

cp .env.example .env
./run.sh
```

`run.sh` loads `.env` and runs the three Piper commands for you. When it finishes, peek at MySQL:

```bash
docker compose exec mysql mysql -upiper -ppiper shop_target \
  -e "SHOW TABLES; SELECT COUNT(*) AS users FROM users; SELECT COUNT(*) AS orders FROM orders;"
```

You should see `teams`, `users`, `products`, and `orders`, with 2 users and 2 orders.

Finished playing?

```bash
docker compose down -v
```

That `-v` drops the volumes, so the next run starts clean.

## What lives in `shop`

Every example uses the same tiny store:

- **teams** and **users** — they point at each other (a foreign-key cycle)
- **products**
- **orders** — each order belongs to a user and a product

Ada and Grace shop at team Alpha. Two products, two orders. Small enough to read in one sitting, awkward enough (that cycle) to show why Piper asks you to plan carefully.

## What Piper actually does

From inside an example folder, the flow is always the same:

1. **`piper inspect`** — reads the source and writes an intermediate representation under `.piper/runs/<run-id>/`
2. **`piper plan`** — turns that IR into a migration plan for the target dialect
3. **`piper execute`** — creates tables or collections and copies the rows

You can run those by hand after `source .env`, or just use `./run.sh`. Artifacts stay in that example’s `.piper/` folder (Piper treats the current working directory as the project root).

### Why `--cycle-mode defer_constraints`

The seed includes a circular relationship between `users` and `teams`. Piper’s default `strict` planner refuses that cycle — which is the safe choice. These examples pass `--cycle-mode defer_constraints` so planning can continue by applying the cycle edges after the rows are loaded.

## Credentials

Each `.env.example` already points at the compose stack. Passwords can stay inside the URLs, or you can strip them out and set `PIPER_SOURCE_PASSWORD` / `PIPER_TARGET_PASSWORD` instead.

```bash
# typical .env (relational-to-relational)
PIPER_SOURCE_URL=postgres://piper:piper@127.0.0.1:5432/shop_source?sslmode=disable
PIPER_TARGET_URL=mysql://piper:piper@127.0.0.1:3306/shop_target?sslmode=disable
```

## If something feels stuck

- **Port already in use** — another example (or a local Postgres/MySQL/Mongo) is bound to the same port. Tear the other stack down, or stop the local service.
- **`missing .env`** — copy `.env.example` to `.env` in that folder. `run.sh` will not invent one for you.
- **`piper: command not found`** — the binary is not on your `PATH`. Confirm with `which piper`.
- **Plan fails on a cycle** — you ran `piper plan` without `--cycle-mode defer_constraints`. Use `./run.sh`, or pass that flag yourself.
- **Services not healthy yet** — wait a few seconds and run `docker compose ps` again. MySQL in particular can take a moment on first boot.

Have fun — and if a run surprises you, the files under `.piper/` are there so you can see exactly what Piper saw and what it planned to do.

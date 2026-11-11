# Piper playground

Welcome! This is a small local stack where you can try Piper on three real datasets. Employees loads into MySQL, Pagila into PostgreSQL, and the MongoDB sample databases into MongoDB. Piper migrates **across engines only** — six combinations (same-dialect pairs are unsupported).

Here's how the scripts fit together:

- `run.sh` runs one combination (we call it a "cell"). It clears that cell's target, deletes its `.piper` directory, then runs `inspect`, `plan`, and `execute` for you.
- `commands.sh` prints those same commands so you can type them yourself and see what's happening.
- `matrix.sh` runs all six supported cells in one go.

## The matrix

| Dataset | Source | Supported targets | Plan |
| --- | --- | --- | --- |
| `employees` | MySQL database `employees` | `postgres`, `mongo` | default cycle mode |
| `pagila` | PostgreSQL database `pagila` | `mysql`, `mongo` | `--cycle-mode defer_constraints` |
| `sample` | MongoDB database `sample_mflix` | `mysql`, `postgres` | `inspect --sample-full` |

`load.sh sample` imports every sample database: `sample_airbnb`, `sample_analytics`, `sample_geospatial`, `sample_mflix`, `sample_supplies`, `sample_training`, and `sample_weatherdata`. The scripted cell copies `sample_mflix`. If you'd like to try one of the others, use `commands.sh` and run it by hand.

The target database name matches the source dataset name on the other engine:

| Cell | Target database |
| --- | --- |
| employees → postgres | `employees` |
| employees → mongo | `employees` |
| pagila → mysql | `pagila` |
| pagila → mongo | `pagila` |
| sample → mysql | `sample_mflix` |
| sample → postgres | `sample_mflix` |

Same-engine cells (`employees → mysql`, `pagila → postgres`, `sample → mongo`) are rejected by the scripts and by Piper.

## Before you start

You only need two things: Docker Compose v2 and the `piper` binary. Nothing else has to be installed.

Drop the binary into `bin/` and make it executable:

```bash
cp /path/to/piper bin/piper
chmod +x bin/piper
```

The scripts look for `bin/piper` first. If it isn't there, they try `../piper-go/piper`, then `piper` on your `PATH`.

Make sure these ports are free: PostgreSQL `5432`, MySQL `3306`, MongoDB `27017`.

The local passwords are:

| Engine | User | Password |
| --- | --- | --- |
| PostgreSQL | `postgres` | `playground` |
| MySQL app user | `playground` | `playground` |
| MySQL root | `root` | `root` |
| MongoDB | `playground` | `playground` |

A quick note on PostgreSQL: we use the `pgvector/pgvector:pg18` image because Pagila's `film_embedding.embedding` column is `vector(20)`.

## 1. Start the stack

From this directory:

```bash
./playground/up.sh
```

## 2. Load a source

Pick one, or load all three:

```bash
./playground/load.sh employees
./playground/load.sh pagila
./playground/load.sh sample
```

Each load drops that source and loads it fresh. Your other sources and all targets are left as they are. Heads up: employees is about 3,919,015 table rows, so give it a moment. The sample import reads the JSON files under `datasets/mongodb-sample-dataset`.

## 3. Run one cell

```bash
./playground/run.sh employees postgres
./playground/run.sh employees mongo
./playground/run.sh pagila mysql
./playground/run.sh pagila mongo
./playground/run.sh sample mysql
./playground/run.sh sample postgres
```

Artifacts and the generated `.env` for each cell live in `runs/<dataset>-to-<target>/`.

## Or load an e2e fixture and migrate by hand

The playground also ships the Piper e2e fixture pack under `datasets/e2e-fixtures/` (kitchen-sink types, unicode, partitions, cycles, Mongo edges, etc.).

```bash
./playground/fixture.sh list
./playground/fixture.sh load production_weird
./playground/fixture.sh commands production_weird mysql
```

`load` creates a source database named after the fixture id (e.g. `production_weird`) on that fixture's engine. `commands` writes `runs/fixture-<id>-to-<target>/.env` and prints the `inspect` / `plan` / `execute` lines to copy.

Same-dialect targets are rejected here too. Some Postgres fixtures (for example `pgnimbus_types`) need extra extensions; if load fails, read the error and install what's missing on the playground Postgres image.

## Prefer to type the commands yourself?

Great way to learn! `commands.sh` writes the cell's `.env` and prints the commands. It doesn't run Piper, so you stay in control.

```bash
./playground/commands.sh employees postgres
```

From the piper-example directory, that prints:

```bash
./playground/clear.sh target employees postgres
cd runs/employees-to-postgres
rm -rf .piper
set -a
source .env
set +a
./piper inspect
./piper plan --target postgres
./piper --yes execute
cd ../..
```

Each cell gets a `./piper` symlink to `runs/piper`, which finds `bin/piper` for you.

The `.env` in that directory looks like this:

```bash
PIPER_SOURCE_URL=mysql://playground:playground@127.0.0.1:3306/employees?sslmode=disable
PIPER_TARGET_URL=postgres://postgres:playground@127.0.0.1:5432/employees?sslmode=disable
```

A couple of small differences to know about: Pagila's plan line adds `--cycle-mode defer_constraints`, and a sample cell's inspect line is `inspect --sample-full`.

Want to try a different sample database?

```bash
./playground/commands.sh sample mysql sample_analytics
```

That cell is `runs/sample_analytics-to-mysql`, and its target database is `sample_analytics`.

## Run every cell

Feeling ambitious? Load all three sources first, then:

```bash
./playground/matrix.sh
```

It runs the six `run.sh` commands above, in that order. As a reminder, `run.sh sample` copies `sample_mflix`, not the other sample databases.

## Clear a target

Use this when you want a target empty and you're not about to call `run.sh` (which already clears the target it's about to fill).

```bash
./playground/clear.sh target employees postgres
./playground/clear.sh target employees mongo
./playground/clear.sh target pagila mysql
./playground/clear.sh target pagila mongo
./playground/clear.sh target sample mysql
./playground/clear.sh target sample postgres
```

For a different sample database:

```bash
./playground/clear.sh target sample postgres sample_analytics
```

MySQL and PostgreSQL targets are dropped and recreated empty. A MongoDB target is simply dropped.

## Clear a source

Want a dataset gone? Clear it, and load it again before your next `run.sh`.

```bash
./playground/clear.sh source employees
./playground/load.sh employees

./playground/clear.sh source pagila
./playground/load.sh pagila

./playground/clear.sh source sample
./playground/load.sh sample
```

Clearing `sample` drops all seven sample databases.

## How do I know it worked?

A passing cell checks these row counts:

| Dataset | Table | Rows |
| --- | --- | --- |
| employees | `departments` | 9 |
| employees | `dept_manager` | 24 |
| employees | `employees` | 300,024 |
| employees | `dept_emp` | 331,603 |
| employees | `titles` | 443,308 |
| employees | `salaries` | 2,844,047 |
| pagila | `film` | 1,000 |
| pagila | `rental` | 51,805 |
| pagila | `payment` | 51,061 |
| sample | `comments` | 50,304 |
| sample | `movies` | 23,539 |
| sample | `sessions` | 1 |
| sample | `theaters` | 1,564 |
| sample | `users` | 185 |

You can run the check yourself any time:

```bash
./playground/check.sh employees postgres
./playground/check.sh sample mysql
```

## All done? Shut it down

```bash
./playground/down.sh
```

This removes the Docker volumes, so the next `up` starts with empty servers. You'll need to load your sources again.

## What's where

```text
bin/piper                         the binary you copy in
datasets/test_db                  employees dump
datasets/pagila                   pagila dump
datasets/mongodb-sample-dataset   MongoDB sample JSON
datasets/e2e-fixtures             Piper e2e fixture pack + catalog.json
playground/                       up, down, load, clear, run, commands, fixture, check, matrix
runs/piper                        shortcut wrapper; cell dirs symlink ./piper here
runs/                             one directory per cell
docker-compose.yml                PostgreSQL 18 + pgvector, MySQL 8.4, MongoDB 7
```

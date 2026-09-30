# Piper playground

One local stack, two datasets, six copies. Employees comes from `test_db` and is loaded into MySQL. Pagila is loaded into PostgreSQL. Each dataset is then copied to MySQL, PostgreSQL, and MongoDB.

`run.sh` is one cell. It clears that cell's target, deletes that cell's `.piper` directory, and runs `inspect`, `plan`, and `execute`. The source stays loaded. `matrix.sh` runs all six cells.

## Matrix

| Dataset | Source | Targets | Plan |
| --- | --- | --- | --- |
| `employees` | MySQL database `employees` | `mysql`, `postgres`, `mongo` | default cycle mode |
| `pagila` | PostgreSQL database `pagila` | `mysql`, `postgres`, `mongo` | `--cycle-mode defer_constraints` |

Same-engine copies use a second database, so clearing the target leaves the source in place:

| Cell | Target database |
| --- | --- |
| employees → mysql | `employees_target` |
| employees → postgres | `employees` |
| employees → mongo | `employees` |
| pagila → mysql | `pagila` |
| pagila → postgres | `pagila_target` |
| pagila → mongo | `pagila` |

## What you need

Docker Compose v2, and a `piper` binary. The scripts use `$PIPER_BIN` when it is set, then `../piper-go/piper`, then `piper` on `PATH`.

Ports: PostgreSQL `5432`, MySQL `3306`, MongoDB `27017`.

Local passwords:

| Engine | User | Password |
| --- | --- | --- |
| PostgreSQL | `postgres` | `piper` |
| MySQL app user | `piper` | `piper` |
| MySQL root | `root` | `root` |
| MongoDB | `piper` | `piper` |

PostgreSQL is the `pgvector/pgvector:pg18` image because Pagila's `film_embedding.embedding` column is `vector(20)`.

## Start

From this directory:

```bash
./playground/up.sh
```

## Load a source

Employees runs `datasets/test_db/employees.sql` (about 3,919,015 table rows). Pagila runs `pagila-schema.sql`, then `pagila-data.sql`.

```bash
./playground/load.sh employees
./playground/load.sh pagila
```

Each load drops that source database and loads it again. The other source, and every target, stay as they are.

## Run one cell

```bash
./playground/run.sh employees mysql
./playground/run.sh employees postgres
./playground/run.sh employees mongo
./playground/run.sh pagila mysql
./playground/run.sh pagila postgres
./playground/run.sh pagila mongo
```

Artifacts and the generated `.env` for a cell live in `runs/<dataset>-to-<target>/`.

Employees → each target is the long copy. Pagila is the smaller one.

## Run every cell

```bash
./playground/matrix.sh
```

Load both sources first. The matrix runs the six commands above, in that order.

## Clear a target

Use this when you want that target empty and you are not about to call `run.sh`. `run.sh` already clears the target it is about to fill.

```bash
./playground/clear.sh target employees mysql
./playground/clear.sh target employees postgres
./playground/clear.sh target employees mongo
./playground/clear.sh target pagila mysql
./playground/clear.sh target pagila postgres
./playground/clear.sh target pagila mongo
```

MySQL and PostgreSQL targets are dropped and created empty. A MongoDB target is dropped.

## Clear a source

Use this when you want the loaded dataset gone. Load it again before the next `run.sh`.

```bash
./playground/clear.sh source employees
./playground/load.sh employees

./playground/clear.sh source pagila
./playground/load.sh pagila
```

## Counts a passing cell checks

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

Check a target that already finished:

```bash
./playground/check.sh employees postgres
./playground/check.sh pagila mysql
```

## Stop

```bash
./playground/down.sh
```

That removes the Docker volumes. The next `up` starts empty servers. Load both sources again.

## Layout

```text
datasets/test_db    employees dump, moved here with its own git history
datasets/pagila     pagila dump, moved here with its own git history
playground/         up, down, load, clear, run, check, matrix
runs/               one directory per cell
docker-compose.yml  PostgreSQL 18 + pgvector, MySQL 8.4, MongoDB 7
```

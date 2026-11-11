# Piper Playground

A small local stack for trying Piper on three real datasets.

## What's in this repo

```text
piper-example/
├── bin/                 # Put your Piper binary here (bin/piper)
├── datasets/            # Sample databases for testing migrations
├── docker-compose.yml   # Starts MySQL, PostgreSQL, and MongoDB locally
├── playground/          # Scripts to load sample data and reset databases
└── runs/
    └── piper            # Shortcut to the Piper binary in bin/
                         # Place the binary there before using it
```

## Datasets

| Database      | Dataset             | Loads into |
| ------------- | ------------------- | ---------- |
| Employees     | `datasets/mysql`    | MySQL      |
| Pagila        | `datasets/postgres` | PostgreSQL |
| Mongo samples | `datasets/mongodb`  | MongoDB    |

With three databases, there are six possible migration directions. Same-dialect pairs (e.g. MySQL → MySQL) are not supported.

## Setup

1. Review `docker-compose.yml` in the repo root. It's short, and you should always know what you're running.
2. Put the Piper binary at `bin/piper` and make it executable (`chmod +x bin/piper`).
3. Start the stack:
   ```bash
    docker compose up -d
   ```

## Walkthrough: MySQL → PostgreSQL

You can try any of the six directions. This walkthrough migrates the **Employees** dataset from MySQL to PostgreSQL.

### 1. Make sure Piper can run

- **macOS:** if the binary is blocked, run:
  ```bash
  xattr -d com.apple.quarantine bin/piper
  chmod +x bin/piper   # only if needed
  ```
- **Windows:** if a security prompt appears, confirm that you want to run it.
- **Linux:** nothing to do, though you may need `chmod +x bin/piper`.

Then, from the repo root, check that it works:

```bash
bin/piper --help
```

### 2. Prepare the run directory

From the repo root:

```bash
# Clear the target database (only needed if it has leftover data)
./playground/clear.sh target employees postgres

mkdir -p runs/mysql-to-postgres
cd runs/mysql-to-postgres
ln -sfn ../piper ./piper
```

### 3. Configure the connections

Create a `.env` file in this directory:

```env
PIPER_SOURCE_URL=mysql://playground:playground@127.0.0.1:3306/employees?sslmode=disable
PIPER_TARGET_URL=postgres://postgres:playground@127.0.0.1:5432/employees?sslmode=disable
```

> If you changed ports or credentials in `docker-compose.yml`, update these URLs to match.

Load the variables into your shell (re-run this whenever you edit `.env`):

```bash
set -a
source .env
set +a
```

> **Starting fresh?** Piper keeps its artifacts in `.piper`. Leftovers are harmless, but you can reset with `rm -rf .piper`.

### 4. Run the migration

```bash
./piper inspect
./piper plan --target postgres
./piper execute --yes
```

Done! 🎉

## Learn more

Full documentation: [piperbyadam.vercel.app](https://piperbyadam.vercel.app)

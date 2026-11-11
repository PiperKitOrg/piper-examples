# Piper playground

Welcome! This is a small local stack where you can try Piper on three real datasets. 

We have:

- Employees: `datasets/test_db` which loads into MySQL
- Pagila: `datasets/pagila` which loads into Postgres
- Mongo sample data: `datasets/mongodb-sample-dataset` which loads into Mongo.

All 3 gives you 6 possible migration matrix direction, same-dialect pairs are not supported.

## Before you start:

Take a look at `docker-compose.yml` in the root directory just in case I put anything suspicious there.
Didn't find anything? Good!
Let's up our docker! 

`docker compose up -d`

## Migration

With 6 possible migration direction, you may try whichever you please but for this example,
I will choose the PostgreSQL <-> MongoDB one to display.

**Let's start:**

1. Before we do the run, ensure Piper is allowed on your computer.
- If you're on Mac, you may do something like this if you encounter any problem that won't allow you to run:
`xattr -d com.apple.quarantine ./piper` and `chmod +x ./piper` if need.

- If you're on windows, you may get a pop up asking if you're sure you wanna run it, just click yes.
- If you're on linux, it's silent, worst case scenario, the computer dies because you didn't plug in your charger.



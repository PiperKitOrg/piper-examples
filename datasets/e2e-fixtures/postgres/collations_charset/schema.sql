-- M4-A: Postgres citext + unique text toward MySQL CI collation warnings.
-- Trailing-space CHAR and Turkish I rows stay tiny and deterministic.

CREATE EXTENSION IF NOT EXISTS citext;

DROP TABLE IF EXISTS login_aliases CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;

CREATE TABLE accounts (
  id            INTEGER PRIMARY KEY,
  email         CITEXT NOT NULL,
  handle        CITEXT NOT NULL,
  label_pad     CHAR(8) NOT NULL,
  note          TEXT,
  CONSTRAINT accounts_email_uidx UNIQUE (email),
  CONSTRAINT accounts_handle_uidx UNIQUE (handle),
  CONSTRAINT accounts_label_pad_uidx UNIQUE (label_pad)
);

CREATE TABLE login_aliases (
  id            INTEGER PRIMARY KEY,
  account_id    INTEGER NOT NULL REFERENCES accounts (id),
  alias_name    TEXT NOT NULL,
  CONSTRAINT login_aliases_alias_uidx UNIQUE (alias_name)
);

INSERT INTO accounts (id, email, handle, label_pad, note) VALUES
  (1, 'Ada@Example.com', 'Istanbul', 'alpha   ', 'citext email'),
  (2, 'bob@example.com', 'ankara', 'beta    ', 'turkish-ish handle + pad CHAR');

INSERT INTO login_aliases (id, account_id, alias_name) VALUES
  (1, 1, 'Ada'),
  (2, 2, 'bob ');

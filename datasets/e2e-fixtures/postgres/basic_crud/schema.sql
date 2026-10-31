DROP TABLE IF EXISTS items CASCADE;
DROP TABLE IF EXISTS empty_box CASCADE;

CREATE TABLE items (
  id          INTEGER PRIMARY KEY,
  name        TEXT NOT NULL,
  note        TEXT NULL,
  qty         INTEGER NOT NULL DEFAULT 0,
  price       NUMERIC(12, 2) NOT NULL,
  active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX items_name_uidx ON items (name);

CREATE TABLE empty_box (
  id INTEGER PRIMARY KEY,
  label TEXT
);

INSERT INTO items (id, name, note, qty, price, active, created_at) VALUES
  (1, 'alpha', NULL, 3, 10.50, TRUE, '2024-01-01T00:00:00Z'),
  (2, 'beta', 'unicode café', 0, 0.01, FALSE, '2024-06-15T12:30:00Z'),
  (3, 'gamma', 'line1', 100, 9999.99, TRUE, '2025-01-01T08:00:00Z');

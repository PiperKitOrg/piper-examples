-- Shop schema for R → non-R migration testing.
--
-- Designed to test:
--   - FK cycles: users <-> teams
--   - 1:N relationships: users -> orders
--   - N:1 relationship: orders -> products
--   - nullable FK: teams.owner_user_id
--   - unique constraint: users.email
--   - defaults
--   - numeric / boolean / timestamp types
--   - multiple users in the same team
--   - multiple orders per user
--   - multiple orders for the same product
--   - orphan-like optional relationships (team without owner)

DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS teams CASCADE;

CREATE TABLE teams (
  id SERIAL PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  owner_user_id INTEGER NULL
);

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  email VARCHAR(256) NOT NULL UNIQUE,
  team_id INTEGER NULL REFERENCES teams (id)
);

ALTER TABLE teams
  ADD CONSTRAINT teams_owner_user_fk
  FOREIGN KEY (owner_user_id) REFERENCES users (id);

CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  price NUMERIC(12, 2) NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users (id),
  product_id INTEGER NOT NULL REFERENCES products (id),
  quantity INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- Teams
-- ------------------------------------------------------------

INSERT INTO teams (id, name, owner_user_id) VALUES
  (1, 'Alpha', NULL),
  (2, 'Beta', NULL),
  (3, 'Gamma', NULL);

-- ------------------------------------------------------------
-- Users
-- ------------------------------------------------------------

INSERT INTO users (id, name, email, team_id) VALUES
  (1, 'Ada',     'ada@example.com',     1),
  (2, 'Grace',   'grace@example.com',   1),
  (3, 'Linus',   'linus@example.com',   1),
  (4, 'Dennis',  'dennis@example.com',  2),
  (5, 'Margaret','margaret@example.com',2),
  (6, 'Ken',     'ken@example.com',     NULL);

-- Complete the users <-> teams cycle.
UPDATE teams SET owner_user_id = 1 WHERE id = 1;
UPDATE teams SET owner_user_id = 4 WHERE id = 2;

-- Gamma intentionally has no owner.

-- ------------------------------------------------------------
-- Products
-- ------------------------------------------------------------

INSERT INTO products (id, name, price, active) VALUES
  (1, 'Widget',       9.99,  TRUE),
  (2, 'Gadget',       19.50, TRUE),
  (3, 'Premium Box',  49.99, TRUE),
  (4, 'Legacy Cable', 2.50,  FALSE);

-- ------------------------------------------------------------
-- Orders
-- ------------------------------------------------------------

INSERT INTO orders (id, user_id, product_id, quantity, created_at) VALUES
  (1, 1, 1, 2, '2026-01-10 10:00:00+00'),
  (2, 1, 2, 1, '2026-01-11 11:30:00+00'),
  (3, 1, 1, 5, '2026-01-15 09:15:00+00'),

  (4, 2, 2, 1, '2026-02-01 14:00:00+00'),
  (5, 2, 3, 2, '2026-02-03 16:45:00+00'),

  (6, 3, 1, 1, '2026-02-10 08:20:00+00'),

  (7, 4, 3, 3, '2026-03-01 12:00:00+00'),
  (8, 4, 2, 2, '2026-03-02 13:10:00+00'),

  (9, 5, 1, 10, '2026-03-05 17:30:00+00'),

  -- Ken has no team and no orders.
  -- This is useful for testing sparse/optional relationships.
  (10, 5, 4, 1, '2026-03-10 09:00:00+00');

-- ------------------------------------------------------------
-- Restore sequences
-- ------------------------------------------------------------

SELECT setval(
  pg_get_serial_sequence('teams', 'id'),
  (SELECT MAX(id) FROM teams)
);

SELECT setval(
  pg_get_serial_sequence('users', 'id'),
  (SELECT MAX(id) FROM users)
);

SELECT setval(
  pg_get_serial_sequence('products', 'id'),
  (SELECT MAX(id) FROM products)
);

SELECT setval(
  pg_get_serial_sequence('orders', 'id'),
  (SELECT MAX(id) FROM orders)
);
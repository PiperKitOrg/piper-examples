-- Shop schema with a two-table users⇄teams FK cycle (matches piper-go testdata shop_with_cycle).

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

INSERT INTO teams (id, name, owner_user_id) VALUES (1, 'Alpha', NULL);
INSERT INTO users (id, name, email, team_id) VALUES
  (1, 'Ada', 'ada@example.com', 1),
  (2, 'Grace', 'grace@example.com', 1);
UPDATE teams SET owner_user_id = 1 WHERE id = 1;

INSERT INTO products (id, name, price, active) VALUES
  (1, 'Widget', 9.99, TRUE),
  (2, 'Gadget', 19.50, TRUE);

INSERT INTO orders (id, user_id, product_id, quantity) VALUES
  (1, 1, 1, 2),
  (2, 2, 2, 1);

SELECT setval(pg_get_serial_sequence('teams', 'id'), (SELECT MAX(id) FROM teams));
SELECT setval(pg_get_serial_sequence('users', 'id'), (SELECT MAX(id) FROM users));
SELECT setval(pg_get_serial_sequence('products', 'id'), (SELECT MAX(id) FROM products));
SELECT setval(pg_get_serial_sequence('orders', 'id'), (SELECT MAX(id) FROM orders));

-- Shop schema for Piper testing.
-- Exercises:
--   - FK cycle: users ⇄ teams
--   - Simple 1:N: users → orders
--   - Multiple references to the same table
--   - Nullable relationships
--   - Deeper dependency chains
--   - Many-to-many relationship
--   - Self-referencing relationship

DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS product_categories CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS addresses CASCADE;
DROP TABLE IF EXISTS teams CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE teams (
  id SERIAL PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  owner_user_id INTEGER NULL
);

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  email VARCHAR(256) NOT NULL UNIQUE,
  team_id INTEGER NULL REFERENCES teams (id),
  manager_id INTEGER NULL REFERENCES users (id)
);

ALTER TABLE teams
  ADD CONSTRAINT teams_owner_user_fk
  FOREIGN KEY (owner_user_id) REFERENCES users (id);

CREATE TABLE addresses (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users (id),
  label VARCHAR(64) NOT NULL,
  street VARCHAR(255) NOT NULL,
  city VARCHAR(128) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  price NUMERIC(12, 2) NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by INTEGER NULL REFERENCES users (id)
);

CREATE TABLE categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(128) NOT NULL UNIQUE,
  parent_id INTEGER NULL REFERENCES categories (id)
);

-- Many-to-many: products ⇄ categories
CREATE TABLE product_categories (
  product_id INTEGER NOT NULL REFERENCES products (id),
  category_id INTEGER NOT NULL REFERENCES categories (id),
  PRIMARY KEY (product_id, category_id)
);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users (id),
  product_id INTEGER NOT NULL REFERENCES products (id),
  shipping_address_id INTEGER NULL REFERENCES addresses (id),
  quantity INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Another layer below orders.
CREATE TABLE order_items (
  id SERIAL PRIMARY KEY,
  order_id INTEGER NOT NULL REFERENCES orders (id),
  product_id INTEGER NOT NULL REFERENCES products (id),
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price NUMERIC(12, 2) NOT NULL
);


-- ============================================================
-- DATA
-- ============================================================

INSERT INTO teams (id, name, owner_user_id)
VALUES
  (1, 'Alpha', NULL),
  (2, 'Beta', NULL),
  (3, 'Platform', NULL);

INSERT INTO users (id, name, email, team_id, manager_id)
VALUES
  (1, 'Ada',   'ada@example.com',   1, NULL),
  (2, 'Grace', 'grace@example.com', 1, 1),
  (3, 'Linus', 'linus@example.com', 2, NULL),
  (4, 'Dennis','dennis@example.com', 2, 3),
  (5, 'Ken',   'ken@example.com',   3, 1),
  (6, 'Rob',   'rob@example.com',   NULL, NULL);

UPDATE teams
SET owner_user_id = CASE id
  WHEN 1 THEN 1
  WHEN 2 THEN 3
  WHEN 3 THEN 5
END
WHERE id IN (1, 2, 3);


INSERT INTO addresses
  (id, user_id, label, street, city, is_default)
VALUES
  (1, 1, 'Home',   '1 Main Street',   'Phnom Penh', TRUE),
  (2, 1, 'Office', '10 Tech Street',  'Phnom Penh', FALSE),
  (3, 2, 'Home',   '20 River Road',   'Phnom Penh', TRUE),
  (4, 3, 'Home',   '30 Mountain Road', 'Sen Monorom', TRUE);


INSERT INTO products
  (id, name, price, active, created_by)
VALUES
  (1, 'Widget',  9.99,  TRUE, 1),
  (2, 'Gadget',  19.50, TRUE, 2),
  (3, 'Cable',   4.25,  TRUE, 3),
  (4, 'Adapter', 14.00, TRUE, NULL),
  (5, 'Legacy',  99.99, FALSE, 5);


INSERT INTO categories
  (id, name, parent_id)
VALUES
  (1, 'Electronics', NULL),
  (2, 'Accessories', 1),
  (3, 'Cables', 2),
  (4, 'Adapters', 2),
  (5, 'Legacy', NULL);


INSERT INTO product_categories (product_id, category_id)
VALUES
  (1, 1),
  (2, 1),
  (2, 2),
  (3, 2),
  (3, 3),
  (4, 2),
  (4, 4),
  (5, 5);


INSERT INTO orders
  (id, user_id, product_id, shipping_address_id, quantity)
VALUES
  (1, 1, 1, 1, 2),
  (2, 2, 2, 3, 1),
  (3, 3, 3, 4, 5),
  (4, 1, 4, 2, 1),
  (5, 6, 5, NULL, 1);


INSERT INTO order_items
  (id, order_id, product_id, quantity, unit_price)
VALUES
  (1, 1, 1, 2, 9.99),
  (2, 1, 3, 1, 4.25),
  (3, 2, 2, 1, 19.50),
  (4, 3, 3, 5, 4.25),
  (5, 4, 4, 1, 14.00),
  (6, 5, 5, 1, 99.99);


-- Keep SERIAL sequences sane after explicit IDs.
SELECT setval(pg_get_serial_sequence('teams', 'id'),
              (SELECT MAX(id) FROM teams));

SELECT setval(pg_get_serial_sequence('users', 'id'),
              (SELECT MAX(id) FROM users));

SELECT setval(pg_get_serial_sequence('addresses', 'id'),
              (SELECT MAX(id) FROM addresses));

SELECT setval(pg_get_serial_sequence('products', 'id'),
              (SELECT MAX(id) FROM products));

SELECT setval(pg_get_serial_sequence('categories', 'id'),
              (SELECT MAX(id) FROM categories));

SELECT setval(pg_get_serial_sequence('orders', 'id'),
              (SELECT MAX(id) FROM orders));

SELECT setval(pg_get_serial_sequence('order_items', 'id'),
              (SELECT MAX(id) FROM order_items));
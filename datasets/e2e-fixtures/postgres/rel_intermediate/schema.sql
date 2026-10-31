DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL
);

CREATE TABLE categories (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  parent_id INTEGER NULL REFERENCES categories(id)
);

CREATE TABLE products (
  id INTEGER PRIMARY KEY,
  sku TEXT NOT NULL UNIQUE,
  category_id INTEGER NOT NULL REFERENCES categories(id),
  attrs JSONB NOT NULL,
  price NUMERIC(10, 2) NOT NULL
);

CREATE TABLE orders (
  id INTEGER PRIMARY KEY,
  customer_id INTEGER NOT NULL REFERENCES customers(id),
  placed_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE order_items (
  order_id INTEGER NOT NULL REFERENCES orders(id),
  product_id INTEGER NOT NULL REFERENCES products(id),
  qty INTEGER NOT NULL,
  PRIMARY KEY (order_id, product_id)
);

INSERT INTO customers (id, email, full_name) VALUES
  (1, 'a@example.com', 'Ada Lovelace'),
  (2, 'b@example.com', 'Alan Turing');

INSERT INTO categories (id, name, parent_id) VALUES
  (1, 'root', NULL),
  (2, 'books', 1),
  (3, 'tech', 2);

INSERT INTO products (id, sku, category_id, attrs, price) VALUES
  (1, 'SKU-1', 3, '{"color":"blue"}', 12.00),
  (2, 'SKU-2', 2, '{"pages":200}', 8.50);

INSERT INTO orders (id, customer_id, placed_at) VALUES
  (1, 1, '2024-02-01T10:00:00Z'),
  (2, 2, '2024-03-01T11:00:00Z');

INSERT INTO order_items (order_id, product_id, qty) VALUES
  (1, 1, 2),
  (1, 2, 1),
  (2, 2, 4);

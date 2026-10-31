SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;
SET FOREIGN_KEY_CHECKS=1;

CREATE TABLE customers (
  id INT PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  UNIQUE KEY customers_email_uidx (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE categories (
  id INT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  parent_id INT NULL,
  CONSTRAINT categories_parent_fk FOREIGN KEY (parent_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE products (
  id INT PRIMARY KEY,
  sku VARCHAR(64) NOT NULL,
  category_id INT NOT NULL,
  attrs JSON NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  UNIQUE KEY products_sku_uidx (sku),
  CONSTRAINT products_category_fk FOREIGN KEY (category_id) REFERENCES categories(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE orders (
  id INT PRIMARY KEY,
  customer_id INT NOT NULL,
  placed_at TIMESTAMP NOT NULL,
  CONSTRAINT orders_customer_fk FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE order_items (
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  qty INT NOT NULL,
  PRIMARY KEY (order_id, product_id),
  CONSTRAINT oi_order_fk FOREIGN KEY (order_id) REFERENCES orders(id),
  CONSTRAINT oi_product_fk FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO customers (id, email, full_name) VALUES
  (1, 'a@example.com', 'Ada Lovelace'),
  (2, 'b@example.com', 'Alan Turing');

INSERT INTO categories (id, name, parent_id) VALUES
  (1, 'root', NULL),
  (2, 'books', 1),
  (3, 'tech', 2);

INSERT INTO products (id, sku, category_id, attrs, price) VALUES
  (1, 'SKU-1', 3, JSON_OBJECT('color', 'blue'), 12.00),
  (2, 'SKU-2', 2, JSON_OBJECT('pages', 200), 8.50);

INSERT INTO orders (id, customer_id, placed_at) VALUES
  (1, 1, '2024-02-01 10:00:00'),
  (2, 2, '2024-03-01 11:00:00');

INSERT INTO order_items (order_id, product_id, qty) VALUES
  (1, 1, 2),
  (1, 2, 1),
  (2, 2, 4);

-- Shop schema for Piper testing.
-- MySQL counterpart to seed-postgres.sql.
--
-- Exercises:
--   - FK cycle: users ⇄ teams
--   - Self-referencing FK: users.manager_id
--   - Simple 1:N relationships
--   - Multiple references to the same table
--   - Nullable relationships
--   - Deeper dependency chains
--   - Many-to-many relationship
--   - Decimal values
--   - Boolean values
--   - Timestamp values

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS product_categories;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS addresses;
DROP TABLE IF EXISTS teams;
DROP TABLE IF EXISTS users;

SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================
-- SCHEMA
-- ============================================================

CREATE TABLE teams (
  id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(128) NOT NULL,
  owner_user_id INT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE users (
  id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(128) NOT NULL,
  email VARCHAR(256) NOT NULL,
  team_id INT NULL,
  manager_id INT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY users_email_unique (email),
  CONSTRAINT users_team_fk
    FOREIGN KEY (team_id) REFERENCES teams (id),
  CONSTRAINT users_manager_fk
    FOREIGN KEY (manager_id) REFERENCES users (id)
) ENGINE=InnoDB;

ALTER TABLE teams
  ADD CONSTRAINT teams_owner_user_fk
  FOREIGN KEY (owner_user_id) REFERENCES users (id);


CREATE TABLE addresses (
  id INT NOT NULL AUTO_INCREMENT,
  user_id INT NOT NULL,
  label VARCHAR(64) NOT NULL,
  street VARCHAR(255) NOT NULL,
  city VARCHAR(128) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id),
  CONSTRAINT addresses_user_fk
    FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB;


CREATE TABLE products (
  id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(128) NOT NULL,
  price DECIMAL(12, 2) NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by INT NULL,
  PRIMARY KEY (id),
  CONSTRAINT products_created_by_fk
    FOREIGN KEY (created_by) REFERENCES users (id)
) ENGINE=InnoDB;


CREATE TABLE categories (
  id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(128) NOT NULL,
  parent_id INT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY categories_name_unique (name),
  CONSTRAINT categories_parent_fk
    FOREIGN KEY (parent_id) REFERENCES categories (id)
) ENGINE=InnoDB;


-- Many-to-many: products ⇄ categories
CREATE TABLE product_categories (
  product_id INT NOT NULL,
  category_id INT NOT NULL,
  PRIMARY KEY (product_id, category_id),
  CONSTRAINT product_categories_product_fk
    FOREIGN KEY (product_id) REFERENCES products (id),
  CONSTRAINT product_categories_category_fk
    FOREIGN KEY (category_id) REFERENCES categories (id)
) ENGINE=InnoDB;


CREATE TABLE orders (
  id INT NOT NULL AUTO_INCREMENT,
  user_id INT NOT NULL,
  product_id INT NOT NULL,
  shipping_address_id INT NULL,
  quantity INT NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT orders_user_fk
    FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT orders_product_fk
    FOREIGN KEY (product_id) REFERENCES products (id),
  CONSTRAINT orders_shipping_address_fk
    FOREIGN KEY (shipping_address_id) REFERENCES addresses (id)
) ENGINE=InnoDB;


CREATE TABLE order_items (
  id INT NOT NULL AUTO_INCREMENT,
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  unit_price DECIMAL(12, 2) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT order_items_order_fk
    FOREIGN KEY (order_id) REFERENCES orders (id),
  CONSTRAINT order_items_product_fk
    FOREIGN KEY (product_id) REFERENCES products (id)
) ENGINE=InnoDB;


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
  (1, 'Ada',    'ada@example.com',    1, NULL),
  (2, 'Grace',  'grace@example.com',  1, 1),
  (3, 'Linus',  'linus@example.com',  2, NULL),
  (4, 'Dennis', 'dennis@example.com', 2, 3),
  (5, 'Ken',    'ken@example.com',    3, 1),
  (6, 'Rob',    'rob@example.com',    NULL, NULL);


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
  (1, 1, 'Home',   '1 Main Street',    'Phnom Penh', TRUE),
  (2, 1, 'Office', '10 Tech Street',   'Phnom Penh', FALSE),
  (3, 2, 'Home',   '20 River Road',    'Phnom Penh', TRUE),
  (4, 3, 'Home',   '30 Mountain Road', 'Sen Monorom', TRUE);


INSERT INTO products
  (id, name, price, active, created_by)
VALUES
  (1, 'Widget',  9.99,  TRUE,  1),
  (2, 'Gadget',  19.50, TRUE,  2),
  (3, 'Cable',   4.25,  TRUE,  3),
  (4, 'Adapter', 14.00, TRUE,  NULL),
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
  (id, user_id, product_id, shipping_address_id, quantity, created_at)
VALUES
  (1, 1, 1, 1, 2, '2026-09-10 10:00:00'),
  (2, 2, 2, 3, 1, '2026-09-11 11:30:00'),
  (3, 3, 3, 4, 5, '2026-09-12 14:15:00'),
  (4, 1, 4, 2, 1, '2026-09-13 09:45:00'),
  (5, 6, 5, NULL, 1, '2026-09-14 16:20:00');


INSERT INTO order_items
  (id, order_id, product_id, quantity, unit_price)
VALUES
  (1, 1, 1, 2, 9.99),
  (2, 1, 3, 1, 4.25),
  (3, 2, 2, 1, 19.50),
  (4, 3, 3, 5, 4.25),
  (5, 4, 4, 1, 14.00),
  (6, 5, 5, 1, 99.99);


-- Keep AUTO_INCREMENT values sane after explicit IDs.
ALTER TABLE teams AUTO_INCREMENT = 4;
ALTER TABLE users AUTO_INCREMENT = 7;
ALTER TABLE addresses AUTO_INCREMENT = 5;
ALTER TABLE products AUTO_INCREMENT = 6;
ALTER TABLE categories AUTO_INCREMENT = 6;
ALTER TABLE orders AUTO_INCREMENT = 6;
ALTER TABLE order_items AUTO_INCREMENT = 7;
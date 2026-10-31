-- M4-B: Discovery fixture — view, trigger, procedure/function skipped (no translation required).
-- Single-statement routine bodies so non-interactive mysql client needs no DELIMITER.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS order_inventory_v;
DROP TRIGGER IF EXISTS orders_audit_bi;
DROP PROCEDURE IF EXISTS restock_item;
DROP FUNCTION IF EXISTS inventory_on_hand;
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS order_lines;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS inventory;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE inventory (
  sku           VARCHAR(32) NOT NULL PRIMARY KEY,
  title         VARCHAR(128) NOT NULL,
  qty_on_hand   INT NOT NULL DEFAULT 0,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE orders (
  id            INT UNSIGNED NOT NULL PRIMARY KEY,
  customer      VARCHAR(64) NOT NULL,
  placed_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE order_lines (
  id            INT UNSIGNED NOT NULL PRIMARY KEY,
  order_id      INT UNSIGNED NOT NULL,
  sku           VARCHAR(32) NOT NULL,
  qty           INT NOT NULL,
  CONSTRAINT order_lines_order_fk FOREIGN KEY (order_id) REFERENCES orders (id),
  CONSTRAINT order_lines_sku_fk FOREIGN KEY (sku) REFERENCES inventory (sku)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE audit_log (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_id      INT UNSIGNED NOT NULL,
  action        VARCHAR(32) NOT NULL,
  noted_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO inventory (sku, title, qty_on_hand) VALUES
  ('SKU-1', 'Widget', 10),
  ('SKU-2', 'Gadget', 4);

INSERT INTO orders (id, customer, placed_at) VALUES
  (1, 'ada', '2024-01-02 10:00:00'),
  (2, 'bob', '2024-01-03 11:00:00');

INSERT INTO order_lines (id, order_id, sku, qty) VALUES
  (1, 1, 'SKU-1', 2),
  (2, 1, 'SKU-2', 1),
  (3, 2, 'SKU-1', 1);

CREATE FUNCTION inventory_on_hand(p_sku VARCHAR(32))
RETURNS INT
READS SQL DATA
DETERMINISTIC
RETURN (SELECT IFNULL(qty_on_hand, 0) FROM inventory WHERE sku = p_sku LIMIT 1);

CREATE PROCEDURE restock_item(IN p_sku VARCHAR(32), IN p_qty INT)
UPDATE inventory SET qty_on_hand = qty_on_hand + p_qty WHERE sku = p_sku;

CREATE TRIGGER orders_audit_bi
BEFORE INSERT ON orders
FOR EACH ROW
INSERT INTO audit_log (order_id, action) VALUES (NEW.id, 'insert');

-- Calls inventory_on_hand so plan skips the view with the routines/views warnings.
CREATE VIEW order_inventory_v AS
SELECT o.id AS order_id, o.customer, ol.sku, ol.qty, inventory_on_hand(ol.sku) AS qty_on_hand
FROM orders o
JOIN order_lines ol ON ol.order_id = o.id;

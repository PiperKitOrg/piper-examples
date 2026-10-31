-- M4-B: Discovery fixture — view, trigger, function skipped (no translation required).

DROP VIEW IF EXISTS order_inventory_v CASCADE;
DROP TRIGGER IF EXISTS orders_audit_bi ON orders;
DROP FUNCTION IF EXISTS orders_audit_bi_fn();
DROP FUNCTION IF EXISTS inventory_on_hand(text);
DROP FUNCTION IF EXISTS restock_item(text, integer);
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS order_lines CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;

CREATE TABLE inventory (
  sku           TEXT PRIMARY KEY,
  title         TEXT NOT NULL,
  qty_on_hand   INTEGER NOT NULL DEFAULT 0,
  updated_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE orders (
  id            INTEGER PRIMARY KEY,
  customer      TEXT NOT NULL,
  placed_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE order_lines (
  id            INTEGER PRIMARY KEY,
  order_id      INTEGER NOT NULL REFERENCES orders (id),
  sku           TEXT NOT NULL REFERENCES inventory (sku),
  qty           INTEGER NOT NULL
);

CREATE TABLE audit_log (
  id            SERIAL PRIMARY KEY,
  order_id      INTEGER NOT NULL,
  action        TEXT NOT NULL,
  noted_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

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

CREATE OR REPLACE FUNCTION inventory_on_hand(p_sku TEXT)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(qty_on_hand, 0) FROM inventory WHERE sku = p_sku;
$$;

CREATE OR REPLACE FUNCTION restock_item(p_sku TEXT, p_qty INTEGER)
RETURNS VOID
LANGUAGE sql
AS $$
  UPDATE inventory SET qty_on_hand = qty_on_hand + p_qty WHERE sku = p_sku;
$$;

CREATE OR REPLACE FUNCTION orders_audit_bi_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO audit_log (order_id, action) VALUES (NEW.id, 'insert');
  RETURN NEW;
END;
$$;

CREATE TRIGGER orders_audit_bi
BEFORE INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION orders_audit_bi_fn();

-- Calls inventory_on_hand so plan skips the view with the routines/views warnings.
CREATE VIEW order_inventory_v AS
SELECT o.id AS order_id, o.customer, ol.sku, ol.qty, inventory_on_hand(ol.sku) AS qty_on_hand
FROM orders o
JOIN order_lines ol ON ol.order_id = o.id;

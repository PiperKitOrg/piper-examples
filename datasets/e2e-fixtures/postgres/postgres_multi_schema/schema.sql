-- M4-E: Two non-public schemas with the same table name + cross-schema FK from public.
-- Piper inspects only the connected schema (public) and must warn about the others.

DROP TABLE IF EXISTS public.shipments CASCADE;
DROP TABLE IF EXISTS catalog.items CASCADE;
DROP TABLE IF EXISTS fulfillment.items CASCADE;
DROP SCHEMA IF EXISTS catalog CASCADE;
DROP SCHEMA IF EXISTS fulfillment CASCADE;

CREATE SCHEMA catalog;
CREATE SCHEMA fulfillment;

CREATE TABLE catalog.items (
  id            INTEGER PRIMARY KEY,
  sku           TEXT NOT NULL UNIQUE,
  title         TEXT NOT NULL
);

CREATE TABLE fulfillment.items (
  id            INTEGER PRIMARY KEY,
  sku           TEXT NOT NULL UNIQUE,
  warehouse     TEXT NOT NULL
);

CREATE TABLE public.shipments (
  id            INTEGER PRIMARY KEY,
  catalog_item_id INTEGER NOT NULL REFERENCES catalog.items (id),
  qty           INTEGER NOT NULL,
  shipped_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO catalog.items (id, sku, title) VALUES
  (1, 'SKU-1', 'Widget'),
  (2, 'SKU-2', 'Gadget');

INSERT INTO fulfillment.items (id, sku, warehouse) VALUES
  (1, 'SKU-1', 'phnom-penh'),
  (2, 'SKU-2', 'siem-reap');

INSERT INTO public.shipments (id, catalog_item_id, qty, shipped_at) VALUES
  (1, 1, 2, '2024-01-02 10:00:00'),
  (2, 2, 1, '2024-01-03 11:00:00');

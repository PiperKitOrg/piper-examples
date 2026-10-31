-- M4-D: MySQL RANGE/LIST partitions, generated column, functional + invisible indexes, composite key.
-- PK includes every partition column (MySQL requirement).

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS order_events;
DROP TABLE IF EXISTS catalog_items;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE catalog_items (
  shop_id         INT UNSIGNED NOT NULL,
  sku             VARCHAR(32) NOT NULL,
  category        VARCHAR(32) NOT NULL,
  title           VARCHAR(128) NOT NULL,
  price_cents     INT NOT NULL,
  title_lower     VARCHAR(128)
    GENERATED ALWAYS AS (LOWER(title)) STORED,
  PRIMARY KEY (shop_id, sku, category),
  KEY catalog_items_category_idx (category),
  KEY catalog_items_title_lower_idx ((LOWER(title))),
  KEY catalog_items_price_invisible_idx (price_cents) INVISIBLE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
PARTITION BY LIST COLUMNS(category) (
  PARTITION p_apparel VALUES IN ('apparel'),
  PARTITION p_home VALUES IN ('home'),
  PARTITION p_other VALUES IN ('other')
);

CREATE TABLE order_events (
  event_id        BIGINT UNSIGNED NOT NULL,
  event_day       DATE NOT NULL,
  shop_id         INT UNSIGNED NOT NULL,
  sku             VARCHAR(32) NOT NULL,
  qty             INT NOT NULL,
  PRIMARY KEY (event_id, event_day),
  KEY order_events_shop_sku_idx (shop_id, sku)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
PARTITION BY RANGE COLUMNS(event_day) (
  PARTITION p2023 VALUES LESS THAN ('2024-01-01'),
  PARTITION p2024 VALUES LESS THAN ('2025-01-01'),
  PARTITION pmax VALUES LESS THAN (MAXVALUE)
);

INSERT INTO catalog_items (shop_id, sku, category, title, price_cents) VALUES
  (1, 'SKU-1', 'apparel', 'Blue Shirt', 1999),
  (1, 'SKU-2', 'home', 'Mug', 899),
  (2, 'SKU-3', 'other', 'Cable', 499);

INSERT INTO order_events (event_id, event_day, shop_id, sku, qty) VALUES
  (1, '2023-06-01', 1, 'SKU-1', 2),
  (2, '2024-02-15', 1, 'SKU-2', 1),
  (3, '2025-01-10', 2, 'SKU-3', 4);

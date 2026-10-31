DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS empty_box;

CREATE TABLE items (
  id          INT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  note        VARCHAR(255) NULL,
  qty         INT NOT NULL DEFAULT 0,
  price       DECIMAL(12, 2) NOT NULL,
  active      TINYINT(1) NOT NULL DEFAULT 1,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY items_name_uidx (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE empty_box (
  id INT PRIMARY KEY,
  label VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO items (id, name, note, qty, price, active, created_at) VALUES
  (1, 'alpha', NULL, 3, 10.50, 1, '2024-01-01 00:00:00'),
  (2, 'beta', 'unicode café', 0, 0.01, 0, '2024-06-15 12:30:00'),
  (3, 'gamma', 'line1', 100, 9999.99, 1, '2025-01-01 08:00:00');

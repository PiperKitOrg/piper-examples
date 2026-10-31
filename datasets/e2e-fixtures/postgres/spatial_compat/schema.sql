-- M4-F: Postgres built-in geometric types (no PostGIS extension required).
-- Emulate/warn toward MySQL; not the MySQL spatial path.

DROP TABLE IF EXISTS places CASCADE;

CREATE TABLE places (
  id        INTEGER PRIMARY KEY,
  label     TEXT NOT NULL,
  pt        POINT NOT NULL,
  box_area  BOX NOT NULL
);

INSERT INTO places (id, label, pt, box_area) VALUES
  (1, 'origin', '(104.9165,11.5564)', '((104.9,11.5),(105.0,11.6))'),
  (2, 'offset', '(103.85,13.36)', '((103.8,13.3),(103.9,13.4))');

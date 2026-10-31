-- M4-F: Small MySQL geometry (no PostGIS). Explicit GeoJSON/binary warn OK.

SET NAMES utf8mb4;

DROP TABLE IF EXISTS places;

CREATE TABLE places (
  id        INT UNSIGNED NOT NULL PRIMARY KEY,
  label     VARCHAR(64) NOT NULL,
  pt        POINT NOT NULL SRID 4326,
  shape     GEOMETRY NOT NULL,
  SPATIAL INDEX places_shape_idx (shape)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- MySQL SRID 4326 axis order is lat/lon for POINT.
INSERT INTO places (id, label, pt, shape) VALUES
(
  1, 'origin',
  ST_GeomFromText('POINT(11.5564 104.9165)', 4326),
  ST_GeomFromText('POINT(104.9165 11.5564)')
),
(
  2, 'line',
  ST_GeomFromText('POINT(13.36 103.85)', 4326),
  ST_GeomFromText('LINESTRING(104.9 11.5, 103.8 13.3)')
);

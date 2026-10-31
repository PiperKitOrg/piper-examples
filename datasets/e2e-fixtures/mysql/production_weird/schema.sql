-- Production-weird MySQL kitchen sink: Gap A type fidelity stress.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS weird_docs;
DROP TABLE IF EXISTS weird_geo;
DROP TABLE IF EXISTS weird_keys;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE weird_keys (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug            VARCHAR(64) NOT NULL,
  tiny_u          TINYINT UNSIGNED NOT NULL,
  small_u         SMALLINT UNSIGNED NOT NULL,
  int_u           INT UNSIGNED NOT NULL,
  big_u           BIGINT UNSIGNED NOT NULL,
  bit_flag        BIT(1) NOT NULL DEFAULT b'1',
  bit_mask        BIT(8) NOT NULL,
  mood            ENUM('plain','a,b','it''s') NOT NULL,
  flags           SET('plain','it''s','x-y') NOT NULL,
  birth_year      YEAR NOT NULL,
  duration        TIME(3) NOT NULL,
  oversize_time   TIME NOT NULL,
  price           DECIMAL(12, 4) NOT NULL,
  note            VARCHAR(255) NULL,
  blob_payload    VARBINARY(32) NOT NULL,
  long_key        VARCHAR(191) NOT NULL,
  touched_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_at      DATETIME(3) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY weird_keys_slug_uidx (slug),
  KEY weird_keys_long_key_idx (long_key),
  FULLTEXT KEY weird_keys_note_ft (note)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE weird_geo (
  id        INT UNSIGNED NOT NULL PRIMARY KEY,
  label     VARCHAR(64) NOT NULL,
  pt        POINT NOT NULL SRID 4326,
  shape     GEOMETRY NOT NULL,
  SPATIAL INDEX weird_geo_shape_idx (shape)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE weird_docs (
  doc_id    INT UNSIGNED NOT NULL PRIMARY KEY,
  key_id    BIGINT UNSIGNED NOT NULL,
  title     VARCHAR(128) NOT NULL,
  body      TEXT,
  zero_width VARCHAR(32) NOT NULL,
  CONSTRAINT weird_docs_key_fk FOREIGN KEY (key_id) REFERENCES weird_keys (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO weird_keys (
  id, slug, tiny_u, small_u, int_u, big_u, bit_flag, bit_mask, mood, flags,
  birth_year, duration, oversize_time, price, note, blob_payload, long_key, created_at
) VALUES
(
  1, 'alpha', 255, 65535, 4294967295, 18446744073709551615, b'1', b'10101010',
  'a,b', 'plain,it''s', 1999, '-13:14:50.123', '517:51:04',
  12345678.9012, 'unicode café', X'DEADBEEF',
  REPEAT('x', 191), '2024-01-02 03:04:05.678'
),
(
  2, 'beta', 0, 0, 0, 0, b'0', b'00000001',
  'it''s', 'x-y', 1901, '00:00:00.000', '23:59:59',
  0.0001, NULL, X'00',
  CONCAT('y', REPEAT('z', 190)), '1970-01-01 00:00:01.000'
);

INSERT INTO weird_geo (id, label, pt, shape) VALUES
(
  1, 'origin',
  ST_GeomFromText('POINT(0 0)', 4326),
  ST_GeomFromText('POINT(0 0)')
),
(
  2, 'offset',
  ST_GeomFromText('POINT(8 19)', 4326),
  ST_GeomFromText('LINESTRING(30 10, 10 30, 40 40)')
);

INSERT INTO weird_docs (doc_id, key_id, title, body, zero_width) VALUES
  (1, 1, 'Hello', 'café', CONCAT('a', UNHEX('E2808B'), 'b')),
  (2, 2, 'NULL-ish', 'null', 'N/A');

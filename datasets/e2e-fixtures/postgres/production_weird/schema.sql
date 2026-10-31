-- Production-weird Postgres kitchen sink: Gap A type fidelity stress.
-- Intentionally small row counts; each column class maps to a known Piper risk.

DROP TABLE IF EXISTS weird_docs CASCADE;
DROP TABLE IF EXISTS weird_geo CASCADE;
DROP TABLE IF EXISTS weird_keys CASCADE;
DROP TYPE IF EXISTS weird_mood CASCADE;

CREATE TYPE weird_mood AS ENUM ('ok', 'meh', 'a,b', 'it''s fine');

CREATE TABLE weird_keys (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug            TEXT NOT NULL,
  mood            weird_mood NOT NULL DEFAULT 'ok',
  tags            TEXT[] NOT NULL DEFAULT '{}',
  scores          INTEGER[] NOT NULL DEFAULT '{}',
  meta_json       JSON NOT NULL DEFAULT '{}',
  meta_jsonb      JSONB NOT NULL DEFAULT '{}',
  blob_payload    BYTEA NOT NULL,
  net_host        INET,
  net_block       CIDR,
  salary_band     INT4RANGE,
  created_plain   TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  created_tz      TIMESTAMPTZ NOT NULL,
  huge_num        NUMERIC(50, 10) NOT NULL,
  length_hours    NUMERIC(6, 2) GENERATED ALWAYS AS (round((scores[1]::numeric) / 60.0, 2)) STORED
);

CREATE UNIQUE INDEX weird_keys_slug_uidx ON weird_keys (slug);
CREATE INDEX weird_keys_meta_gin ON weird_keys USING gin (meta_jsonb);

CREATE TABLE weird_geo (
  id        INTEGER PRIMARY KEY,
  label     TEXT NOT NULL,
  pt        POINT NOT NULL,
  box_area  BOX NOT NULL
);

CREATE TABLE weird_docs (
  doc_id    INTEGER PRIMARY KEY,
  key_id    UUID REFERENCES weird_keys (id),
  title     TEXT NOT NULL,
  body      TEXT,
  zero_width TEXT NOT NULL DEFAULT E'a\u200Bb'
);

INSERT INTO weird_keys (
  id, slug, mood, tags, scores, meta_json, meta_jsonb, blob_payload,
  net_host, net_block, salary_band, created_plain, created_tz, huge_num
) VALUES
(
  '11111111-1111-1111-1111-111111111111',
  'alpha',
  'a,b',
  ARRAY['office', 'naïve', E'zw\u200Bsp'],
  ARRAY[120, 45],
  '{"color":"blue","n":1}',
  '{"nested":{"ok":true},"arr":[1,2]}',
  E'\\xDEADBEEF',
  '192.168.1.10',
  '10.0.0.0/8',
  '[50000,90000)',
  '2024-01-02 03:04:05',
  '2024-01-02 03:04:05+00',
  123456789012345678901234567890.1234567890
),
(
  '22222222-2222-2222-2222-222222222222',
  'beta',
  'it''s fine',
  ARRAY['emoji-✅'],
  ARRAY[0],
  '[]',
  '{"empty":null}',
  E'\\x00',
  NULL,
  NULL,
  NULL,
  '1970-01-01 00:00:01',
  '1970-01-01 00:00:01+00',
  0.0000000001
);

INSERT INTO weird_geo (id, label, pt, box_area) VALUES
  (1, 'origin', '(0,0)', '((0,0),(1,1))'),
  (2, 'offset', '(8,19)', '((8,19),(10,30))');

INSERT INTO weird_docs (doc_id, key_id, title, body, zero_width) VALUES
  (1, '11111111-1111-1111-1111-111111111111', 'Hello', 'café', E'a\u200Bb'),
  (2, '22222222-2222-2222-2222-222222222222', 'NULL-ish', 'null', 'N/A');

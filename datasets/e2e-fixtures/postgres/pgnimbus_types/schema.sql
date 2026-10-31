-- Slim type-rich Postgres fixture adapted from the pgNimbus demo seed
-- (https://github.com/Shman4ik/pgNimbus scripts/demo, MIT).
-- Keeps the Gap A type surface (hstore, citext domain, composite, money,
-- ltree+GiST, macaddr, bit/varbit, ranges, partitions) with tiny row counts.
-- pgvector is intentionally omitted (alpine harness has no vector extension).

CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS ltree;

DROP TABLE IF EXISTS readings CASCADE;
DROP TABLE IF EXISTS devices CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS units CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TYPE IF EXISTS address CASCADE;
DROP TYPE IF EXISTS product_category CASCADE;
DROP TYPE IF EXISTS device_status CASCADE;
DROP DOMAIN IF EXISTS email_addr CASCADE;

CREATE TYPE product_category AS ENUM (
  'electronics','home','apparel','books','toys','grocery','sports','beauty','automotive'
);
CREATE TYPE device_status AS ENUM (
  'online','offline','maintenance','error','provisioning'
);
CREATE TYPE address AS (
  street  text,
  city    text,
  region  text,
  postal  text,
  country char(2)
);
CREATE DOMAIN email_addr AS citext
  CHECK (VALUE ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$');

CREATE TABLE customers (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email          email_addr UNIQUE NOT NULL,
  first_name     text NOT NULL,
  last_name      text NOT NULL,
  full_name      text GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
  shipping       address,
  tags           text[] NOT NULL DEFAULT '{}',
  interests      jsonb NOT NULL DEFAULT '{}'::jsonb,
  attrs          hstore,
  loyalty_tier   smallint NOT NULL DEFAULT 0 CHECK (loyalty_tier BETWEEN 0 AND 5),
  signup_at      timestamptz NOT NULL DEFAULT now(),
  last_login_ip  inet,
  home_network   cidr,
  home_location  point,
  membership     daterange,
  avatar_thumb   bytea,
  search         tsvector GENERATED ALWAYS AS
                   (to_tsvector('simple', first_name || ' ' || last_name || ' ' || email)) STORED
);

CREATE TABLE products (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sku             citext UNIQUE NOT NULL,
  name            text NOT NULL,
  category        product_category NOT NULL,
  price           numeric(12,2) NOT NULL CHECK (price > 0),
  cost            money NOT NULL,
  attributes      jsonb NOT NULL DEFAULT '{}'::jsonb,
  dimensions_cm   box,
  tags            text[] NOT NULL DEFAULT '{}',
  rating          numeric(2,1) CHECK (rating BETWEEN 0 AND 5),
  weight_grams    integer,
  in_stock        boolean NOT NULL DEFAULT true,
  lead_time       interval,
  price_band      numrange,
  added_at        timestamptz NOT NULL DEFAULT now(),
  search          tsvector GENERATED ALWAYS AS (to_tsvector('english', name)) STORED
);

CREATE INDEX products_search_gin ON products USING gin (search);
CREATE INDEX products_name_trgm ON products USING gin (name gin_trgm_ops);

CREATE TABLE units (
  id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  path        ltree UNIQUE NOT NULL,
  name        text NOT NULL,
  headcount   integer NOT NULL DEFAULT 0,
  budget      money,
  cost_center text
);

CREATE INDEX units_path_gist ON units USING gist (path);

CREATE TABLE employees (
  id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  unit_id     integer NOT NULL REFERENCES units(id),
  manager_id  integer REFERENCES employees(id) ON DELETE SET NULL,
  name        text NOT NULL,
  title       text NOT NULL,
  email       citext UNIQUE NOT NULL,
  salary_band int4range NOT NULL,
  salary      money NOT NULL,
  skills      text[] NOT NULL DEFAULT '{}',
  hired_on    date NOT NULL,
  profile     jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_manager  boolean NOT NULL DEFAULT false
);

CREATE TABLE devices (
  id           integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  serial       uuid NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  name         text NOT NULL,
  mac          macaddr UNIQUE NOT NULL,
  ip           inet,
  subnet       cidr,
  firmware     bit(16),
  flags        bit(8),
  location     point,
  coverage     polygon,
  config       jsonb NOT NULL DEFAULT '{}'::jsonb,
  status       device_status NOT NULL DEFAULT 'provisioning',
  battery_pct  numeric(5,2) CHECK (battery_pct BETWEEN 0 AND 100),
  uptime       interval,
  installed_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE readings (
  id          bigint GENERATED ALWAYS AS IDENTITY,
  device_id   integer NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  recorded_at timestamptz NOT NULL,
  metric      text NOT NULL,
  value       double precision NOT NULL,
  unit        text,
  quality     smallint CHECK (quality BETWEEN 0 AND 100),
  flags       bit(8),
  payload     jsonb,
  PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

CREATE TABLE readings_2026_01 PARTITION OF readings
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE readings_2026_02 PARTITION OF readings
  FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE readings_default PARTITION OF readings DEFAULT;

INSERT INTO customers (
  id, email, first_name, last_name, shipping, tags, interests, attrs,
  loyalty_tier, signup_at, last_login_ip, home_network, home_location,
  membership, avatar_thumb
) VALUES
(
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'ada@shop.example', 'Ada', 'Lovelace',
  ROW('1 Analytical Way', 'London', 'ENG', 'EC1A', 'GB')::address,
  ARRAY['vip','newsletter'],
  '{"theme":"dark","currency":"GBP"}'::jsonb,
  'referrer=>friend,lang=>en',
  5, '2024-01-02 03:04:05+00',
  '192.168.1.10', '10.0.0.0/8', point(-0.12, 51.5),
  '[2024-01-01,2026-01-01)', decode('deadbeef', 'hex')
),
(
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'grace@shop.example', 'Grace', 'Hopper',
  ROW('2 Cobol Lane', 'New York', 'NY', '10001', 'US')::address,
  ARRAY['beta'],
  '{"theme":"light","currency":"USD"}'::jsonb,
  'referrer=>organic,lang=>en',
  3, '2023-06-15 12:00:00+00',
  '10.1.2.3', '10.1.0.0/16', point(-74.0, 40.7),
  '[2023-01-01,)', decode('00', 'hex')
);

INSERT INTO products (
  sku, name, category, price, cost, attributes, dimensions_cm, tags,
  rating, weight_grams, in_stock, lead_time, price_band, added_at
) VALUES
(
  'PRD-000001', 'Premium Mouse', 'electronics', 49.99, 12.50::money,
  '{"color":"black","wireless":true}'::jsonb,
  box(point(0,0), point(10,4)),
  ARRAY['peripheral','usb'],
  4.5, 120, true, '2 days'::interval, numrange(40, 60), '2024-02-01 00:00:00+00'
),
(
  'PRD-000002', 'Eco Notebook', 'books', 9.50, 2.00::money,
  '{"pages":192}'::jsonb,
  box(point(0,0), point(21,14)),
  ARRAY['stationery'],
  4.0, 350, true, '1 day'::interval, numrange(5, 15), '2024-03-01 00:00:00+00'
);

INSERT INTO units (path, name, headcount, budget, cost_center) VALUES
  ('company', 'Acme Corp', 0, 25000000::money, 'CC-000'),
  ('company.engineering', 'Engineering', 0, 9000000::money, 'CC-100'),
  ('company.engineering.platform', 'Platform', 3, 3200000::money, 'CC-110');

INSERT INTO employees (
  unit_id, manager_id, name, title, email, salary_band, salary, skills, hired_on, profile, is_manager
) VALUES
(
  3, NULL, 'Alex Lee', 'Platform Lead', 'lead.platform@acme.example',
  int4range(120000, 180000), 150000::money, ARRAY['leadership','postgres'],
  '2019-04-01', '{"level":"M","remote":true}'::jsonb, true
),
(
  3, 1, 'Sam Park', 'Engineer', 'sam.park@acme.example',
  int4range(90000, 130000), 110000::money, ARRAY['go','sql'],
  '2021-08-15', '{"level":"IC","remote":false}'::jsonb, false
);

INSERT INTO devices (
  name, mac, ip, subnet, firmware, flags, location, coverage, config,
  status, battery_pct, uptime, installed_at
) VALUES
(
  'Sensor-0001', '08:00:2b:01:02:03', '172.16.1.10', '172.16.1.0/24',
  B'1010101010101010', B'10101010', point(1.5, 2.5),
  polygon(box(point(0,0), point(5,5))),
  '{"model":"ESP32","sample_rate_hz":10}'::jsonb,
  'online', 87.5, '120 hours'::interval, '2025-12-01 00:00:00+00'
),
(
  'Gateway-0002', '08:00:2b:aa:bb:cc', '172.16.2.1', '172.16.2.0/24',
  B'0000111100001111', B'00000001', point(8, 19),
  polygon(box(point(8,19), point(12,25))),
  '{"model":"RPi4","sample_rate_hz":1}'::jsonb,
  'maintenance', 42.0, '10 hours'::interval, '2025-11-15 00:00:00+00'
);

INSERT INTO readings (device_id, recorded_at, metric, value, unit, quality, flags, payload) VALUES
  (1, '2026-01-15 10:00:00+00', 'temperature', 21.5, '°C', 98, B'00000001', '{"raw":512}'::jsonb),
  (1, '2026-01-15 11:00:00+00', 'humidity', 44.0, '%', 97, B'00000000', NULL),
  (2, '2026-02-01 09:00:00+00', 'voltage', 5.1, 'V', 99, B'00000010', '{"calibrated":true}'::jsonb),
  (2, '2025-12-01 00:00:00+00', 'temperature', -3.2, '°C', 80, B'11111111', '{"raw":1}'::jsonb);

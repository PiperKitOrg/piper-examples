DROP TABLE IF EXISTS batch_rows CASCADE;

CREATE TABLE batch_rows (
  id INTEGER PRIMARY KEY,
  payload TEXT NOT NULL
);

INSERT INTO batch_rows (id, payload)
SELECT g, 'row-' || g
FROM generate_series(1, 500) AS g;

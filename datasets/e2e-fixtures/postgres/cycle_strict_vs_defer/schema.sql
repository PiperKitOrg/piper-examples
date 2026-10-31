DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS authors CASCADE;

CREATE TABLE authors (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  favorite_book_id INTEGER NULL
);

CREATE TABLE books (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  author_id INTEGER NOT NULL REFERENCES authors(id)
);

ALTER TABLE authors
  ADD CONSTRAINT authors_favorite_book_fk
  FOREIGN KEY (favorite_book_id) REFERENCES books(id);

INSERT INTO authors (id, name, favorite_book_id) VALUES (1, 'Ada', NULL);
INSERT INTO books (id, title, author_id) VALUES (10, 'Notes', 1);
UPDATE authors SET favorite_book_id = 10 WHERE id = 1;

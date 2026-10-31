SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS authors;
SET FOREIGN_KEY_CHECKS=1;

CREATE TABLE authors (
  id INT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  favorite_book_id INT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE books (
  id INT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  author_id INT NOT NULL,
  CONSTRAINT books_author_fk FOREIGN KEY (author_id) REFERENCES authors(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE authors
  ADD CONSTRAINT authors_favorite_book_fk
  FOREIGN KEY (favorite_book_id) REFERENCES books(id);

INSERT INTO authors (id, name, favorite_book_id) VALUES (1, 'Ada', NULL);
INSERT INTO books (id, title, author_id) VALUES (10, 'Notes', 1);
UPDATE authors SET favorite_book_id = 10 WHERE id = 1;

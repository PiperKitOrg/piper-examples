-- M4-A: MySQL collation / charset uniqueness edges for cross-dialect plan warnings.
-- CI unique, Turkish I, CHAR pad/trailing spaces. Tiny deterministic rows.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS login_aliases;
DROP TABLE IF EXISTS accounts;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE accounts (
  id            INT UNSIGNED NOT NULL PRIMARY KEY,
  email         VARCHAR(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  handle        VARCHAR(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_turkish_ci NOT NULL,
  label_pad     CHAR(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  note          VARCHAR(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NULL,
  UNIQUE KEY accounts_email_uidx (email),
  UNIQUE KEY accounts_handle_uidx (handle),
  UNIQUE KEY accounts_label_pad_uidx (label_pad)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE login_aliases (
  id            INT UNSIGNED NOT NULL PRIMARY KEY,
  account_id    INT UNSIGNED NOT NULL,
  alias_name    VARCHAR(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  UNIQUE KEY login_aliases_alias_uidx (alias_name),
  CONSTRAINT login_aliases_account_fk FOREIGN KEY (account_id) REFERENCES accounts (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO accounts (id, email, handle, label_pad, note) VALUES
  (1, 'Ada@Example.com', 'Istanbul', 'alpha   ', 'ci email'),
  (2, 'bob@example.com', 'ankara', 'beta', 'turkish handle + pad CHAR');

INSERT INTO login_aliases (id, account_id, alias_name) VALUES
  (1, 1, 'Ada'),
  (2, 2, 'bob ');

SET FOREIGN_KEY_CHECKS = 0;

SET @tables = NULL;

SELECT GROUP_CONCAT(CONCAT('`', table_name, '`'))
INTO @tables
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_type = 'BASE TABLE';

SET @sql = IFNULL(CONCAT('DROP TABLE ', @tables), 'SELECT 1');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET FOREIGN_KEY_CHECKS = 1;
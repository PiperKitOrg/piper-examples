SELECT
    kcu.CONSTRAINT_NAME AS constraint_name,

    kcu.TABLE_SCHEMA AS source_schema,
    kcu.TABLE_NAME AS source_table,

    GROUP_CONCAT(
        kcu.COLUMN_NAME
        ORDER BY kcu.ORDINAL_POSITION
        SEPARATOR ','
    ) AS source_columns,

    kcu.REFERENCED_TABLE_SCHEMA AS target_schema,
    kcu.REFERENCED_TABLE_NAME AS target_table,

    GROUP_CONCAT(
        kcu.REFERENCED_COLUMN_NAME
        ORDER BY kcu.ORDINAL_POSITION
        SEPARATOR ','
    ) AS target_columns,

    rc.UPDATE_RULE AS on_update,
    rc.DELETE_RULE AS on_delete

FROM information_schema.KEY_COLUMN_USAGE kcu

JOIN information_schema.REFERENTIAL_CONSTRAINTS rc
    ON rc.CONSTRAINT_SCHEMA = kcu.CONSTRAINT_SCHEMA
    AND rc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
    AND rc.TABLE_NAME = kcu.TABLE_NAME

WHERE kcu.REFERENCED_TABLE_NAME IS NOT NULL
  AND kcu.TABLE_SCHEMA NOT IN (
      'information_schema',
      'mysql',
      'performance_schema',
      'sys'
  )

GROUP BY
    kcu.CONSTRAINT_NAME,
    kcu.TABLE_SCHEMA,
    kcu.TABLE_NAME,
    kcu.REFERENCED_TABLE_SCHEMA,
    kcu.REFERENCED_TABLE_NAME,
    rc.UPDATE_RULE,
    rc.DELETE_RULE

ORDER BY
    kcu.TABLE_SCHEMA,
    kcu.TABLE_NAME,
    kcu.CONSTRAINT_NAME;
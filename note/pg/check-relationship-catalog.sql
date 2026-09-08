SELECT
    con.conname AS constraint_name,

    src_ns.nspname AS source_schema,
    src.relname AS source_table,

    ARRAY(
        SELECT src_att.attname
        FROM unnest(con.conkey) WITH ORDINALITY AS cols(attnum, ord)
        JOIN pg_attribute src_att
          ON src_att.attrelid = con.conrelid
         AND src_att.attnum = cols.attnum
        ORDER BY cols.ord
    ) AS source_columns,

    dst_ns.nspname AS target_schema,
    dst.relname AS target_table,

    ARRAY(
        SELECT dst_att.attname
        FROM unnest(con.confkey) WITH ORDINALITY AS cols(attnum, ord)
        JOIN pg_attribute dst_att
          ON dst_att.attrelid = con.confrelid
         AND dst_att.attnum = cols.attnum
        ORDER BY cols.ord
    ) AS target_columns,

    CASE con.confupdtype
        WHEN 'a' THEN 'NO ACTION'
        WHEN 'r' THEN 'RESTRICT'
        WHEN 'c' THEN 'CASCADE'
        WHEN 'n' THEN 'SET NULL'
        WHEN 'd' THEN 'SET DEFAULT'
    END AS on_update,

    CASE con.confdeltype
        WHEN 'a' THEN 'NO ACTION'
        WHEN 'r' THEN 'RESTRICT'
        WHEN 'c' THEN 'CASCADE'
        WHEN 'n' THEN 'SET NULL'
        WHEN 'd' THEN 'SET DEFAULT'
    END AS on_delete

FROM pg_constraint con

JOIN pg_class src
  ON src.oid = con.conrelid

JOIN pg_namespace src_ns
  ON src_ns.oid = src.relnamespace

JOIN pg_class dst
  ON dst.oid = con.confrelid

JOIN pg_namespace dst_ns
  ON dst_ns.oid = dst.relnamespace

WHERE con.contype = 'f'
  AND src_ns.nspname NOT IN ('pg_catalog', 'information_schema')

ORDER BY
    source_schema,
    source_table,
    constraint_name;
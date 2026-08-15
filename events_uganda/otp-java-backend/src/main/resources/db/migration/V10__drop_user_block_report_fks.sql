-- Drop foreign key constraints from user_blocks and reports that reference users(id).
-- Chat participants (e.g. vendor-1) are not always rows in the users table, so
-- blocking/reporting them would otherwise fail with a foreign key violation.
DO $$
DECLARE
    fk_record RECORD;
BEGIN
    FOR fk_record IN
        SELECT tbl.oid::regclass AS table_name, con.conname AS constraint_name
        FROM pg_constraint con
        JOIN pg_class tbl ON tbl.oid = con.conrelid
        JOIN pg_class reftbl ON reftbl.oid = con.confrelid
        WHERE tbl.relname IN ('user_blocks', 'reports')
          AND reftbl.relname = 'users'
          AND con.contype = 'f'
    LOOP
        EXECUTE format('ALTER TABLE %s DROP CONSTRAINT IF EXISTS %I',
                       fk_record.table_name, fk_record.constraint_name);
    END LOOP;
END $$;

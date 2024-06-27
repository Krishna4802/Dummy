CREATE PROCEDURE GetTableCounts
AS
BEGIN
    SET NOCOUNT ON;

    -- Declare a table variable to store the results
    DECLARE @Results TABLE (
        new_table NVARCHAR(128),
        new_table_count INT,
        old_table NVARCHAR(128),
        old_table_count INT
    );

    -- Declare a cursor to iterate over table pairs
    DECLARE @new_table NVARCHAR(128);
    DECLARE @old_table NVARCHAR(128);
    DECLARE table_cursor CURSOR FOR
    SELECT new_table, old_table FROM TablePairs;

    OPEN table_cursor;

    FETCH NEXT FROM table_cursor INTO @new_table, @old_table;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        DECLARE @new_table_count INT;
        DECLARE @old_table_count INT;

        -- Dynamic SQL to get the row count of the new_table
        SET @SQL = 'SELECT @new_table_count = COUNT(*) FROM ' + QUOTENAME(@new_table);
        EXEC sp_executesql @SQL, N'@new_table_count INT OUTPUT', @new_table_count OUTPUT;

        -- Dynamic SQL to get the row count of the old_table
        SET @SQL = 'SELECT @old_table_count = COUNT(*) FROM ' + QUOTENAME(@old_table);
        EXEC sp_executesql @SQL, N'@old_table_count INT OUTPUT', @old_table_count OUTPUT;

        -- Insert the results into the @Results table variable
        INSERT INTO @Results (new_table, new_table_count, old_table, old_table_count)
        VALUES (@new_table, @new_table_count, @old_table, @old_table_count);

        FETCH NEXT FROM table_cursor INTO @new_table, @old_table;
    END

    CLOSE table_cursor;
    DEALLOCATE table_cursor;

    -- Select the results
    SELECT * FROM @Results;
END;

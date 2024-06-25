CREATE PROCEDURE GetTableCounts
    @ObjectName NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX) = '';
    DECLARE @TableName NVARCHAR(255);

    -- Temporary table to hold table names
    CREATE TABLE #TableNames (
        TableName NVARCHAR(255)
    );

    -- Insert table names into the temporary table
    INSERT INTO #TableNames (TableName)
    SELECT DISTINCT table_name
    FROM input.table_details
    WHERE type = 'table' AND object_name = @ObjectName;

    -- Cursor to iterate over the table names
    DECLARE TableCursor CURSOR FOR
    SELECT TableName
    FROM #TableNames;

    OPEN TableCursor;
    FETCH NEXT FROM TableCursor INTO @TableName;

    -- Loop through the table names and construct the dynamic SQL
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @SQL = @SQL + 
            'SELECT ''' + @TableName + ''' AS TableName, COUNT(*) AS RowCount FROM ' + @TableName + ' UNION ALL ';

        FETCH NEXT FROM TableCursor INTO @TableName;
    END;

    CLOSE TableCursor;
    DEALLOCATE TableCursor;

    -- Remove the trailing 'UNION ALL'
    SET @SQL = LEFT(@SQL, LEN(@SQL) - 10);

    -- Execute the dynamic SQL
    EXEC sp_executesql @SQL;

    -- Drop the temporary table
    DROP TABLE #TableNames;
END;

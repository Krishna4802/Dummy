        CREATE PROCEDURE DropHistoryTables
            @BaseTableName NVARCHAR(128),
            @KeepCount INT
        AS
        BEGIN
            SET NOCOUNT ON;
        
            DECLARE @SQL NVARCHAR(MAX) = ''
            DECLARE @HistoryTable NVARCHAR(128)
            DECLARE @RowCount INT
        
            -- Create a table to hold the history table names
            CREATE TABLE #HistoryTables (TableName NVARCHAR(128), RowNum INT)
        
            -- Insert history table names into the temp table with row numbers
            INSERT INTO #HistoryTables (TableName, RowNum)
            SELECT TABLE_NAME, ROW_NUMBER() OVER (ORDER BY TABLE_NAME DESC) AS RowNum
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_NAME LIKE @BaseTableName + '_history_%'
        
            -- Check how many history tables were found
            SELECT * FROM #HistoryTables
        
            -- Determine the number of tables to delete
            SELECT @RowCount = COUNT(*) - @KeepCount FROM #HistoryTables
        
            -- Check how many tables we need to delete
            PRINT 'Number of tables to delete: ' + CAST(@RowCount AS NVARCHAR(10))
        
            -- Only proceed if there are tables to delete
            IF @RowCount > 0
            BEGIN
                -- Fetch and generate the drop statements for the tables to be deleted
                SELECT @SQL = STRING_AGG('DROP TABLE ' + QUOTENAME(TableName), '; ') + ';'
                FROM #HistoryTables
                WHERE RowNum > @KeepCount
        
                -- Check the generated SQL
                PRINT 'Generated SQL: ' + @SQL
        
                -- Execute the generated SQL to drop the old history tables
                EXEC sp_executesql @SQL
            END
        
            -- Drop the temp table
            DROP TABLE #HistoryTables
        END
        
        

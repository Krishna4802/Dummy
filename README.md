        CREATE PROCEDURE DropHistoryTables
            @BaseTableName NVARCHAR(128),
            @KeepCount INT
        AS
        BEGIN
            SET NOCOUNT ON;
        
            DECLARE @SQL NVARCHAR(MAX) = ''
            DECLARE @RowCount INT
            DECLARE @ActualTableName NVARCHAR(128)
        
            -- Extract the actual table name without schema
            SET @ActualTableName = PARSENAME(@BaseTableName, 1)
        
            -- Create a table to hold the history table names
            CREATE TABLE #HistoryTables (TableName NVARCHAR(128), TimestampPart NVARCHAR(50), RowNum INT)
        
            -- Insert history table names into the temp table with row numbers
            INSERT INTO #HistoryTables (TableName, TimestampPart, RowNum)
            SELECT 
                TABLE_NAME,
                RIGHT(TABLE_NAME, 19) AS TimestampPart,
                ROW_NUMBER() OVER (ORDER BY CONVERT(DATETIME, REPLACE(REPLACE(RIGHT(TABLE_NAME, 19), '_', '-'), '-', ':')) DESC) AS RowNum
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_NAME LIKE @ActualTableName + '_history_%'
        
            -- Debug: Check how many history tables were found
            PRINT 'History tables found:'
            SELECT * FROM #HistoryTables
        
            -- Determine the number of tables to delete
            SELECT @RowCount = COUNT(*) - @KeepCount FROM #HistoryTables
        
            -- Debug: Check how many tables we need to delete
            PRINT 'Number of tables to delete: ' + CAST(@RowCount AS NVARCHAR(10))
        
            -- Only proceed if there are tables to delete
            IF @RowCount > 0
            BEGIN
                -- Fetch and generate the drop statements for the tables to be deleted
                SELECT @SQL = STRING_AGG('DROP TABLE ' + QUOTENAME(TableName), '; ') + ';'
                FROM #HistoryTables
                WHERE RowNum > @KeepCount
        
                -- Debug: Check the generated SQL
                PRINT 'Generated SQL: ' + @SQL
        
                -- Execute the generated SQL to drop the old history tables
                EXEC sp_executesql @SQL
            END
            ELSE
            BEGIN
                PRINT 'No tables to delete.'
            END
        
            -- Drop the temp table
            DROP TABLE #HistoryTables
        END

        CREATE PROCEDURE DropHistoryTables
            @BaseTableName NVARCHAR(128),
            @KeepCount INT
        AS
        BEGIN
            DECLARE @SQL NVARCHAR(MAX) = ''
            DECLARE @HistoryTable NVARCHAR(128)
            DECLARE @DropTableSQL NVARCHAR(MAX)
        
            -- Create a table to hold the history table names
            CREATE TABLE #HistoryTables (TableName NVARCHAR(128))
        
            -- Insert history table names into the temp table
            INSERT INTO #HistoryTables (TableName)
            SELECT TABLE_NAME
            FROM INFORMATION_SCHEMA.TABLES
            WHERE TABLE_NAME LIKE @BaseTableName + '_history_%'
            ORDER BY TABLE_NAME DESC
        
            -- Declare a cursor to iterate over the history tables
            DECLARE HistoryTableCursor CURSOR FOR
            SELECT TableName
            FROM #HistoryTables
        
            -- Open the cursor
            OPEN HistoryTableCursor
        
            -- Skip the specified number of recent history tables
            WHILE @KeepCount > 0
            BEGIN
                FETCH NEXT FROM HistoryTableCursor INTO @HistoryTable
                IF @@FETCH_STATUS = 0
                    SET @KeepCount = @KeepCount - 1
                ELSE
                    BREAK
            END
        
            -- Fetch and generate the drop statements for the remaining tables
            FETCH NEXT FROM HistoryTableCursor INTO @HistoryTable
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @DropTableSQL = 'DROP TABLE ' + QUOTENAME(@HistoryTable) + ';'
                SET @SQL = @SQL + @DropTableSQL + CHAR(13) -- Add new line for readability
                FETCH NEXT FROM HistoryTableCursor INTO @HistoryTable
            END
        
            -- Close and deallocate the cursor
            CLOSE HistoryTableCursor
            DEALLOCATE HistoryTableCursor
        
            -- Drop the temp table
            DROP TABLE #HistoryTables
        
            -- Execute the generated SQL to drop the old history tables
            EXEC sp_executesql @SQL
        END




    EXEC DropHistoryTables @BaseTableName = 'OldTable', @KeepCount = 1


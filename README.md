                CREATE PROCEDURE MoveAndDropTableWithTimestamp
                    @SourceTableName NVARCHAR(128)
                AS
                BEGIN
                    DECLARE @DestinationTableName NVARCHAR(128)
                    DECLARE @InsertSQL NVARCHAR(MAX)
                    DECLARE @DropSQL NVARCHAR(MAX)
                    DECLARE @CurrentDateTime NVARCHAR(20)
                    
                    -- Get the current date and time in the format yyyy_mm_dd_hh_mm_ss
                    SET @CurrentDateTime = FORMAT(GETDATE(), 'yyyy_MM_dd_HH_mm_ss')
                
                    -- Construct the destination table name
                    SET @DestinationTableName = @SourceTableName + '_history_' + @CurrentDateTime
                
                    -- Construct the SQL queries
                    SET @InsertSQL = N'SELECT * INTO ' + QUOTENAME(@DestinationTableName) + ' FROM ' + QUOTENAME(@SourceTableName)
                    SET @DropSQL = N'DROP TABLE ' + QUOTENAME(@SourceTableName)
                
                    -- Execute the insert SQL query
                    EXEC sp_executesql @InsertSQL
                
                    -- Execute the drop table SQL query
                    EXEC sp_executesql @DropSQL
END

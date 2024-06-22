                CREATE PROCEDURE lib.generate_chunk_queries
                (
                    @loadquery NVARCHAR(MAX),
                    @primary_key NVARCHAR(MAX),
                    @chunksize INT = 5000
                )
                AS
                BEGIN
                    DECLARE @total_count INT;
                    DECLARE @offset INT = 0;
                    DECLARE @query NVARCHAR(MAX);
                    DECLARE @sql NVARCHAR(MAX);
                    DECLARE @params NVARCHAR(MAX);
                
                    -- Temporary table to hold the generated queries
                    DECLARE @Queries TABLE
                    (
                        Query NVARCHAR(MAX)
                    );
                
                    -- Construct the dynamic SQL to get the total count
                    SET @sql = N'SELECT @total_count = COUNT(*) FROM (' + @loadquery + ') AS LoadQuery';
                    SET @params = N'@total_count INT OUTPUT';
                
                    -- Execute the dynamic SQL to get the total count
                    EXEC sp_executesql @sql, @params, @total_count = @total_count OUTPUT;
                
                    -- Generate queries for each chunk
                    WHILE @offset < @total_count
                    BEGIN
                        SET @query = N'SELECT * FROM (' + @loadquery + ') AS LoadQuery ORDER BY ' + @primary_key + ' OFFSET ' + CAST(@offset AS NVARCHAR(MAX)) + ' ROWS FETCH NEXT ' + CAST(@chunksize AS NVARCHAR(MAX)) + ' ROWS ONLY';
                
                        -- Insert the generated query into the temporary table
                        INSERT INTO @Queries (Query) VALUES (@query);
                
                        -- Move to the next chunk
                        SET @offset = @offset + @chunksize;
                    END;
                
                    -- Return the result set
                    SELECT Query FROM @Queries;
                END;

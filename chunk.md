    CREATE FUNCTION dbo.getchunkloadquery
    (
        @loadquery NVARCHAR(MAX),
        @primary_key NVARCHAR(MAX),
        @chunksize INT = 5000
    )
    RETURNS @Queries TABLE
    (
        Query NVARCHAR(MAX)
    )
    AS
    BEGIN
        DECLARE @total_count INT;
        DECLARE @offset INT = 0;
        DECLARE @query NVARCHAR(MAX);
    
        -- Temporary table to store row numbers based on primary_key
        DECLARE @RowNumbers TABLE
        (
            RowNumber INT IDENTITY(1,1),
            PrimaryKeyValue NVARCHAR(MAX)
        );
    
        -- Construct the query to get total count and row numbers
        SET @query = N'
            SELECT 
                COUNT(*) AS total_count,
                ' + @primary_key + ' AS PrimaryKeyValue
            FROM 
                (' + @loadquery + ') AS LoadQuery';
        
        -- Execute the query to get total count and populate row numbers
        INSERT INTO @RowNumbers (PrimaryKeyValue)
        EXEC sp_executesql @query;
    
        -- Get total count
        SELECT @total_count = total_count FROM @RowNumbers;
    
        -- Generate queries for each chunk
        WHILE @offset < @total_count
        BEGIN
            SET @query = N'
                SELECT * 
                FROM (
                    SELECT 
                        ROW_NUMBER() OVER (ORDER BY ' + @primary_key + ') AS RowNum,
                        * 
                    FROM 
                        (' + @loadquery + ') AS LoadQuery
                ) AS NumberedRows
                WHERE RowNum > ' + CAST(@offset AS NVARCHAR(MAX)) + '
                AND RowNum <= ' + CAST(@offset + @chunksize AS NVARCHAR(MAX));
    
            -- Insert the generated query into the result table
            INSERT INTO @Queries (Query) VALUES (@query);
    
            -- Move to the next chunk
            SET @offset = @offset + @chunksize;
        END;
    
        -- Return the result set
        RETURN;
    END;

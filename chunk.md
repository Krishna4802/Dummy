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
          INSERT INTO @Queries
          EXEC dbo.generate_chunk_queries @loadquery, @primary_key, @chunksize;
      
          RETURN;
      END;





SELECT Query 
FROM dbo.getchunkloadquery('SELECT * FROM meta.get_tables', 'id', 10);

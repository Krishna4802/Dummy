            CREATE PROCEDURE dbo.get_direct_references
            (
                @object_id INT,
                @level INT
            )
            AS
            BEGIN
                SELECT 
                    @level AS level,
                    referenced_entity = 
                        QUOTENAME(SCHEMA_NAME(o.schema_id)) + '.' + QUOTENAME(o.name),
                    referenced_entity_id = o.object_id
                INTO #DirectReferences
                FROM 
                    sys.sql_expression_dependencies d
                INNER JOIN 
                    sys.objects o ON d.referenced_id = o.object_id
                WHERE 
                    d.referencing_id = @object_id
                    AND o.type IN ('V', 'U', 'P', 'FN') -- Only include views, tables, stored procedures, and functions
                    AND o.is_ms_shipped = 0;
                
                SELECT * FROM #DirectReferences;
                
                DROP TABLE #DirectReferences;
            END;




            CREATE PROCEDURE dbo.get_all_references
            (
                @object_name NVARCHAR(256)
            )
            AS
            BEGIN
                DECLARE @object_id INT;
                DECLARE @level INT = 1;
            
                SELECT @object_id = OBJECT_ID(@object_name);
            
                IF OBJECT_ID('tempdb..#References') IS NOT NULL
                    DROP TABLE #References;
            
                CREATE TABLE #References
                (
                    base_entity NVARCHAR(256),
                    level INT,
                    referenced_entity NVARCHAR(256),
                    referenced_entity_id INT
                );
            
                INSERT INTO #References (base_entity, level, referenced_entity, referenced_entity_id)
                VALUES (@object_name, @level, @object_name, @object_id);
            
                WHILE EXISTS (SELECT 1 FROM #References WHERE level = @level)
                BEGIN
                    INSERT INTO #References (base_entity, level, referenced_entity, referenced_entity_id)
                    SELECT 
                        r.base_entity,
                        @level + 1,
                        dr.referenced_entity,
                        dr.referenced_entity_id
                    FROM 
                        #References r
                    CROSS APPLY 
                        (
                            EXEC dbo.get_direct_references r.referenced_entity_id, @level + 1
                        ) dr
                    WHERE 
                        r.level = @level
                        AND NOT EXISTS (
                            SELECT 1 
                            FROM #References x
                            WHERE x.referenced_entity_id = dr.referenced_entity_id
                            AND x.level <= @level + 1
                        );
            
                    SET @level = @level + 1;
                END;
            
                -- Pivot the results to get the desired output format
                DECLARE @columns NVARCHAR(MAX), @sql NVARCHAR(MAX);
                SELECT @columns = ISNULL(@columns + ', ', '') + QUOTENAME('referenced_entity level ' + CAST(level AS NVARCHAR))
                FROM (SELECT DISTINCT level FROM #References WHERE level > 1) AS Levels
                ORDER BY level;
            
                SET @sql = '
                SELECT base_entity, ' + @columns + '
                FROM (
                    SELECT base_entity, referenced_entity, ''referenced_entity level '' + CAST(level AS NVARCHAR) AS lvl
                    FROM #References
                ) AS SourceTable
                PIVOT (
                    MAX(referenced_entity)
                    FOR lvl IN (' + @columns + ')
                ) AS PivotTable
                ORDER BY base_entity';
            
                EXEC sp_executesql @sql;
            
                DROP TABLE #References;
            END;



            EXEC dbo.get_all_references 'stg2.SP_employee_details';


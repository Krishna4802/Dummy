            CREATE FUNCTION dbo.get_direct_references
            (
                @object_name NVARCHAR(256)
            )
            RETURNS @References TABLE
            (
                referenced_entity NVARCHAR(256)
            )
            AS
            BEGIN
                DECLARE @object_id INT;
            
                SELECT @object_id = OBJECT_ID(@object_name);
            
                INSERT INTO @References (referenced_entity)
                SELECT 
                    referenced_entity = referenced_entity_name 
                FROM 
                    (SELECT DISTINCT 
                        referenced_entity_name = 
                            OBJECT_SCHEMA_NAME(referencing_id) + '.' + OBJECT_NAME(referencing_id)
                     FROM sys.sql_expression_dependencies 
                     WHERE referencing_id = @object_id
                     AND referenced_entity_name IS NOT NULL
                    ) AS DirectReferences;
            
                RETURN;
            END;




                        
                        
                        CREATE PROCEDURE dbo.get_all_references
                        (
                            @object_name NVARCHAR(256)
                        )
                        AS
                        BEGIN
                            WITH EntityReferences AS
                            (
                                -- Anchor member: Start with the given stored procedure
                                SELECT 
                                    @object_name AS referenced_entity,
                                    @object_name AS base_entity
                                UNION ALL
                                -- Recursive member: Get references for each referenced entity
                                SELECT 
                                    dr.referenced_entity,
                                    er.base_entity
                                FROM 
                                    dbo.get_direct_references(er.referenced_entity) dr
                                INNER JOIN 
                                    EntityReferences er ON dr.referenced_entity = er.referenced_entity
                            )
                            SELECT DISTINCT 
                                base_entity,
                                referenced_entity
                            FROM 
                                EntityReferences
                            WHERE 
                                referenced_entity != base_entity
                            ORDER BY 
                                base_entity, referenced_entity;
                        END;
                        
                        
                        
                        
                        EXEC dbo.get_all_references 'stg2.SP_employee_details';


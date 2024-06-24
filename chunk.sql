            path = CAST(er.path + ' -> ' + 
                        CASE 
                            WHEN dr.referenced_entity LIKE 'input.vw_%' THEN (
                                SELECT COALESCE(MAX(referenced_entity), dr.referenced_entity)
                                FROM sys.sql_expression_dependencies
                                WHERE referencing_id = dr.referenced_entity_id
                            )
                            ELSE dr.referenced_entity 
                        END 
                        AS NVARCHAR(MAX))

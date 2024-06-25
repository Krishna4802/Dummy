CREATE PROCEDURE dbo.get_all_references
(
    @object_name NVARCHAR(256)
)
AS
BEGIN
    DECLARE @object_id INT;
    SELECT @object_id = OBJECT_ID(@object_name);

    IF @object_id IS NULL
    BEGIN
        RAISERROR('Invalid object name: %s', 16, 1, @object_name);
        RETURN;
    END

    ;WITH EntityReferences AS
    (
        -- Anchor member: start with the given stored procedure
        SELECT 
            base_entity = @object_name,
            referenced_entity = @object_name,
            referenced_entity_id = @object_id,
            level = 0,
            path = CAST(@object_name AS NVARCHAR(MAX))
        UNION ALL
        -- Recursive member: get references for each referenced entity
        SELECT 
            er.base_entity,
            CASE 
                WHEN dr.referenced_entity LIKE 'input.mv_%' THEN REPLACE(dr.referenced_entity, 'input.mv_', 'input.vw_')
                ELSE dr.referenced_entity
            END AS referenced_entity,
            dr.referenced_entity_id,
            er.level + 1,
            CAST(er.path + ' -> ' + 
                CASE 
                    WHEN dr.referenced_entity LIKE 'input.vw_%' THEN (
                        SELECT COALESCE(MAX(dr2.referenced_entity), dr.referenced_entity)
                        FROM sys.sql_expression_dependencies dr2
                        WHERE dr2.referencing_id = dr.referenced_entity_id
                    )
                    ELSE dr.referenced_entity 
                END 
            AS NVARCHAR(MAX)) AS path
        FROM 
            EntityReferences er
        CROSS APPLY 
            dbo.get_direct_references(er.referenced_entity_id) dr
        WHERE 
            CHARINDEX(dr.referenced_entity, er.path) = 0 -- Avoid circular references
    )
    SELECT 
        base_entity,
        referenced_entity,
        level,
        path
    FROM 
        EntityReferences
    WHERE 
        referenced_entity != base_entity
    ORDER BY 
        base_entity, level, referenced_entity
    OPTION (MAXRECURSION 0); -- Allow unlimited recursion
END;

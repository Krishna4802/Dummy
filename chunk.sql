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
        -- Anchor member: start with the given object
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
            referenced_entity = 
                CASE 
                    WHEN dr.referenced_entity LIKE 'mv\_%' THEN REPLACE(dr.referenced_entity, 'mv_', 'vw_')
                    ELSE dr.referenced_entity
                END,
            referenced_entity_id = 
                CASE 
                    WHEN dr.referenced_entity LIKE 'mv\_%' THEN OBJECT_ID(REPLACE(dr.referenced_entity, 'mv_', 'vw_'))
                    ELSE OBJECT_ID(dr.referenced_entity)
                END,
            er.level + 1,
            path = er.path + ' -> ' + 
                CASE 
                    WHEN dr.referenced_entity LIKE 'mv\_%' THEN REPLACE(dr.referenced_entity, 'mv_', 'vw_')
                    ELSE dr.referenced_entity 
                END
        FROM 
            EntityReferences er
        CROSS APPLY 
            (
                SELECT 
                    referenced_entity = referenced_entity_name,
                    referenced_entity_id = dbo.GetEntityID(referenced_entity_name) -- Replace with your function to get entity ID
                FROM 
                    dbo.get_direct_references(er.referenced_entity_id)
            ) dr
        WHERE 
            CHARINDEX(
                CASE 
                    WHEN dr.referenced_entity LIKE 'mv\_%' THEN REPLACE(dr.referenced_entity, 'mv_', 'vw_')
                    ELSE dr.referenced_entity
                END, 
                er.path
            ) = 0 -- Avoid circular references
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
        base_entity, path
    OPTION (MAXRECURSION 0); -- Allow unlimited recursion
END;

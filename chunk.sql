CREATE OR ALTER PROCEDURE dbo.get_all_references
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
        FROM 
            sys.objects
        WHERE 
            OBJECT_ID = @object_id
        UNION ALL
        -- Recursive member: get references for each referenced entity
        SELECT 
            er.base_entity,
            CASE 
                WHEN CHARINDEX('input.mv_', dr.referenced_entity) = 1 THEN 'input.vw_' + SUBSTRING(dr.referenced_entity, LEN('input.mv_') + 1, LEN(dr.referenced_entity))
                ELSE dr.referenced_entity
            END,
            dr.referenced_entity_id,
            er.level + 1,
            path = CAST(er.path + '->' + 
                        CASE 
                            WHEN CHARINDEX('input.mv_', dr.referenced_entity) = 1 THEN 'input.vw_' + SUBSTRING(dr.referenced_entity, LEN('input.mv_') + 1, LEN(dr.referenced_entity))
                            ELSE dr.referenced_entity
                        END
                     AS NVARCHAR(MAX))
        FROM 
            EntityReferences er
        CROSS APPLY 
            dbo.get_direct_references(dr.referenced_entity_id) dr
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

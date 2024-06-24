drop FUNCTION dbo.get_direct_references

CREATE or alter FUNCTION dbo.get_direct_references(@object_id INT)
RETURNS @References TABLE
(
    referenced_entity NVARCHAR(256),
    referenced_entity_id INT
)
AS
BEGIN
    INSERT INTO @References (referenced_entity, referenced_entity_id)
    SELECT 
        referenced_entity = QUOTENAME(SCHEMA_NAME(o.schema_id)) + '.' + QUOTENAME(o.name),
        referenced_entity_id = o.object_id
    FROM 
        sys.sql_expression_dependencies d
    INNER JOIN 
        sys.objects o ON d.referenced_id = o.object_id
    WHERE 
        d.referencing_id = @object_id
        AND o.type IN ('V', 'U', 'P', 'FN', 'TF') -- Include views, tables, procedures, functions
        AND o.is_ms_shipped = 0;

    RETURN;
END;





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
            referenced_entity = referenced_entity,
            level = 1,
            path = CAST(@object_name AS NVARCHAR(MAX)) + ' -> ' + referenced_entity
        FROM 
            dbo.get_direct_references(@object_id)
        WHERE
            referenced_entity != @object_name -- Exclude self-reference
        UNION ALL
        -- Recursive member: get references for each referenced entity
        SELECT 
            er.base_entity,
            dr.referenced_entity,
            level = er.level + 1,
            path = CAST(er.path + ' -> ' + dr.referenced_entity AS NVARCHAR(MAX))
        FROM 
            EntityReferences er
        CROSS APPLY 
            dbo.get_direct_references(OBJECT_ID(er.referenced_entity)) dr
        WHERE 
            CHARINDEX(dr.referenced_entity, er.path) = 0 -- Avoid circular references
    )
    SELECT 
        base_entity,
        referenced_entity,
        ISNULL((
            SELECT referenced_entity 
            FROM EntityReferences er2 
            WHERE er2.base_entity = er.base_entity 
              AND er2.level = er.level + 1 
              AND CHARINDEX(er.referenced_entity, er2.path) = 1), '') AS level_2,
        ISNULL((
            SELECT referenced_entity 
            FROM EntityReferences er3 
            WHERE er3.base_entity = er.base_entity 
              AND er3.level = er.level + 2 
              AND CHARINDEX(er.referenced_entity, er3.path) = 1), '') AS level_3
    FROM 
        EntityReferences er
    WHERE 
        er.level = 1 -- Only show level 1 references
    ORDER BY 
        base_entity, referenced_entity;
END;

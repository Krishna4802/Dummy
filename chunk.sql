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





CREATE or alter PROCEDURE dbo.get_all_references
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
            referenced_entity = CAST(@object_name AS NVARCHAR(MAX)) AS path,
            level = 1
        UNION ALL
        -- Recursive member: get references for each referenced entity
        SELECT 
            er.base_entity,
            CAST(er.path + ' -> ' + dr.referenced_entity AS NVARCHAR(MAX)),
            er.level + 1
        FROM 
            EntityReferences er
        CROSS APPLY 
            dbo.get_direct_references(OBJECT_ID(er.referenced_entity)) dr
        WHERE 
            CHARINDEX(dr.referenced_entity, er.path) = 0 -- Avoid circular references
    )
    SELECT 
        base_entity AS base_entity,
        STUFF((SELECT CHAR(10) + REPLICATE(' ', (level - 1) * 2) + referenced_entity
               FROM EntityReferences sub
               WHERE sub.base_entity = main.base_entity
               ORDER BY sub.level
               FOR XML PATH('')), 1, 1, '') AS referenced_entities
    FROM 
        EntityReferences main
    WHERE 
        referenced_entity != base_entity
    GROUP BY 
        base_entity
    ORDER BY 
        base_entity;
END;

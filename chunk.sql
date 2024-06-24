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
            referenced_entity = @object_name,
            referenced_entity_id = @object_id,
            level = 0,
            path = CAST(@object_name AS NVARCHAR(MAX)) AS path
        UNION ALL
        -- Recursive member: get references for each referenced entity
        SELECT 
            er.base_entity,
            dr.referenced_entity,
            dr.referenced_entity_id,
            er.level + 1,
            path = CAST(er.path + ' | ' + dr.referenced_entity AS NVARCHAR(MAX))
        FROM 
            EntityReferences er
        CROSS APPLY 
            dbo.get_direct_references(er.referenced_entity_id) dr
        WHERE 
            CHARINDEX(dr.referenced_entity, er.path) = 0 -- Avoid circular references
    )
    SELECT 
        base_entity,
        PARSENAME(referenced_entity, 1) AS level_1,
        PARSENAME(referenced_entity, 2) AS level_2,
        PARSENAME(referenced_entity, 3) AS level_3,
        PARSENAME(referenced_entity, 4) AS level_4,
        PARSENAME(referenced_entity, 5) AS level_5
    FROM 
    (
        SELECT 
            base_entity,
            referenced_entity,
            ROW_NUMBER() OVER (PARTITION BY base_entity ORDER BY level DESC) AS rn
        FROM 
            EntityReferences
        WHERE 
            referenced_entity != base_entity
    ) AS t
    PIVOT 
    (
        MAX(referenced_entity) 
        FOR rn IN ([1], [2], [3], [4], [5])
    ) AS p
    ORDER BY 
        base_entity;
END;

CREATE FUNCTION dbo.get_direct_references(@object_id INT)
RETURNS TABLE
AS
RETURN
(
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
        AND o.is_ms_shipped = 0
);


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
            level = 0
        UNION ALL
        -- Recursive member: get references for each referenced entity
        SELECT 
            er.base_entity,
            dr.referenced_entity,
            dr.referenced_entity_id,
            er.level + 1
        FROM 
            EntityReferences er
        CROSS APPLY 
            dbo.get_direct_references(er.referenced_entity_id) dr
    )
    SELECT DISTINCT 
        base_entity,
        referenced_entity,
        level
    FROM 
        EntityReferences
    WHERE 
        referenced_entity != base_entity
    ORDER BY 
        base_entity, level, referenced_entity;
END;


EXEC dbo.get_all_references 'stg2.SP_employee_details';

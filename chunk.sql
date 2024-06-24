CREATE FUNCTION dbo.get_direct_references(@object_id INT)
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
            path = CAST(er.path + ' -> ' + 
                        CASE 
                            WHEN dr.referenced_entity LIKE 'input.vw_%' THEN dbo.get_path(dr.referenced_entity)
                            ELSE dr.referenced_entity 
                        END AS NVARCHAR(MAX))
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



EXEC dbo.get_all_references 'stg2.SP_employee_details';




CREATE FUNCTION dbo.get_path(@entity NVARCHAR(256))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @path NVARCHAR(MAX);

    SELECT @path = COALESCE(@path + ' -> ' + referenced_entity, referenced_entity)
    FROM sys.sql_expression_dependencies
    WHERE referencing_id = OBJECT_ID(@entity);

    RETURN @path;
END;


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
            referenced_entity = CAST(
                CASE 
                    WHEN dr.referenced_entity LIKE 'input.mv_%' THEN REPLACE(dr.referenced_entity, 'input.mv_', 'input.vw_')
                    ELSE dr.referenced_entity
                END AS NVARCHAR(256)
            ),
            referenced_entity_id = 
                CASE 
                    WHEN dr.referenced_entity LIKE 'input.mv_%' THEN OBJECT_ID(REPLACE(dr.referenced_entity, 'input.mv_', 'input.vw_'))
                    ELSE dr.referenced_entity_id
                END,
            er.level + 1,
            path = CAST(er.path + ' -> ' + 
                CASE 
                    WHEN dr.referenced_entity LIKE 'input.mv_%' THEN REPLACE(dr.referenced_entity, 'input.mv_', 'input.vw_')
                    ELSE dr.referenced_entity 
                END AS NVARCHAR(MAX))
        FROM 
            EntityReferences er
        CROSS APPLY 
            dbo.get_direct_references(
                CASE 
                    WHEN dr.referenced_entity LIKE 'input.mv_%' THEN OBJECT_ID(REPLACE(dr.referenced_entity, 'input.mv_', 'input.vw_'))
                    ELSE dr.referenced_entity_id
                END
            ) dr
        WHERE 
            CHARINDEX(
                CASE 
                    WHEN dr.referenced_entity LIKE 'input.mv_%' THEN REPLACE(dr.referenced_entity, 'input.mv_', 'input.vw_')
                    ELSE dr.referenced_entity
                END, 
                er.path
            ) = 0 -- Avoid circular references
    )
    SELECT 
        base_entity,
        MAX(CASE WHEN level = 1 THEN referenced_entity ELSE NULL END) AS referenced_entity_level_1,
        MAX(CASE WHEN level = 2 THEN referenced_entity ELSE NULL END) AS referenced_entity_level_2,
        MAX(CASE WHEN level = 3 THEN referenced_entity ELSE NULL END) AS referenced_entity_level_3,
        MAX(CASE WHEN level = 4 THEN referenced_entity ELSE NULL END) AS referenced_entity_level_4,
        MAX(CASE WHEN level = 5 THEN referenced_entity ELSE NULL END) AS referenced_entity_level_5,
        MAX(CASE WHEN level = 6 THEN referenced_entity ELSE NULL END) AS referenced_entity_level_6,
        MAX(CASE WHEN level = 7 THEN referenced_entity ELSE NULL END) AS referenced_entity_level_7,
        MAX(CASE WHEN level = 8 THEN referenced_entity ELSE NULL END) AS referenced_entity_level_8,
        MAX(CASE WHEN level = 9 THEN referenced_entity ELSE NULL END) AS referenced_entity_level_9,
        MAX(CASE WHEN level = 10 THEN referenced_entity ELSE NULL END) AS referenced_entity_level_10,
        path
    FROM 
        EntityReferences
    WHERE 
        referenced_entity != base_entity
    GROUP BY 
        base_entity, path
    ORDER BY 
        base_entity, path
    OPTION (MAXRECURSION 0); -- Allow unlimited recursion
END;

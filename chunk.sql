    -- Adjust @object_name if it starts with 'input.mv_'
    IF LEFT(@object_name, 8) = 'input.mv_'
    BEGIN
        SET @object_name = 'input.vw_' + SUBSTRING(@object_name, 9, LEN(@object_name));
    END

    SELECT @object_id = OBJECT_ID(@object_name);

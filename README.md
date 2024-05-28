    -- Create the function
    CREATE FUNCTION dbo.fn_GetStateByZipcode(@zipcode INT)
    RETURNS NVARCHAR(50)
    AS
    BEGIN
        DECLARE @state NVARCHAR(50);
    
        SELECT @state = State
        FROM test.zipstate
        WHERE zipcode = @zipcode;
    
        RETURN @state;
    END
    GO

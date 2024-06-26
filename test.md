SELECT
    CASE
        WHEN CHARINDEX(' ', FullName) = 0 THEN FullName
        ELSE LEFT(FullName, CHARINDEX(' ', FullName) - 1)
    END AS FirstWord
FROM
    Employees;






SELECT
    -- Extract the last word
    CASE
        WHEN CHARINDEX(' ', REVERSE(FullName)) = 0 THEN FullName
        ELSE REVERSE(LEFT(REVERSE(FullName), CHARINDEX(' ', REVERSE(FullName)) - 1))
    END AS LastWord
FROM
    Employees;






CREATE FUNCTION dbo.GetFirstWord (@inputString NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (
        CASE
            WHEN CHARINDEX(' ', @inputString) = 0 THEN @inputString
            ELSE LEFT(@inputString, CHARINDEX(' ', @inputString) - 1)
        END
    );
END;
GO





CREATE FUNCTION dbo.GetLastWord (@inputString NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    RETURN (
        CASE
            WHEN CHARINDEX(' ', REVERSE(@inputString)) = 0 THEN @inputString
            ELSE REVERSE(LEFT(REVERSE(@inputString), CHARINDEX(' ', REVERSE(@inputString)) - 1))
        END
    );
END;
GO






        CREATE FUNCTION dbo.GetMiddleName (
            @FirstName NVARCHAR(MAX),
            @MiddleName NVARCHAR(MAX),
            @LastName NVARCHAR(MAX)
        )
        RETURNS NVARCHAR(MAX)
        AS
        BEGIN
            DECLARE @FirstNameParts NVARCHAR(MAX);
            DECLARE @LastNameParts NVARCHAR(MAX);
            DECLARE @Result NVARCHAR(MAX);
            
            -- Extracting the middle components from the first name
            SET @FirstNameParts = 
                CASE
                    WHEN CHARINDEX(' ', @FirstName) = 0 THEN ''
                    ELSE SUBSTRING(@FirstName, CHARINDEX(' ', @FirstName) + 1, LEN(@FirstName) - CHARINDEX(' ', @FirstName))
                END;
            
            -- Extracting the parts from the last name except the last word
            SET @LastNameParts = 
                CASE
                    WHEN CHARINDEX(' ', @LastName) = 0 THEN ''
                    ELSE LEFT(@LastName, LEN(@LastName) - CHARINDEX(' ', REVERSE(@LastName)))
                END;
            
            -- If the middle name is NULL, set it to an empty string
            SET @MiddleName = ISNULL(@MiddleName, '');
            
            -- Combine the extracted parts with the middle name
            SET @Result = LTRIM(RTRIM(@FirstNameParts + ' ' + @MiddleName + ' ' + @LastNameParts));
            
            RETURN @Result;
        END;
        GO




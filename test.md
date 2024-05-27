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

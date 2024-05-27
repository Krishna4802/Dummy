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

SELECT
    CASE
        WHEN CHARINDEX(' ', FullName) = 0 THEN FullName
        ELSE LEFT(FullName, CHARINDEX(' ', FullName) - 1)
    END AS FirstWord
FROM
    Employees;

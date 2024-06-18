        SELECT TOP 10 
            qs.creation_time,
            qs.last_execution_time,
            qs.execution_count,
            SUBSTRING(qt.text, (qs.statement_start_offset/2) + 1, 
            ((CASE qs.statement_end_offset
                WHEN -1 THEN DATALENGTH(qt.text)
                ELSE qs.statement_end_offset
            END - qs.statement_start_offset)/2) + 1) AS query_text,
            qt.dbid,
            DB_NAME(qt.dbid) AS database_name,
            s.login_name AS executed_by_user
        FROM 
            sys.dm_exec_query_stats AS qs
        CROSS APPLY 
            sys.dm_exec_sql_text(qs.sql_handle) AS qt
        JOIN 
            sys.dm_exec_sessions AS s ON qs.session_id = s.session_id
        WHERE 
            s.login_name = 'YourUserName' -- Replace with the specific username
        ORDER BY 
            qs.last_execution_time DESC;

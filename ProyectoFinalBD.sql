
SET SERVEROUTPUT ON;
GRANT select any dictionary to system;

/*----------------------------------------------------------------------------Application Package-------------------------------------------------------------------------------------------------------*/
CREATE OR REPLACE PACKAGE DrBd IS
PROCEDURE drUSR (v_nombre_usuario VARCHAR2);
PROCEDURE drFKS (v_nombre_usuario VARCHAR2);
PROCEDURE drDATA (v_nombre_usuario VARCHAR2);
END DrBd;


CREATE OR REPLACE PACKAGE BODY DrBd IS
/*---------------------------------------------------------------------PRIMER EJERCICIO------------------------------------------------------------*/
PROCEDURE drUSR (v_nombre_usuario VARCHAR2) IS
    pTableSpace nvarchar2(20):='';
    pQuota number;
    pQuota2 nvarchar2(12):='';
    pNumberViews number;
    pNumberTables number;
    pSynonyms number;
    pSecuences number;
    cursor cursor1 is SELECT * FROM all_tables where owner = v_nombre_usuario ORDER BY TABLE_NAME;
    tableRowNum number;
    tableName nvarchar2(20);
    defNull nvarchar2(10):='';
    vType nvarchar2(8):='';
    fTableName nvarchar2(30):='';
    pType nvarchar2(20):='';
    string_query VARCHAR2(100);
    c1 SYS_REFCURSOR;
BEGIN
   select default_tablespace into pTableSpace from DBA_USERS where USERNAME = v_nombre_usuario;
    select max_bytes into pQuota from DBA_TS_QUOTAS where USERNAME = v_nombre_usuario;
    if pQuota = -1 then
        pQuota2:='Unlimited';
    else
        pQuota2:='Limited';
    end if;
    select count(*) into pNumberTables from DBA_TABLES where OWNER = v_nombre_usuario;
    select count(*) into pNumberViews from DBA_VIEWS where OWNER= v_nombre_usuario;
    select count(*) into pSynonyms from DBA_SYNONYMS where OWNER = v_nombre_usuario;
    select count(*) into pSecuences from DBA_SEQUENCES where sequence_owner = v_nombre_usuario;
    DBMS_OUTPUT.PUT_LINE('USER: '|| v_nombre_usuario ||'                '||'TableSpace: '|| pTableSpace ||'             '||'Quota: '|| pQuota2);
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('    '||'  Tables: '|| pNumberTables ||'          '||'Views: '|| pNumberViews||'          '||'Synonyms: '|| pSynonyms||'          '||'Secuences: '|| pSecuences);   
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------------');
    FOR i IN cursor1
    LOOP
    string_query:='SELECT COUNT(*) FROM ALL_TAB_COLUMNS WHERE OWNER=:VnOMBRE AND TABLE_NAME=:tableN';
    EXECUTE IMMEDIATE string_query INTO tableRowNum using v_nombre_usuario, i.TABLE_NAME;
    tableName:= upper(substr(i.TABLE_NAME,1,1))||lower(substr(i.TABLE_NAME,2));
    DBMS_OUTPUT.PUT_LINE('Table :' || tableName ||' '||tableRowNum ||' rows');
    tableName:= i.TABLE_NAME;
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Columns' || '           '||' Null?'|| '          '||' Type'|| '            '||'Key'|| '        '||'F.Table');
    DBMS_OUTPUT.PUT_LINE('---------------  ------------  ----------------  --------  --------------');
      FOR cursor2 IN (select column_name, data_type, DATA_LENGTH, nullable from DBA_tab_columns where OWNER=v_nombre_usuario AND TABLE_NAME=i.TABLE_NAME ORDER BY COLUMN_NAME)
        LOOP     
         defNull:=' ';
        if cursor2.nullable='Y' then
            defNull:='Not Null';
        end if;          
        BEGIN
        select pType,tName into vType, fTableName from(SELECT  c.constraint_type pType, c_pk.table_name tName
        FROM all_cons_columns a
        JOIN all_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
        LEFT JOIN all_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
        WHERE c.owner=v_nombre_usuario AND a.table_name = tableName AND a.column_name = cursor2.column_name AND (c.constraint_type ='R' OR c.constraint_type ='P'));
        EXCEPTION
            WHEN no_data_found then
            vType:='';
            fTableName:=''; 
            WHEN others then
             vType:='ver';
            fTableName:='ver';
         END;
        IF vType='P' then
            vType:='PK';
        ELSIF vType='R' then 
            vType:='FK';
        end if;   
        pType:= cursor2.data_type|| '(' || cursor2.DATA_LENGTH|| ')';  
        fTableName:=upper(substr(fTableName,1,1))||lower(substr(fTableName,2));
        DBMS_OUTPUT.PUT_LINE(rpad(cursor2.column_name,15) || '    '|| rpad(defNull,9) || '     '||rpad(pType,14)|| '     '||rpad(vType,2)|| '       '|| rpad(fTableName,15));
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('');
  END LOOP;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
		DBMS_OUTPUT.PUT_LINE('-----------------------------------------------');
		DBMS_OUTPUT.PUT_LINE('No existe un usuario con el nombre ingresado: ' || v_nombre_usuario);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('-----------------------------------------------');
		DBMS_OUTPUT.PUT_LINE('Ha ocurrido un error durante la ejecucion del procedimiento');
END drUSR ;


/*---------------------------------------------------------------------SEGUNDO EJERCICIO------------------------------------------------------------*/
PROCEDURE drFKS(v_nombre_usuario VARCHAR2) IS
    tableName nvarchar2(20);
    pName nvarchar2(50):='';
    secondTable nvarchar2(50):='';
    cursor cursor1 is SELECT * FROM all_tables where owner = v_nombre_usuario ORDER BY TABLE_NAME;
BEGIN
  FOR i IN cursor1
  LOOP
    tableName:=upper(substr(i.TABLE_NAME,1,1))||lower(substr(i.TABLE_NAME,2));
    DBMS_OUTPUT.PUT_LINE(tableName ||':');
    tableName:= i.TABLE_NAME;
    FOR cursor2 IN (SELECT a.table_name, a.column_name, a.constraint_name, c.constraint_type type, c_pk.table_name r_table_name, c_pk.constraint_name r_pk
    FROM all_cons_columns a
    JOIN all_constraints c ON a.owner = c.owner
    AND a.constraint_name = c.constraint_name
    LEFT JOIN all_constraints c_pk ON c.r_owner = c_pk.owner
    AND c.r_constraint_name = c_pk.constraint_name
    WHERE a.owner=v_nombre_usuario and a.table_name=tableName AND c.constraint_type = 'R') LOOP    
    select column_name into pName from all_cons_columns where owner=v_nombre_usuario AND constraint_name=cursor2.r_pk;
    secondTable:=upper(substr(cursor2.r_table_name,1,1))||lower(substr(cursor2.r_table_name,2));
    DBMS_OUTPUT.PUT_LINE( '     '||rpad(cursor2.column_name,17) || ' --> '|| secondTable|| '('|| pName|| ')');
    END LOOP;
  END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('-----------------------------------------------');
		DBMS_OUTPUT.PUT_LINE('Ha ocurrido un error durante la ejecucion del procedimiento');
END drFKS;

/*---------------------------------------------------------------------TERCER EJERCICIO------------------------------------------------------------*/

-------------------------------------ALFA_DDL--------------------------------------------
CREATE TABLE ALFA_DDL(
    CREA_TABLAS_ID NUMBER GENERATED BY DEFAULT AS IDENTITY,
    TABLAS_CREAD VARCHAR(2000)
);

------------------------------------------------------------------------------

create or replace procedure ALFADDL
is
    cursor todas_las_tablas_cursor is select dbms_metadata.get_ddl('TABLE', table_name) AS INFO from user_tables;
begin

    for todas_tablas_cursor_for IN todas_las_tablas_cursor
    loop
         INSERT INTO ALFA_DDL (TABLAS_CREAD) VALUES (todas_tablas_cursor_for.INFO);
    end loop;

END;

-----------------------------EJECUTAR -ALFA_DDL---------------------------------------------
EXEC ALFADDL();

SELECT * FROM ALFA_DDL
ORDER BY CREA_TABLAS_ID ASC;



-------------------------------------ALFA_DML--------------------------------------------
CREATE TABLE ALFA_DML (
    INSERTS VARCHAR(5000)
);

------------------------------------------------------------------------------
DECLARE
    CURSOR c_tablas IS
        SELECT * FROM CAT
        WHERE table_type = 'TABLE';

    -- Cursor para columnas
    v_cursor_columnas SYS_REFCURSOR;
    v_cursor_columnas_sql VARCHAR2(500);

    -- Cursor para valor de columnas
    v_cursor_valor_columnas SYS_REFCURSOR;
    v_cursor_valor_columnas_sql VARCHAR2(500);

    -- Cursor para la cantidad de registros en una tabla
    v_cursor_total_registros SYS_REFCURSOR;
    v_cursor_total_registros_sql VARCHAR2(500);

    -- Cursor para obtener un elemento en X fila
    v_cursor_elemento_x SYS_REFCURSOR;
    v_cursor_elemento_x_sql VARCHAR2(500);

    -- Valores sobre la columna
    v_nombre_columna VARCHAR2(100);
    v_tipo_columna VARCHAR2(100);
    v_columna_null VARCHAR2(100);

    -- Variables para concatenar el INSERT
    v_char_columnas VARCHAR2(8000);
    v_char_valores VARCHAR2(8000);
    v_valor_columna VARCHAR2(5000);

    -- Total de registros de cualquier tabla
    v_totalRegistros NUMBER(10);

    -- INSERT generado
    v_insert VARCHAR2(5000);

BEGIN
    -- Todas las tablas
    FOR tabla IN c_tablas LOOP
        v_char_columnas := '';
        v_char_valores := '';

        v_cursor_columnas_sql := 'SELECT column_name, data_type FROM ALL_TAB_COLUMNS WHERE table_name = ''' || tabla.table_name  || '''';
        
        DBMS_OUTPUT.PUT_LINE('                                ');
        DBMS_OUTPUT.PUT_LINE('INSERT INTO ' || tabla.table_name);

        -- Obtener la cantidad de registros en la tabla actual
        v_cursor_total_registros_sql := 'SELECT COUNT(1) AS cantidadRegistros FROM ' || tabla.table_name;
        OPEN v_cursor_total_registros FOR v_cursor_total_registros_sql;
        LOOP
            FETCH v_cursor_total_registros INTO v_totalRegistros;
            EXIT WHEN v_cursor_total_registros%NOTFOUND;
        END LOOP;
        CLOSE v_cursor_total_registros;
        
        -- Por cada registro generar un insert
        FOR i IN 1..v_totalRegistros LOOP
            v_char_columnas := '';
            v_char_valores := '';

            -- PRIMERA PARTE DEL INSERT ()
            -- Todas las columnas de la tabla
            OPEN v_cursor_columnas FOR v_cursor_columnas_sql;        
            LOOP
                FETCH v_cursor_columnas INTO v_nombre_columna, v_tipo_columna;
                EXIT WHEN v_cursor_columnas%NOTFOUND;

                v_char_columnas := v_char_columnas || v_nombre_columna || ',';

                -- Obtener el valor de la columna actual
                v_cursor_valor_columnas_sql := 'SELECT * FROM ( SELECT * FROM ( SELECT TO_CHAR(' ||
                                                v_nombre_columna  ||
                                                ') AS valor FROM ' ||
                                                tabla.table_name  ||
                                                ') WHERE ROWNUM <= ' || i ||
                                                'ORDER BY ROWNUM DESC) WHERE ROWNUM < 2';
                
                -- Agregar comilla al inicio si no es numero
                IF (SUBSTR(v_tipo_columna, 1, 1) != 'N') THEN
                    v_char_valores := v_char_valores || '''';
                END IF;

                OPEN v_cursor_valor_columnas FOR v_cursor_valor_columnas_sql;
                LOOP
                    FETCH v_cursor_valor_columnas INTO v_valor_columna;
                    EXIT WHEN v_cursor_valor_columnas%NOTFOUND;

                    v_char_valores := v_char_valores || v_valor_columna;
                END LOOP;
                CLOSE v_cursor_valor_columnas;

                -- Agregar comilla al final si no es numero
                IF (SUBSTR(v_tipo_columna, 1, 1) != 'N') THEN
                    v_char_valores := v_char_valores || '''';
                END IF;

                -- Agregar la coma para separar valores
                v_char_valores := v_char_valores || ',';
            END LOOP;
            CLOSE v_cursor_columnas;

            -- Eliminar la coma del final
            v_char_columnas := SUBSTR(v_char_columnas, 1, LENGTH(v_char_columnas) - 1);
            v_char_valores := SUBSTR(v_char_valores, 1, LENGTH(v_char_valores) - 1);

            -- Inserta todo en la tabla de ALFA_DML
             INSERT INTO ALFA_DML ( INSERTS) VALUES('INSERT INTO ' || tabla.table_name || ' (' ||
                                v_char_columnas ||
                                ') VALUES (' ||
                                v_char_valores ||
                                ')');
        END LOOP;
    END LOOP;
END;
/

-----------------------------EJECUTAR -ALFA_DML---------------------------------------------
SELECT * FROM ALFA_DML;

DELETE FROM ALFA_DML;


/*---------------------------------------------------------------------CUARTO EJERCICIO------------------------------------------------------------*/
PROCEDURE drDATA(v_nombre_usuario VARCHAR2) IS
    CURSOR c_columnas IS
        SELECT TABLE_NAME AS tabla, COLUMN_NAME AS columna, SUBSTR(DATA_TYPE, 1, 1) || 
            (CASE 
                WHEN SUBSTR(DATA_TYPE, 1, 1) = 'N' AND NVL(DATA_PRECISION, 0) != 0 THEN'(' || DATA_LENGTH || ',' || DATA_PRECISION || ')'
                WHEN SUBSTR(DATA_TYPE, 1, 1) = 'N' AND NVL(DATA_PRECISION, 0) = 0 THEN '(' || DATA_LENGTH || ')'
                WHEN SUBSTR(DATA_TYPE, 1, 1) != 'N' THEN '(' || DATA_LENGTH || ')'
            END) AS tipo
        FROM dba_tab_columns
        WHERE owner = v_nombre_usuario
        ORDER BY column_name;

    v_cursor_empleados SYS_REFCURSOR;
    v_cursor_sql VARCHAR2(500);

    v_min VARCHAR2(100);
    v_max VARCHAR2(100);

    v_excepcion_encontrada NUMBER(1) := 0;
BEGIN      
    DBMS_OUTPUT.PUT_LINE(RPAD('Column', 24) || 
                        RPAD('Type', 16) || 
                        RPAD('Table', 32) || 
                        RPAD('Values', 100));
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
    
    -- Recorre los resultados de "dba_tab_columns"
    FOR c_fila IN c_columnas LOOP
        v_excepcion_encontrada := 0;

        DECLARE
            TABLE_DOES_NOT_EXIST EXCEPTION;
                PRAGMA EXCEPTION_INIT(TABLE_DOES_NOT_EXIST, -00942);
        BEGIN
            -- Se crea un query dinamico que usa los valores obtenidos en el query anterior
            v_cursor_sql := 'SELECT TO_CHAR(MIN(' || c_fila.columna || ')) AS valorMinimo, TO_CHAR(MAX(' || c_fila.columna || ')) AS valorMaximo FROM ' || c_fila.tabla;

            OPEN v_cursor_empleados FOR v_cursor_sql;

            LOOP
                FETCH v_cursor_empleados INTO v_min, v_max;

                EXIT WHEN v_cursor_empleados%NOTFOUND;

                DBMS_OUTPUT.PUT_LINE(RPAD(c_fila.columna, 24) || 
                                    RPAD(c_fila.tipo, 16) || 
                                    RPAD(c_fila.tabla, 32) || 
                                    RPAD(v_min || '..' || v_max, 100));
            END LOOP;

            CLOSE v_cursor_empleados;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_excepcion_encontrada := 1;
            WHEN TABLE_DOES_NOT_EXIST THEN
                v_excepcion_encontrada := 1;
            WHEN OTHERS THEN
                v_excepcion_encontrada := 1;
        END;

        IF (v_excepcion_encontrada = 1) THEN
            DBMS_OUTPUT.PUT_LINE(RPAD(c_fila.columna, 24) || 
                                RPAD(c_fila.tipo, 16) || 
                                RPAD(c_fila.tabla, 32) || 
                                RPAD('-..-', 100));
        END IF;
    END LOOP;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
		DBMS_OUTPUT.PUT_LINE('-----------------------------------------------');
		DBMS_OUTPUT.PUT_LINE('No existe un usuario con el nombre ingresado: ' || v_nombre_usuario);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('-----------------------------------------------');
		DBMS_OUTPUT.PUT_LINE('Ha ocurrido un error durante la ejecucion del procedimiento');
END drDATA;
end DrBd;



/*-----------------Pruebas---------------------------*/
EXECUTE DrBd.drUSR('USER1');
EXECUTE DrBd.drFKS('USER1');
EXECUTE DrBd.drDATA('USER1');
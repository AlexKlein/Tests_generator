begin
    execute immediate('drop procedure check_dm_dwh');
exception
    when others then
        null;
end;
/
create or replace procedure check_dm_dwh
/******************************* ALFA HISTORY *******************************************\
Дата        Автор            ID       Описание
----------  ---------------  -------- ----------------------------------------------------
25.04.2018  Klein A.M.      [000000]  Создание процедуры генерации UAT для сравнения 
                                      сущностей с ядром.
\******************************* ALFA HISTORY *******************************************/
as
    vOpDay varchar2(128);   -- параметр даты операционного дня
    vSQL   varchar2(1024);  -- скрипт запроса
    vCols  varchar2(1024);  -- текст выбора колонок
    
    cursor cur_tab  -- курсор выборки нужных сущностей
    is
    select row_number ()
           over (partition by dummy
                 order by type,table_name)
           as rownumber,
           owner,
           table_name,
           full_name,
           type,
           column_list
    from  (select tab.owner,
                  tab.table_name,
                  tab.owner||'.'||tab.table_name  as full_name,
                  substr(tab.table_name,
                  instr(tab.table_name,'_',-1)+1) as type,
                  dummy                           as dummy,
                  listagg(col.column_name, ',')
                  within group (order by col.column_name) as column_list 
           from   all_tables tab
           left outer join all_tab_columns col
                        on tab.owner = col.owner and
                           tab.table_name = col.table_name
           left outer join dual rownumb 
                        on 1 = 1
           where  lower(tab.owner) = 'dwh'
           group by tab.owner,
                    tab.table_name,
                    tab.owner||'.'||tab.table_name,
                    substr(tab.table_name,
                    instr(tab.table_name,'_',-1)+1),
                    dummy)
    order by type,
             table_name;

    -- функция выбора параметра
    function f_find_param (p_param_name in varchar2) return varchar2
    is
        -- перевод в режим автономной транзакции
        pragma autonomous_transaction;
        
        v_out varchar2 (255);  -- значение параметра
    begin
        
        -- выбор параметра
        select param_value
        into   v_out
        from   t_params
        where  param_name = p_param_name;

        -- возврат значения параметра
        return v_out;
    end f_find_param;
    
begin

    -- формирование даты операционного дня
    -- vOpDay := 'to_date('''||f_find_param('OPERATION_DAY')||''',''dd.mm.yyyy'')';
    vOpDay := 'to_date(''*operation_day*'',''dd.mm.yyyy'')';
    
    delete from t_test
    where n_test > 300001;
    
    commit;
    
    -- выполняется проход по сущностям выборки
    for i in cur_tab loop
        -- очистка списка параметров
        vCols := null;
        
        -- разбор по типам сущностей
        if    lower(i.type) like '%dim' and
              lower(i.type) not like '%ldim' and
              lower(i.type) not like '%sdim' then
            
            -- проверка на существование deleted_flag
            if lower(i.column_list) like '%deleted_flag%' then
                vCols := vCols||chr(10)||'and deleted_flag = ''N''';
            end if;
            
            -- проверка на существование validto
            if lower(i.column_list) like '%validto%' then
                vCols := vCols||chr(10)||'and validto = date''5999-12-31''';
            end if;
            
            -- сравнение количества строк на ядре и на РБ
            vSQL := 'select '||chr(10)||
                    '(select count(1) '||chr(10)|| 
                    'from   '||i.full_name ||chr(10)|| 
                    'where   1 = 1 '||chr(10)|| 
                    '       '||vCols||') '||chr(10)||
                    '- '||chr(10)||
                    '(select count(1) '||chr(10)|| 
                    'from   '||i.full_name||'@zfsdwtst '||chr(10)||
                    'where   1 = 1 '||chr(10)|| 
                    '       '||vCols||') as kol '||chr(10)|| 
                    'from   dual';
            
            -- вставка новых проверок
            insert into t_test (project,
								owner,
								table_name,
								test_desc,
								emploees,
								n_test,
								sql_test_hash_value,
								test_sql_clob) values ('TST_ENV',
													   'TST_ENV',
													   i.table_name,
													   i.full_name,
													   'AUTO',
													   300001+i.rownumber,
													   null,
													   to_clob(vSQL));
            commit;
   
        elsif lower(i.type) like '%ldim' or 
              lower(i.type) like '%sdim' then
            
            -- проверка на существование deleted_flag
            if lower(i.column_list) like '%deleted_flag%' then
                vCols := vCols||chr(10)||'and deleted_flag = ''N''';
            end if;
            
            -- сравнение количества строк на ядре и на РБ
            vSQL := 'select '||chr(10)||
                    '(select count(1) '||chr(10)|| 
                    'from   '||i.full_name ||chr(10)|| 
                    'where   1 = 1 '||chr(10)|| 
                    '       '||vCols||') '||chr(10)||
                    '- '||chr(10)||
                    '(select count(1) '||chr(10)|| 
                    'from   '||i.full_name||'@zfsdwtst '||chr(10)||
                    'where   1 = 1 '||chr(10)|| 
                    '       '||vCols||') as kol '||chr(10)|| 
                    'from   dual';
            
            -- вставка новых проверок
            insert into t_test (project,
                                owner,
                                table_name,
                                test_desc,
                                emploees,
                                n_test,
                                sql_test_hash_value,
                                test_sql_clob) values ('TST_ENV',
                                                       'TST_ENV',
                                                       i.table_name,
                                                       i.full_name,
                                                       'AUTO',
                                                       300001+i.rownumber,
                                                       null,
                                                       to_clob(vSQL));
            commit;
        
        elsif lower(i.type) like '%hist' then

            -- проверка на существование deleted_flag
            if lower(i.column_list) like '%deleted_flag%' then
                vCols := vCols||chr(10)||'and deleted_flag = ''N''';
            end if;
            
            -- проверка на существование validto
            if lower(i.column_list) like '%validto%' then
                vCols := vCols||chr(10)||'and validto = date''5999-12-31''';
            end if;
            
            -- проверка на существование effective_to
            if lower(i.column_list) like '%effective_to%' then
                vCols := vCols||chr(10)||'and effective_to >= '||vOpDay||'-100';
            end if;

            -- сравнение количества строк на ядре и на РБ
            vSQL := 'select '||chr(10)||
                    '(select count(1) '||chr(10)|| 
                    'from   '||i.full_name ||chr(10)|| 
                    'where   1 = 1 '||chr(10)|| 
                    '       '||vCols||') '||chr(10)||
                    '- '||chr(10)||
                    '(select count(1) '||chr(10)|| 
                    'from   '||i.full_name||'@zfsdwtst '||chr(10)||
                    'where   1 = 1 '||chr(10)|| 
                    '       '||vCols||') as kol '||chr(10)|| 
                    'from   dual';
            
            -- вставка новых проверок
            insert into t_test (project,
                                owner,
                                table_name,
                                test_desc,
                                emploees,
                                n_test,
                                sql_test_hash_value,
                                test_sql_clob) values ('TST_ENV',
                                                       'TST_ENV',
                                                       i.table_name,
                                                       i.full_name,
                                                       'AUTO',
                                                       300001+i.rownumber,
                                                       null,
                                                       to_clob(vSQL));
            commit;
        
        elsif lower(i.type) like '%stat' or 
              lower(i.type) like '%tran' then
            
            -- проверка на существование deleted_flag
            if lower(i.column_list) like '%deleted_flag%' then
                vCols := vCols||chr(10)||'and deleted_flag = ''N''';
            end if;
            
            -- проверка на существование validto
            if lower(i.column_list) like '%validto%' then
                vCols := vCols||chr(10)||'and validto = date''5999-12-31''';
            end if;
            
            -- проверка на существование value_day
            if lower(i.column_list) like '%value_day%' then
                vCols := vCols||chr(10)||'and value_day >= '||vOpDay||'-30';
            end if;
            
            -- сравнение количества строк на ядре и на РБ
            vSQL := 'select '||chr(10)||
                    '(select count(1) '||chr(10)|| 
                    'from   '||i.full_name ||chr(10)|| 
                    'where   1 = 1 '||chr(10)|| 
                    '       '||vCols||') '||chr(10)||
                    '- '||chr(10)||
                    '(select count(1) '||chr(10)|| 
                    'from   '||i.full_name||'@zfsdwtst '||chr(10)||
                    'where   1 = 1 '||chr(10)|| 
                    '       '||vCols||') as kol '||chr(10)|| 
                    'from   dual';
            
            -- вставка новых проверок
            insert into t_test (project,
                                owner,
                                table_name,
                                test_desc,
                                emploees,
                                n_test,
                                sql_test_hash_value,
                                test_sql_clob) values ('TST_ENV',
                                                       'TST_ENV',
                                                       i.table_name,
                                                       i.full_name,
                                                       'AUTO',
                                                       300001+i.rownumber,
                                                       null,
                                                       to_clob(vSQL));
            commit;
            
        end if;
        
    end loop;
    
end;
/

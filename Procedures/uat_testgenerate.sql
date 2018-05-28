begin
    execute immediate('drop procedure uat_testuser.uat_testgenerate');
exception
    when others then
        null;
end;
/
create or replace procedure uat_testuser.uat_testgenerate
/******************************* ALFA HISTORY *******************************************\
Дата        Автор            ID       Описание
----------  ---------------  -------- ----------------------------------------------------
24.05.2018  Клейн А.М.      [000000]  Создание процедуры.
\******************************* ALFA HISTORY *******************************************/
as
    -- сбор списка объекктов последней поставки
    cursor cToObjectList 
        is
    select distinct tst.owner,
           tst.table_name,
           case
               when tbl.owner is not null then
                   'table'
               else
                   'view/synonym'
           end as obj_type,
           max(release_number) as release_number
    from   uat_testuser.uat_test_table_release tst
    left outer join all_tables tbl
                 on tst.owner      = tbl.owner and
                    tst.table_name = tbl.table_name
    group by tst.owner,
             tst.table_name,
             case
                 when tbl.owner is not null then
                     'table'
                 else
                     'view/synonym'
             end
    order by case
                 when tbl.owner is not null then
                     'table'
                 else
                     'view/synonym'
             end,
             tst.owner,
             tst.table_name;

    vSQL varchar2(4000);  -- подготавливаемый SQL скрипт проверки
    
begin

    -- очистка предыдущей генерации
     delete from uat_testuser.uat_test_standard
     where n_test in (41, 42, 43);
     
     commit;

    -- выбор объектов и создание для них скриптов
    for r in cToObjectList loop
    
        -- первоначальная очистка скрипта
        vSQL := null;
        
        -- сбор скрипта проверки соответствия структуры и ЛМ
        vSQL := 'select src.column_name   as column_name_real, '  ||chr(10)|| 
                '       trg.column_name   as column_name_lm, '    ||chr(10)|| 
                '       src.data_type_all as data_type_all_real, '||chr(10)|| 
                '       trg.data_type     as data_type_lm, '      ||chr(10)|| 
                '       src.nullable      as nullable_real, '     ||chr(10)|| 
                '       trg.nullable      as nullable_lm, '       ||chr(10)|| 
                '       src.comments      as comments_real, '     ||chr(10)|| 
                '       trg.comments      as comments_lm '        ||chr(10)|| 
                'from  (select col.column_name, ' ||chr(10)|| 
                '              case '             ||chr(10)|| 
                '                  when data_type in (''NUMBER'',''DATE'') then '||chr(10)||  
                '                      data_type '||chr(10)|| 
                '                  else '         ||chr(10)|| 
                '                      data_type||''(''||data_length||'')'' '||chr(10)|| 
                '              end as  data_type_all, '||chr(10)||
                '              nullable, '             ||chr(10)||
                '              com.comments '          ||chr(10)||
                '       from   all_tab_columns col '   ||chr(10)||
                '       left outer join sys.all_col_comments com '              ||chr(10)||
                '                    on (col.table_name = com.table_name and '  ||chr(10)|| 
                '                        col.column_name = com.column_name) '   ||chr(10)||
                '       where  upper(col.owner) = '''||r.owner||''' and '           ||chr(10)||
                '              upper(col.table_name) = '''||r.table_name||''') src '||chr(10)|| 
                '       full outer join (select table_name, ' ||chr(10)||
                '                               column_name, '||chr(10)||
                '                               data_type, '  ||chr(10)||
                '                               nullable, '   ||chr(10)||
                '                               comments '    ||chr(10)||
                '                        from   model.logical_model@model '          ||chr(10)||  
                '                        where  table_name = '''||r.table_name||''' and '||chr(10)||
                '                               db_schema = '''||r.owner||''') trg '     ||chr(10)||
                '                    on  src.column_name = trg.column_name '         ||chr(10)||
                'where  decode(src.column_name,   trg.column_name, 0, 1) = 1 or '    ||chr(10)||
                '       decode(src.data_type_all, trg.data_type,   0, 1) = 1 or '    ||chr(10)||
                '       decode(src.nullable,      trg.nullable,    0, 1) = 1 or '    ||chr(10)||
                '       decode(src.comments,      trg.comments,    0, 1) = 1';

        -- вставка в стандартные тесты
        insert into uat_testuser.uat_test_standard (table_name,
                                                    test_desc,
                                                    test_sql,
                                                    parent_table_name,
                                                    n_test,
                                                    column_name) values (r.table_name,
                                                                         'Проверка на совпадение сущности с ЛМ',
                                                                         vSQL,
                                                                         null,
                                                                         41,
                                                                         null);
        
        commit;
        
        -- проверка на тип объекта, т.к. индексы есть только у таблиц
        if r.obj_type = 'table' then
            
            -- сбор скрипта проверки соответствия индекса и ЛМ
            vSQL := 'select src.index_name, '   ||chr(10)||
                    '       src.column_name, '  ||chr(10)||
                    '       trg.column_name '   ||chr(10)||
                    'from  (select index_name, '||chr(10)||
                    '              column_name '||chr(10)||
                    '       from   sys.dba_ind_columns '                     ||chr(10)||
                    '       where  table_owner = '''||r.owner||''' and '         ||chr(10)||
                    '              table_name  = '''||r.table_name||''' and '    ||chr(10)|| 
                    '              index_name  = '''||r.table_name||'_PK'') src '||chr(10)||
                    'full outer join (select table_name, ' ||chr(10)||
                    '                        column_name, '||chr(10)||
                    '                        pk '          ||chr(10)||
                    '                 from   model.logical_model@model '          ||chr(10)||   
                    '                 where  table_name = '''||r.table_name||''' and '||chr(10)|| 
                    '                        db_schema  = '''||r.owner||''' and '           ||chr(10)||
                    '                        pk = ''Y'') trg '                    ||chr(10)||
                    '             on src.column_name = trg.column_name '          ||chr(10)||
                    'where decode(src.column_name, trg.column_name, 0, 1) = 1';

            -- вставка в стандартные тесты
            insert into uat_testuser.uat_test_standard (table_name,
                                                        test_desc,
                                                        test_sql,
                                                        parent_table_name,
                                                        n_test,
                                                        column_name) values (r.table_name,
                                                                             'Проверка на совпадение индекса с ЛМ',
                                                                             vSQL,
                                                                             null,
                                                                             42,
                                                                             null);
                                                                             
            commit;

            -- сбор скрипта проверки уникальности индекса
            vSQL := 'select uniqueness '  ||chr(10)||
                     'from   all_indexes '||chr(10)||
                     'where  table_owner = '''||r.owner||''' and '     ||chr(10)|| 
                     '       table_name  = '''||r.table_name||''' and '||chr(10)||
                     '       index_name  = '''||r.table_name||'_PK'' ' ||chr(10)||
                     'minus '||chr(10)||
                     'select ''UNIQUE'' as uniqueness '||chr(10)||
                     'from   dual';

            -- вставка в стандартные тесты
            insert into uat_testuser.uat_test_standard (table_name,
                                                        test_desc,
                                                        test_sql,
                                                        parent_table_name,
                                                        n_test,
                                                        column_name) values (r.table_name,
                                                                             'Проверка на уникальность PK индекса',
                                                                             vSQL,
                                                                             null,
                                                                             43,
                                                                             null);
                                                                             
            commit;
        
        end if;
        
    end loop;
    
exception
    when others then
        dbms_output.put_line('Ошибка '  ||chr(10)||
        dbms_utility.format_error_stack||
        dbms_utility.format_error_backtrace());
        commit;

end;
/
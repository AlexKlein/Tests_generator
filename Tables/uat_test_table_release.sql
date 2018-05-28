declare
    object_not_found exception;
    pragma exception_init(object_not_found, -00942);
begin
    execute immediate ('drop table uat_testuser.uat_test_table_release');
exception
    when object_not_found then
        null;
    when others then
        dbms_output.put_line('Ошибка '||sqlerrm);
end;
/
create table uat_testuser.uat_test_table_release (release_number number,
                                                  owner          varchar(50),
                                                  table_name     varchar(50),
                                                  develop_number number,
                                                  develop_type   varchar(2),
                                                  patch_number   varchar(50),
                                                  employee       varchar(255),
                                                  developer      varchar(255),
                                                  analyst        varchar(255),
                                                  project        varchar(255),
                                                  date_release   varchar(255));
                                                
comment on table uat_testuser.uat_test_table_release is 'Список таблиц для тестирования в рамках поставки';

comment on column uat_testuser.uat_test_table_release.release_number is 'Номер поставки';
comment on column uat_testuser.uat_test_table_release.owner          is 'Схема';
comment on column uat_testuser.uat_test_table_release.table_name     is 'Таблица';
comment on column uat_testuser.uat_test_table_release.develop_number is 'Номер доработки';
comment on column uat_testuser.uat_test_table_release.develop_type   is 'Тип доработки (DF или CR)';
comment on column uat_testuser.uat_test_table_release.patch_number   is 'Номер патча';
comment on column uat_testuser.uat_test_table_release.employee       is 'Тестировщик';
comment on column uat_testuser.uat_test_table_release.developer      is 'Разработчик';
comment on column uat_testuser.uat_test_table_release.analyst        is 'Аналитик';
comment on column uat_testuser.uat_test_table_release.project        is 'Докуменатция';
comment on column uat_testuser.uat_test_table_release.date_release   is 'Дата релиза';
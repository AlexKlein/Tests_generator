declare
    object_not_found exception;
    pragma exception_init(object_not_found, -00942);
begin
    execute immediate ('drop table uat_testuser.uat_test_table_release');
exception
    when object_not_found then
        null;
    when others then
        dbms_output.put_line('������ '||sqlerrm);
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
                                                
comment on table uat_testuser.uat_test_table_release is '������ ������ ��� ������������ � ������ ��������';

comment on column uat_testuser.uat_test_table_release.release_number is '����� ��������';
comment on column uat_testuser.uat_test_table_release.owner          is '�����';
comment on column uat_testuser.uat_test_table_release.table_name     is '�������';
comment on column uat_testuser.uat_test_table_release.develop_number is '����� ���������';
comment on column uat_testuser.uat_test_table_release.develop_type   is '��� ��������� (DF ��� CR)';
comment on column uat_testuser.uat_test_table_release.patch_number   is '����� �����';
comment on column uat_testuser.uat_test_table_release.employee       is '�����������';
comment on column uat_testuser.uat_test_table_release.developer      is '�����������';
comment on column uat_testuser.uat_test_table_release.analyst        is '��������';
comment on column uat_testuser.uat_test_table_release.project        is '������������';
comment on column uat_testuser.uat_test_table_release.date_release   is '���� ������';
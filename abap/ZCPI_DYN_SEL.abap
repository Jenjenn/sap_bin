*&---------------------------------------------------------------------*
*& Report ZCPI_DYN_SEL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZCPI_DYN_SEL.

data: lt1 type table of T100 with header line,
      lwa like line of lt1,
      ls_table_name type string,
      ls_where_clause type string.

data: lo_rt type ref to if_abap_runtime,
      lv_start type i, lv_end type i,
      t1 type i, t2 type i, t3 type i, t4 type i.


ls_table_name = 'T100'.
ls_where_clause = 'SPRSL = lwa-SPRSL AND ARBGB = lwa-ARBGB AND MSGNR = lwa-MSGNR'.

"get data to select with
select * from T100 up to 1 rows into corresponding fields of table lt1.

move-corresponding lt1 to lwa.

"Test non-dynamic selects
lo_rt = cl_abap_runtime=>create_hr_timer( ).
lv_start = lo_rt->get_runtime( ).

do 10000 times.
  select * from T100 into table lt1 bypassing buffer where SPRSL = lwa-SPRSL AND ARBGB = lwa-ARBGB AND MSGNR = lwa-MSGNR.
enddo.

lv_end = lo_rt->get_runtime( ).
t1 = lv_end - lv_start.


"Test sql with 1 dynamic clause
lo_rt = cl_abap_runtime=>create_hr_timer( ).
lv_start = lo_rt->get_runtime( ).

do 10000 times.
  select * from (ls_table_name) into table lt1 bypassing buffer where SPRSL = lwa-SPRSL AND ARBGB = lwa-ARBGB AND MSGNR = lwa-MSGNR.
enddo.

lv_end = lo_rt->get_runtime( ).
t2 = lv_end - lv_start.


"Test sql with 2 dynamic clauses
lo_rt = cl_abap_runtime=>create_hr_timer( ).
lv_start = lo_rt->get_runtime( ).

do 10000 times.
  select * from (ls_table_name) into table lt1 bypassing buffer where (ls_where_clause).
enddo.

lv_end = lo_rt->get_runtime( ).
t3 = lv_end - lv_start.



write / 'non-dynamic selects      : '.
write t1.
write / 'dynamic selects, 1 part  : '.
write t2.
write / 'dynamic selects, 2 parts : '.
write t3.
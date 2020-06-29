*&---------------------------------------------------------------------*
*& Report  ZGENCSTACK
*&
*& Author : I844387
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT zgencstack.

DATA: lo_worker_info TYPE REF TO cl_worker_info.
DATA: lv_wp_index TYPE int4.

DATA: lv_delay_ms TYPE i.
DATA: lv_duration_sec TYPE i.

DATA: lv_time_start TYPE timestamp.
DATA: lv_time_now TYPE timestamp.

DATA: lv_delay_fsec TYPE decfloat16.


PARAMETER pwpindex TYPE i DEFAULT 0.
PARAMETER pdur_sec TYPE i DEFAULT 10.
PARAMETER pdelayms TYPE i DEFAULT 200.


INITIALIZATION.

PERFORM set_texts.


START-OF-SELECTION.

lv_wp_index = pwpindex.
lv_delay_ms = pdelayms.
lv_duration_sec = pdur_sec.

"create the worker info object which use to call method write_worker_stack
TRY.
  CREATE OBJECT lo_worker_info
    EXPORTING
      index = lv_wp_index.
CATCH cx_root. "cx_ssi_no_auth.
  MESSAGE 'Failed to create worker object' TYPE 'E'.
ENDTRY.

lv_delay_fsec = lv_delay_ms / 1000.

"get the current UTC timestamp so we know when to stop
TRY.
cl_abap_tstmp=>systemtstmp_syst2utc(
  EXPORTING
    syst_date = sy-datum
    syst_time = sy-uzeit
  IMPORTING
    utc_tstmp = lv_time_start
).
CATCH cx_root.
  MESSAGE 'Unable to determine start time' TYPE 'E'.
ENDTRY.


"main loop
DO.

  TRY.
    CALL METHOD lo_worker_info->write_worker_stack( ).
    CATCH cx_root.
      MESSAGE 'Unable to write worker stack' TYPE 'W'.
  ENDTRY.

  WAIT UP TO lv_delay_fsec SECONDS.

  "check the current time
  TRY.
    cl_abap_tstmp=>systemtstmp_syst2utc(
      EXPORTING
        syst_date = sy-datum
        syst_time = sy-uzeit
      IMPORTING
        utc_tstmp = lv_time_now
  ).
  CATCH cx_root.
    MESSAGE 'Unable to determine time' TYPE 'E'.
  ENDTRY.

  "if lv_duration_sec seconds have passed, exit
  IF ( cl_abap_tstmp=>subtract(
      tstmp1 = lv_time_now
      tstmp2 = lv_time_start
    ) > lv_duration_sec ).
    EXIT.
  ENDIF.

ENDDO.



FORM set_texts.

  DATA lstxt TYPE TABLE OF rsseltexts WITH HEADER LINE.

  lstxt-name = 'PWPINDEX'.
  lstxt-kind = 'P'.
  lstxt-text = 'WP Index'.
  APPEND lstxt.

  lstxt-name = 'PDUR_SEC'.
  lstxt-kind = 'P'.
  lstxt-text = 'Duration to collect stacks (s)'.
  APPEND lstxt.

  lstxt-name = 'PDELAYMS'.
  lstxt-kind = 'P'.
  lstxt-text = 'Time between stack traces (ms)'.
  APPEND lstxt.


  CALL FUNCTION 'SELECTION_TEXTS_MODIFY'
    EXPORTING
      program = sy-repid
    TABLES
      seltexts = lstxt.

ENDFORM. "set_texts
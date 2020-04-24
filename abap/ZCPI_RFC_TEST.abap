*&---------------------------------------------------------------------*
*& Report  ZCPI_RFC_TEST
*&
*&---------------------------------------------------------------------*
*& This report can be copy+pasted into a system, however, ensure
*& that the following function modules are active on the system
*& that corresponds to the RFC destination:
*& RFC_PING "this should always exist on any system
*& Z_CPI_WORK_FLOPS
*&
*&---------------------------------------------------------------------*
REPORT ZCPI_RFC_TEST.

DATA: goutgoing_rfcs type i VALUE 0,
      gincoming_rfcs type i VALUE 0,
      gtname_base type c LENGTH 12,
      gtname_suf type c LENGTH 4,
      gtname type c LENGTH 16,
      gfn type c LENGTH 30,
      gtdelay type i VALUE 100.

DATA: gucomm_ex type TABLE OF sy-ucomm.

DATA: inputreq type c length 30.

TABLES: sscrfields.

SELECTION-SCREEN BEGIN OF BLOCK fmodule WITH FRAME TITLE fm_title.

  PARAMETER pwm_ping RADIOBUTTON GROUP fm DEFAULT 'X' USER-COMMAND RBFM.
  PARAMETER pwm_wait RADIOBUTTON GROUP fm.
  PARAMETER pwm_sort RADIOBUTTON GROUP fm MODIF ID NYI.
  PARAMETER pwm_flop RADIOBUTTON GROUP fm.

  PARAMETER pw_secs type i DEFAULT 30 MODIF ID DUR. "number of seconds to work per task

SELECTION-SCREEN END OF BLOCK fmodule.

SELECTION-SCREEN BEGIN OF BLOCK ccount WITH FRAME TITLE cc_title.

  PARAMETER pt_count type i DEFAULT 1. "number of tasks to execute
  PARAMETER pn_luw type i DEFAULT 1. "number of LUWs

SELECTION-SCREEN END OF BLOCK ccount.


SELECTION-SCREEN BEGIN OF BLOCK rfctype WITH FRAME TITLE rfc_titl.

  PARAMETER p_dest type C length 20 DEFAULT 'NONE'.

"I'm not doing anything with this user command but it triggers the
"selection-screen output event *shrug*
  PARAMETER prfc_syn RADIOBUTTON GROUP rfc DEFAULT 'X' USER-COMMAND RFCT.
  PARAMETER prfc_asy RADIOBUTTON GROUP rfc.
  PARAMETER prfc_tra RADIOBUTTON GROUP rfc.

  PARAMETER prfc_ut AS CHECKBOX DEFAULT '' MODIF ID UT.
  PARAMETER prfc_su AS CHECKBOX DEFAULT '' USER-COMMAND RFCT MODIF ID SU.

SELECTION-SCREEN END OF BLOCK rfctype.

SELECTION-SCREEN PUSHBUTTON 1(40) butkeept USER-COMMAND BKT MODIF ID NYI.
* not working right now "hmmm..."
* SELECTION-SCREEN PUSHBUTTON /1(40) butcommw USER-COMMAND BCW.

"define the help dialog box
SELECTION-SCREEN BEGIN OF SCREEN 100 TITLE helpti as window.
  SELECTION-SCREEN COMMENT /1(80) helphead Modif id HL1.
  SELECTION-SCREEN COMMENT /1(80) helpl1 Modif id HL1.
  SELECTION-SCREEN COMMENT /1(80) helpl2 Modif id HL2.
SELECTION-SCREEN END OF SCREEN 100.

"set the help request for each field
AT SELECTION-SCREEN on HELP-REQUEST FOR pwm_ping.
  helphead = 'FM: RFC_PING'.
  helpl1 = 'RFC_PING contains no code and is only meant to test the RFC framework'.
  helpl2 = 'This FM causes no delay should complete almost instantly'.
  call SELECTION-SCREEN 100 STARTING AT 25 5.

AT SELECTION-SCREEN on HELP-REQUEST FOR pwm_wait.
  helphead = 'FM: Z_CPI_WORK_WAIT'.
  helpl1 = 'Creates a delay by using a "WAIT UP TO n SECONDS." statement'.
  helpl2 = ' '.
  call SELECTION-SCREEN 100 STARTING AT 25 5.

AT SELECTION-SCREEN on HELP-REQUEST FOR pwm_sort.
  helphead = 'FM: Z_CPI_SORT_TABLE'.
  helpl1 = 'Will select entries from a DB table into an internal table then repeatedly'.
  helpl2 = 'sort the table on two columns until the specified duration is reached'.
  call SELECTION-SCREEN 100 STARTING AT 25 5.

AT SELECTION-SCREEN on HELP-REQUEST FOR pwm_flop.
  helphead = 'FM: Z_CPI_WORK_FLOPS'.
  helpl1 = 'Will execute an arbitrary number of floating point'.
  helpl2 = 'operations until the specified duration is reached'.
  call SELECTION-SCREEN 100 STARTING AT 25 5.

AT SELECTION-SCREEN on HELP-REQUEST FOR pw_secs.
  helphead = 'Duration of work'.
  helpl1 = 'The desired duration for each FM call. I.e. the amount of time spent in the'.
  helpl2 = 'RFC server step for each call'.
  call SELECTION-SCREEN 100 STARTING AT 25 5.

AT SELECTION-SCREEN on HELP-REQUEST FOR pt_count.
  helphead = 'Call count'.
  helpl1 = 'The total number of times to call the selected FM'.
  helpl2 = '(total number of function calls)'.
  call SELECTION-SCREEN 100 STARTING AT 25 5.

AT SELECTION-SCREEN on HELP-REQUEST FOR pn_luw.
  helphead = 'Number of LUWs'.
  helpl1 = 'The number of LUWs to create & execute. Acts as a multiplier.'.
  helpl2 = 'If Call count = 2 and number of LUWs = 2 there will be 4 calls in total.'.
  call SELECTION-SCREEN 100 STARTING AT 25 5.

AT SELECTION-SCREEN on HELP-REQUEST FOR p_dest.
  helphead = 'RFC Destination'.
  helpl1 = 'The RFC destination to send the RFC requests to. Destinations are listed'.
  helpl2 = 'in SM59. The default is NONE which sends the request to the local gateway.'.
  call SELECTION-SCREEN 100 STARTING AT 25 5.

AT SELECTION-SCREEN on HELP-REQUEST FOR prfc_syn.
  helphead = 'Synchronous'.
  helpl1 = 'Call the FM synchronously. When this option is chosen'.
  helpl2 = 'each call is executed in serial.'.
  call SELECTION-SCREEN 100 STARTING AT 25 5.

AT SELECTION-SCREEN on HELP-REQUEST FOR prfc_asy.
  helphead = 'Asynchronous'.
  helpl1 = 'Call the FM asynchronously. Serial/Parallel execution depends on'.
  helpl2 = 'whether or not each call is executed in the same or unique task IDs.'.
  call SELECTION-SCREEN 100 STARTING AT 25 5.

AT SELECTION-SCREEN on HELP-REQUEST FOR prfc_tra.
  helphead = 'Transactional'.
  helpl1 = 'Call the FM transactionally. Calls will be written into the tRFC'.
  helpl2 = 'admin tables and executed later. Parallel execution depends on separate units.'.
  call SELECTION-SCREEN 100 STARTING AT 25 5.

AT SELECTION-SCREEN on HELP-REQUEST FOR prfc_ut.
  helphead = 'Exec aRFCs in unique task IDs'.
  helpl1 = 'If left unchecked, each FM call is executed serially in the same task ID.'.
  helpl2 = 'If checked, each call is executed in parallel in separate task IDs.'.
  call SELECTION-SCREEN 100 STARTING AT 25 5.

AT SELECTION-SCREEN on HELP-REQUEST FOR prfc_su.
  helphead = 'Exec tRFCs in separate units'.
  helpl1 = 'If left unchecked, each FM call is executed serially in the same unit.'.
  helpl2 = 'If checked, calls are executed in parallel in separate units.'.
  call SELECTION-SCREEN 100 STARTING AT 25 5.




"called once during the report before the initial PBO
INITIALIZATION.
"initialize the "text symbols" and selection texts
"we do it this way to avoid the text elements area
"so this report can easily be copy+pasted into another system
  fm_title = 'Function module to call'.
  cc_title = 'Times to call FM'.
  rfc_titl = 'RFC type'.
  butkeept = 'Exec w/o commit (keep transaction)'.
*  butcommw = 'Commit & new transaction (no exec)'.
  inputreq = 'Input required'.

  PERFORM set_selection_texts.


  helpti = 'Help'.
  "remove buttons from the called selection screen
  APPEND: 'CRET' to gucomm_ex, "remove execution
          'NONE' to gucomm_ex, "remove check
          'SPOS' to gucomm_ex. "remove save

"PBO event for selection screens
AT SELECTION-SCREEN OUTPUT.

  case sy-dynnr.
    when '1000'. "main screen
      LOOP AT SCREEN. "show/hide elements based on selection

        case screen-group1.

          when 'NYI'. "hide the parts of the GUI that are not yet implemented
            SCREEN-active = 0.

          when 'DUR'. "Duration of work
            if pwm_ping = 'X'. screen-active = 0.
            else. screen-active = 1.
            endif.

          when 'UT'. "exec arfcs in unique task
            IF prfc_asy = 'X'. SCREEN-active = 1.
            ELSE. SCREEN-active = 0.
            ENDIF.

          when 'SU'. "exec trfcs in separate units
            IF prfc_tra = 'X'. SCREEN-active = 1.
            ELSE. SCREEN-active = 0.
            ENDIF.

        endcase.
        MODIFY SCREEN.
      ENDLOOP.

    when '0100'. "help dialog
      CALL FUNCTION 'RS_SET_SELSCREEN_STATUS'
        EXPORTING p_status = space
        TABLES p_exclude = gucomm_ex.

  endcase.

"PAI event for selection screens
"validation of input
AT SELECTION-SCREEN.

  IF pw_secs is INITIAL.
    SET CURSOR FIELD 'PW_SECS'.
    MESSAGE inputreq type 'E'.
  ENDIF.

  IF pt_count is INITIAL.
    SET CURSOR FIELD 'PT_COUNT'.
    MESSAGE inputreq type 'E'.
  ENDIF.

  CASE sscrfields.
    WHEN 'BKT'.
      perform main.
    WHEN 'BCW'.
      COMMIT WORK AND WAIT.
  ENDCASE.

"execution of program starts here
START-OF-SELECTION.

perform main.

WRITE: 'done'.

FORM main.

  IF     pwm_ping = 'X'. gfn = 'RFC_PING'.
  ELSEIF pwm_wait = 'X'. gfn = 'Z_CPI_WORK_WAIT'.
  ELSEIF pwm_sort = 'X'. gfn = 'Z_CPI_SORT_TABLE'.
  ELSEIF pwm_flop = 'X'. gfn = 'Z_CPI_WORK_FLOPS'.
  ENDIF.

do pn_luw times.

  IF prfc_syn = 'X'.
    perform exec_sync using gfn pw_secs p_dest.
  ELSEIF prfc_asy = 'X'.
    perform exec_async using gfn pw_secs p_dest.
  ELSEIF prfc_tra = 'X' and prfc_su = ''.
    perform exec_transactional using gfn pw_secs p_dest pn_luw.
  ELSEIF prfc_tra = 'X'.
    perform exec_transactional_su using gfn pw_secs p_dest.
  ENDIF.

commit work.

enddo.

ENDFORM. "main


FORM exec_sync using lfn type c lt type i ldest type c.

  do pt_count times.
    PERFORM delay_by_work USING gtdelay.

    CALL FUNCTION lfn DESTINATION ldest
      EXPORTING i_time = lt.

  enddo.

ENDFORM.  "exec_sync


FORM exec_async using lfn type c lt type i ldest type c.

  gtname_base = sy-uname.
  gtname = gtname_base.

  do pt_count times.
    perform delay_by_work USING gtdelay.

    ADD 1 to goutgoing_rfcs.

    IF prfc_ut = 'X'. "execute in parallel unique tasks

      "create the taskname
      UNPACK sy-index to gtname_suf.
      CONCATENATE gtname_base gtname_suf INTO gtname.

    ENDIF.

    CALL FUNCTION lfn STARTING NEW TASK gtname
      DESTINATION ldest PERFORMING call_done ON END OF TASK
      EXPORTING i_time = lt.

    IF prfc_ut = ''.
     wait until goutgoing_rfcs = gincoming_rfcs.
    ENDIF.

  enddo.

  IF prfc_ut = 'X'.
    WAIT UNTIL goutgoing_rfcs = gincoming_rfcs.
  ENDIF.


ENDFORM. "exec_async


FORM exec_transactional using lfn type c lt type i ldest type c ln_luw type i.

  do pt_count times.

    perform delay_by_work USING gtdelay.

    CALL FUNCTION lfn IN BACKGROUND TASK
      DESTINATION ldest
      EXPORTING i_time = lt.

  enddo.

ENDFORM.


FORM exec_transactional_su using lfn type c lt type i ldest type c.

  do pt_count times.

      CALL FUNCTION lfn IN BACKGROUND TASK
        AS SEPARATE UNIT DESTINATION ldest
        EXPORTING i_time = lt.

  enddo.

ENDFORM.


"callback for asynchronously executed tasks
FORM call_done using taskname.
  ADD 1 to gincoming_rfcs.
ENDFORM.


"creates a programmatic delay by executing arbitrary flops
FORM delay_by_work USING i_loops TYPE i.

  DATA: f1 type f,
        f2 type f,
        f3 type f.

  " 1 iteration = ~ 6.8ms
  DO i_loops TIMES.
    perform get_random_safe using 7 7493 changing f1.
    perform get_random_safe using 23 4847 changing f2.
    perform get_random_safe using 65 283 changing f3.

    do 10000 times.
      f1 = SQRT( f1 ).
      f2 = SQRT( f2 ).
      f3 = SQRT( f3 ).

      f1 = f1 * f2 * ( sin( f3 ) + 1 ).
      f2 = f2 * 4 + f1.
      f3 = f3 * f2 * f1.
    enddo.

  ENDDO.

ENDFORM. "delay_by_work

FORM get_random_safe using min type f max type f changing out type f.

"try random_f8
call function 'FUNCTION_EXISTS'
  EXPORTING FUNCNAME = 'RANDOM_F8'
  EXCEPTIONS FUNCTION_NOT_EXIST = 1.

if sy-subrc = 0.
  CALL FUNCTION 'RANDOM_F8'
  EXPORTING RND_MIN = min RND_MAX = max
  IMPORTING RND_VALUE = out.

  EXIT.
endif.

"try QF05_random
call function 'FUNCTION_EXISTS'
  EXPORTING FUNCNAME = 'QF05_RANDOM'
  EXCEPTIONS FUNCTION_NOT_EXIST = 1.

if sy-subrc = 0.
  CALL FUNCTION 'QF05_RANDOM'
  IMPORTING RAN_NUMBER = out.

  out = out * ( max - min ) + min.

  EXIT.
ENDIF.

endform. "form get_random_safe

FORM set_selection_texts.

  data lstxt type table of rsseltexts WITH HEADER LINE.

  lstxt-name = 'PN_LUW'.
  lstxt-kind = 'P'.
  lstxt-text = 'Number of LUWs'.
  append lstxt.

  lstxt-name = 'PRFC_ASY'.
  lstxt-kind = 'P'.
  lstxt-text = 'Asynchronous'.
  append lstxt.

  lstxt-name = 'PRFC_SU'.
  lstxt-kind = 'P'.
  lstxt-text = 'Exec tRFCs in separate units'.
  append lstxt.

  lstxt-name = 'PRFC_SYN'.
  lstxt-kind = 'P'.
  lstxt-text = 'Synchronous'.
  append lstxt.

  lstxt-name = 'PRFC_TRA'.
  lstxt-kind = 'P'.
  lstxt-text = 'Transactional'.
  append lstxt.

  lstxt-name = 'PRFC_UT'.
  lstxt-kind = 'P'.
  lstxt-text = 'Exec aRFCs in unique task IDs'.
  append lstxt.

  lstxt-name = 'PT_COUNT'.
  lstxt-kind = 'P'.
  lstxt-text = 'Call count'.
  append lstxt.

  lstxt-name = 'PWM_FLOP'.
  lstxt-kind = 'P'.
  lstxt-text = 'Z_CPI_WORK_FLOPS'.
  append lstxt.

  lstxt-name = 'PWM_PING'.
  lstxt-kind = 'P'.
  lstxt-text = 'RFC_PING'.
  append lstxt.

  lstxt-name = 'PWM_SORT'.
  lstxt-kind = 'P'.
  lstxt-text = 'Z_CPI_SORT_TABLE'.
  append lstxt.

  lstxt-name = 'PWM_WAIT'.
  lstxt-kind = 'P'.
  lstxt-text = 'Z_CPI_WAIT'.
  append lstxt.

  lstxt-name = 'PW_SECS'.
  lstxt-kind = 'P'.
  lstxt-text = 'Duration of work (s)'.
  append lstxt.

  lstxt-name = 'P_DEST'.
  lstxt-kind = 'P'.
  lstxt-text = 'RFC Destination'.
  append lstxt.

  CALL FUNCTION 'SELECTION_TEXTS_MODIFY'
    EXPORTING
      PROGRAM = sy-repid
    TABLES
      SELTEXTS = lstxt.


ENDFORM. "create_selection_texts
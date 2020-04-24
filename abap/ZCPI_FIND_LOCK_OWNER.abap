*Author : Jennifer Gray
*
*
REPORT ZCPI_FIND_LOCK_OWNER.

"======INCLUDES========
INCLUDE TSKHINCL.

"======TYPES==========

"type to store the user technical information
TYPES: BEGIN OF t_user_info_line.
  TYPES:  key   type c LENGTH 40,
          value type c LENGTH 80.
TYPES: END OF t_user_info_line.
TYPES: t_user_info_table TYPE TABLE OF t_user_info_line.

"LockOwnderID type -> lock owner IDs are 58 characters long
TYPES: t_loid type c length 58.


"=======CLASSES=======
CLASS lcl_tech_info DEFINITION.
  PUBLIC SECTION.

  DATA:
        user_info     TYPE t_user_info_table,
        alv_tech_info TYPE REF TO cl_salv_table.

  METHODS constructor
                    IMPORTING im_cont TYPE REF TO cl_gui_container
                              im_cont_name TYPE string.


  METHODS find_mode_of_lockowner
                    IMPORTING im_loid type t_loid
                    RAISING CX_SSI_NO_AUTH.

  METHODS is_found RETURNING VALUE(found) TYPE abap_bool.
  METHODS hide_other_modes.
  METHODS clear_filters.

  PRIVATE SECTION.

  DATA mode_of_owner type string VALUE IS INITIAL.

  METHODS set_columns_info.

ENDCLASS.


"=======GLOBALS=======
DATA: go_tech_info    TYPE REF TO lcl_tech_info,
      go_dock         TYPE REF TO cl_gui_docking_container,
      go_cont         TYPE REF TO cl_gui_container,
      g_last_lo       TYPE t_loid VALUE IS INITIAL,
      g_ucomm         TYPE sy-ucomm.


"=======SCREEN========
PARAMETERS P_LOID type t_loid VISIBLE LENGTH 58.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN PUSHBUTTON 1(10) sb_text USER-COMMAND SRCH.
SELECTION-SCREEN PUSHBUTTON 13(25) filt_txt USER-COMMAND FLTR MODIF ID FLT.

INITIALIZATION.


"PAI
AT SELECTION-SCREEN.
g_ucomm = sy-ucomm.
  if ( 1 = 1 ).endif.


"PBO
"all the work done here
AT SELECTION-SCREEN OUTPUT.

perform initialize.

"refresh if the user hit 'enter' or the search button
IF ( g_ucomm = 'SRCH' OR g_ucomm IS INITIAL ).
  go_tech_info->find_mode_of_lockowner( p_loid ).

ELSEIF ( g_ucomm = 'FLTR' ).
  go_tech_info->hide_other_modes( ).
ENDIF.


FORM initialize.

  STATICS l_first_time TYPE abap_bool VALUE 'X'.

  if ( l_first_time = abap_true ).

    l_first_time = abap_false.

    "format the selection screen
    PERFORM set_selection_texts.
    PERFORM set_text_elements.
    PERFORM adjust_gui_status.

    "create the docking object for the alv table
    CREATE OBJECT go_dock
      EXPORTING
        repid = sy-cprog
        dynnr = sy-dynnr
        ratio = 95  "between 5 and 95 or error
        side = cl_gui_docking_container=>dock_at_bottom
        name = 'DC_TECH_INFO'
        .
    IF sy-subrc <> 0.
      MESSAGE 'Error creating docking container "tech info"' TYPE '8'.
    ENDIF.

    go_cont ?= go_dock.

    "create our alv wrapper object
    CREATE OBJECT go_tech_info
      EXPORTING
        im_cont       = go_cont
        im_cont_name  = go_cont->get_name( )
        .

  endif.

ENDFORM. "initialize

FORM set_selection_texts.

  DATA lstxt TYPE TABLE OF rsseltexts WITH HEADER LINE.

  lstxt-name = 'P_LOID'.
  lstxt-kind = 'P'.
  lstxt-text = 'Lock Owner ID'.
  APPEND lstxt.

   CALL FUNCTION 'SELECTION_TEXTS_MODIFY'
    EXPORTING
      PROGRAM = sy-repid
    TABLES
      SELTEXTS = lstxt.


ENDFORM. "set_selection_texts

FORM adjust_gui_status.

  "now we want to disable the execute button to avoid clunky reinitializations
  "we just use "at selection-screen output" for our report
  DATA : lt_ucomms type table of sy-ucomm.
  append 'ONLI' to lt_ucomms.

  CALL FUNCTION 'RS_SET_SELSCREEN_STATUS'
    EXPORTING
      p_status = sy-pfkey
    TABLES
      p_exclude = lt_ucomms
      .

ENDFORM. "adjust_gui_status

FORM set_text_elements.
  sb_text = 'Search'.
  filt_txt = 'Hide unrelated modes'.
ENDFORM.



CLASS lcl_tech_info IMPLEMENTATION.

*  DATA:
*        user_info     TYPE t_user_info_table,
*        alv_tech_info TYPE REF TO cl_salv_table,
*        alv_col       TYPE REF TO cl_salv_column.
*
*  DATA mode_of_owner type string VALUE IS INITIAL.

  METHOD constructor.
                    "IMPORTING im_cont TYPE REF TO cl_gui_container
                              "im_cont_name TYPE string.



  TRY.

    CALL METHOD cl_salv_table=>factory
      EXPORTING
        list_display    = if_salv_c_bool_sap=>false
        r_container     = im_cont
        container_name  = im_cont_name
      IMPORTING
        r_salv_table    = alv_tech_info
      CHANGING
        t_table         = user_info.

    "add standard buttons
    alv_tech_info->get_functions( )->set_all( abap_true ).

    "set column info
    me->set_columns_info( ).

    CATCH cx_salv_msg cx_salv_not_found.
  ENDTRY.

  alv_tech_info->display( ).

  ENDMETHOD.

  METHOD find_mode_of_lockowner.
                    "IMPORTING im_loid type t_loid
                    "RAISING CX_SSI_NO_AUTH

    DATA:
          l_found           TYPE c VALUE abap_false,
          l_session_list    TYPE ssi_session_list,
          l_server_info     TYPE REF TO cl_server_info,
          l_tech_info       type t_user_info_table.

    FIELD-SYMBOLS: <session>    LIKE LINE OF l_session_list,
                   <tech_info>  LIKE LINE OF user_info.

    CLEAR mode_of_owner.

    IF ( im_loid IS NOT INITIAL ).

      "get session info for this server
      CREATE OBJECT l_server_info.
      l_session_list = l_server_info->get_session_list( ).

      "opcode_usr_info gets us all the mode information for one logon_hdl -> don't need the mode id
      SORT l_session_list BY logon_hdl.
      DELETE ADJACENT DUPLICATES FROM l_session_list COMPARING logon_hdl.

      "for each logon in the server
      LOOP at l_session_list ASSIGNING <session>.

        "export table
        REFRESH l_tech_info.

        CALL 'ThUsrInfo' ID 'OPCODE' FIELD opcode_usr_info "user's technical info per mode
          ID 'TID' FIELD <session>-logon_hdl               "logon handle
          ID 'WITH_APPL_INFO' FIELD 1                      "yes - ssi_bool
          ID 'TABLE' FIELD l_tech_info[].

        LOOP AT l_tech_info ASSIGNING <tech_info> WHERE key cs '.enq_info'.

          if <tech_info>-VALUE cs im_loid.

            "found the logon handle that owns the lock
            l_found = abap_true.

            "extract the index of the mode from the key
            SPLIT <tech_info>-KEY AT '.' INTO mode_of_owner DATA(dummy).

            exit.
          endif.

        ENDLOOP.

        "exit and keep the technical info
        IF ( l_found = abap_true ).EXIT.ENDIF.

      ENDLOOP.

    ENDIF.

    REFRESH user_info.

    IF ( l_found = abap_true ).
      user_info = l_tech_info.
    ELSE.

    ENDIF.

    "refresh our alv table with w/e our result was
    alv_tech_info->refresh( ).

  ENDMETHOD.

  METHOD is_found.
    found = abap_false.
    IF ( user_info IS NOT INITIAL ).
      found = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD hide_other_modes.
    DATA:
          l_filters     TYPE REF TO cl_salv_filters,
          l_filter      TYPE REF TO cl_salv_filter.

    FIELD-SYMBOLS <user_info> LIKE LINE OF user_info.

    IF ( user_info is not initial ).

      l_filters = alv_tech_info->get_filters( ).

      "clear existing filters
      l_filters->clear( ).

      "add the pattern filter for the "modeinfo[n]" string
      l_filter = l_filters->add_filter(
      columnname = 'KEY'
      option = 'CP'
      low = mode_of_owner && '*' ).

      "get the mode-independent/basic session info and add it as single entries
      LOOP AT user_info ASSIGNING <user_info> WHERE KEY NS 'modeinfo'.
        l_filter->add_selopt(
          option = 'EQ'
          low = CONV #( <user_info>-KEY ) ).
      ENDLOOP.

      alv_tech_info->refresh( ).

    endif.

  ENDMETHOD.

  METHOD clear_filters.

    alv_tech_info->get_filters( )->clear( ).

    alv_tech_info->refresh( ).

  ENDMETHOD.

  METHOD set_columns_info.

    DATA:
          lo_cols     TYPE REF TO cl_salv_columns,
          lo_col      TYPE REF TO cl_salv_column.

    lo_cols = alv_tech_info->get_columns( ).

    lo_col = lo_cols->get_column( 'KEY' ).
    lo_col->set_medium_text( 'Field' ).
    lo_col->set_output_length( 30 ).

    lo_col = lo_cols->get_column( 'VALUE' ).
    lo_col->set_medium_text( 'Value' ).
    lo_col->set_output_length( 60 ).

  ENDMETHOD.


ENDCLASS. 

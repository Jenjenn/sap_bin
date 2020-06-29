REPORT ZCPI_STAD.

selection-screen begin of block fb with frame title fb_title.
  parameters: pf01 as checkbox default ' ',
  pf02 as checkbox default ' ',
  pf03 as checkbox default ' ',
  pf04 as checkbox default ' '.
selection-screen end of block fb.

data: it_tab type table of T100,
      it_tab2 type table of T100,
      it_tab_line type T100.
FIELD-SYMBOLS: <it_tab> like line of it_tab.


form pf01.
  do 1111 times.
    select single * from T100 bypassing buffer into it_tab_line where
      SPRSL = it_tab_line-SPRSL and
      ARBGB = it_tab_line-ARBGB and
      MSGNR = it_tab_line-MSGNR.
  enddo.
endform.

form pf02.
  do 2222 times.
    select * from T100 bypassing buffer into table it_tab2 where
      SPRSL = it_tab_line-SPRSL and
      ARBGB = it_tab_line-ARBGB and
      MSGNR = it_tab_line-MSGNR.
  enddo.
endform.

form pf03.
  do 3333 times.
    select single * from T100 into it_tab_line where
      SPRSL = it_tab_line-SPRSL and
      ARBGB = it_tab_line-ARBGB and
      MSGNR = it_tab_line-MSGNR.
  enddo.
endform.

form pf04.
  do 4444 times.
    select * from T100 into table it_tab2 where
      SPRSL = it_tab_line-SPRSL and
      ARBGB = it_tab_line-ARBGB and
      MSGNR = it_tab_line-MSGNR.
  enddo.
endform.


FORM set_selection_texts.

  data lstxt type table of rsseltexts WITH HEADER LINE.

  lstxt-name = 'PF01'.
  lstxt-kind = 'P'.
  lstxt-text = '1111 dir reads from db'.
  append lstxt.

  lstxt-name = 'PF02'.
  lstxt-kind = 'P'.
  lstxt-text = '2222 seq reads from db'.
  append lstxt.

  lstxt-name = 'PF03'.
  lstxt-kind = 'P'.
  lstxt-text = '3333 dir reads from buffer'.
  append lstxt.

  lstxt-name = 'PF04'.
  lstxt-kind = 'P'.
  lstxt-text = '4444 seq reads from buffer'.
  append lstxt.


  CALL FUNCTION 'SELECTION_TEXTS_MODIFY'
    EXPORTING
      PROGRAM = sy-repid
    TABLES
      SELTEXTS = lstxt.


ENDFORM. "create_selection_texts




INITIALIZATION.

fb_title = 'subroutines'.

perform set_selection_texts.



start-of-selection.

select * up to 100 rows from T100 into table it_tab.
read table it_tab into it_tab_line index 1.

if pf01 = 'X'.
  perform pf01.
endif.

if pf02 = 'X'.
  perform pf02.
endif.

if pf03 = 'X'.
  perform pf03.
endif.

if pf04 = 'X'.
  perform pf04.
endif.
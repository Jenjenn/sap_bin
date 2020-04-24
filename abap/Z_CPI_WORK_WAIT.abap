FUNCTION Z_CPI_WORK_WAIT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_TIME) TYPE  I DEFAULT 10
*"----------------------------------------------------------------------

data ltr type i.
ltr = i_time.

"using alerts keeps the WP rolled in for observation.
"a regular abap wait would cause the WP to roll out.
"But alerts only funcitons in durations of 5 or less.
do.
  if ltr > 5.
    CALL 'ALERTS' ID 'ADMODE'         FIELD 50
                  ID 'STORAGE_OPCODE' FIELD 'SLEEP'
                  ID 'TIME'           FIELD 5.
    ltr = ltr - 5.
  else.
    CALL 'ALERTS' ID 'ADMODE'         FIELD 50
                  ID 'STORAGE_OPCODE' FIELD 'SLEEP'
                  ID 'TIME'           FIELD ltr.
    exit.
  endif.
enddo.


ENDFUNCTION.
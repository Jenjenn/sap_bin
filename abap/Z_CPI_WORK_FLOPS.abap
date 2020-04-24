FUNCTION Z_CPI_WORK_FLOPS.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_TIME) TYPE  I DEFAULT 30
*"----------------------------------------------------------------------

DATA: f1 type f,
      f2 type f,
      f3 type f.

DATA: l_runtime_i type i,
      l_runtime type i,
      l_runtime_s type i.

*obtain the initial runtime
GET RUN TIME FIELD l_runtime_i.

*obtain the current runtime
GET RUN TIME FIELD l_runtime.
*calculate the running time in seconds
l_runtime_s = ( l_runtime - l_runtime_i ) DIV 1000000.

*while the requested runtime is greater than the current running time...
WHILE i_time > l_runtime_s.

  "obtain three random floats
  perform get_random_safe using 7 7493 changing f1.
  perform get_random_safe using 23 4847 changing f2.
  perform get_random_safe using 65 283 changing f3.

  do 100000 times.
    "sq rt to restrict the values
    f1 = SQRT( f1 ).
    f2 = SQRT( f2 ).
    f3 = SQRT( f3 ).
    "Do some arbitrary math
    f1 = f1 * f2 * ( sin( f3 ) + 1 ).
    f2 = f2 * 4 + f1.
    f3 = f3 * f2 * f1.
  enddo.
  "obtain the current runtime
  GET RUN TIME FIELD l_runtime.
  "and calcuate the current running time for the next comparison
  l_runtime_s = ( l_runtime - l_runtime_i ) DIV 1000000.

ENDWHILE.

ENDFUNCTION.

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
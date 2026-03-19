      *> Template variable storage for template engine
       01 WS-TPL-VARS.
          05 WS-TPL-VAR-COUNT     PIC 99 VALUE 0.
          05 WS-TPL-VAR OCCURS 50 TIMES.
             10 WS-TPL-VAR-KEY    PIC X(30).
             10 WS-TPL-VAR-VALUE  PIC X(1024).

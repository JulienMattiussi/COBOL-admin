      *> HTML body buffer
       01 HTML-BODY            PIC X(32768).
       01 HTML-LEN             PIC 9(8) COMP-5 VALUE 0.
       01 WS-LEN-STR           PIC X(10).
      *> Page content buffer (for layout wrapping)
       01 WS-PAGE-CONTENT      PIC X(16384).
       01 WS-PAGE-LEN          PIC 9(8) COMP-5 VALUE 0.

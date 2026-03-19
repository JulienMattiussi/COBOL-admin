      *> HTTP request/response buffers
       01 REQUEST-BUFFER       PIC X(4096).
       01 RESPONSE-BUFFER      PIC X(65536).
       01 RESPONSE-LEN         PIC 9(8) COMP-5 VALUE 0.
       01 WS-CRLF              PIC XX VALUE X"0D0A".
       01 WS-REQUEST-COUNT     PIC 9(8) VALUE 0.

      *> Request parsing
       01 WS-REQUEST-METHOD    PIC X(10).
       01 WS-REQUEST-PATH      PIC X(512).
       01 WS-PATH-LEN          PIC 9(4) COMP-5 VALUE 0.
       01 WS-REQUEST-BODY      PIC X(4096).
       01 WS-BODY-LEN          PIC 9(4) COMP-5 VALUE 0.

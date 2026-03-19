      *> Parses HTTP request: method, path, body
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTTP-PARSE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-SPACE-POS         PIC 9(4) COMP-5 VALUE 0.
       01 WS-PATH-START        PIC 9(4) COMP-5 VALUE 0.
       01 WS-SCAN-IDX          PIC 9(4) COMP-5 VALUE 0.
       01 WS-BODY-START        PIC 9(4) COMP-5 VALUE 0.

       LINKAGE SECTION.
       01 LS-REQUEST-BUFFER    PIC X(4096).
       01 LS-REQUEST-METHOD    PIC X(10).
       01 LS-REQUEST-PATH      PIC X(512).
       01 LS-PATH-LEN          PIC 9(4) COMP-5.
       01 LS-REQUEST-BODY      PIC X(4096).
       01 LS-BODY-LEN          PIC 9(4) COMP-5.

       PROCEDURE DIVISION USING
           LS-REQUEST-BUFFER LS-REQUEST-METHOD
           LS-REQUEST-PATH LS-PATH-LEN
           LS-REQUEST-BODY LS-BODY-LEN.

       MAIN-LOGIC.
           MOVE SPACES TO LS-REQUEST-METHOD
           MOVE SPACES TO LS-REQUEST-PATH
           MOVE 0 TO LS-PATH-LEN
           MOVE SPACES TO LS-REQUEST-BODY
           MOVE 0 TO LS-BODY-LEN

      *> Extract method (before first space)
           MOVE 0 TO WS-SPACE-POS
           INSPECT LS-REQUEST-BUFFER TALLYING WS-SPACE-POS
               FOR CHARACTERS BEFORE INITIAL SPACE

           IF WS-SPACE-POS > 0 AND WS-SPACE-POS <= 10
               MOVE LS-REQUEST-BUFFER(1:WS-SPACE-POS)
                   TO LS-REQUEST-METHOD
           END-IF

      *> Extract path (between first and second space)
           COMPUTE WS-PATH-START = WS-SPACE-POS + 2

           PERFORM VARYING WS-SCAN-IDX
               FROM WS-PATH-START BY 1
               UNTIL WS-SCAN-IDX > 4096
               IF LS-REQUEST-BUFFER(WS-SCAN-IDX:1) = SPACE
                   OR LS-REQUEST-BUFFER(WS-SCAN-IDX:1) = X"0D"
                   OR LS-REQUEST-BUFFER(WS-SCAN-IDX:1) = X"0A"
                   COMPUTE LS-PATH-LEN =
                       WS-SCAN-IDX - WS-PATH-START
                   EXIT PERFORM
               END-IF
           END-PERFORM

           IF LS-PATH-LEN > 0 AND LS-PATH-LEN <= 512
               MOVE LS-REQUEST-BUFFER(
                   WS-PATH-START:LS-PATH-LEN)
                   TO LS-REQUEST-PATH
           END-IF

      *> Extract body (after \r\n\r\n)
           MOVE 0 TO WS-BODY-START
           PERFORM VARYING WS-SCAN-IDX FROM 1 BY 1
               UNTIL WS-SCAN-IDX > 4092
               IF LS-REQUEST-BUFFER(
                   WS-SCAN-IDX:4) = X"0D0A0D0A"
                   COMPUTE WS-BODY-START =
                       WS-SCAN-IDX + 4
                   EXIT PERFORM
               END-IF
           END-PERFORM

           IF WS-BODY-START > 0
               MOVE 0 TO LS-BODY-LEN
               INSPECT LS-REQUEST-BUFFER(WS-BODY-START:)
                   TALLYING LS-BODY-LEN
                   FOR CHARACTERS BEFORE INITIAL LOW-VALUE
               IF LS-BODY-LEN > 0 AND LS-BODY-LEN <= 4096
                   MOVE LS-REQUEST-BUFFER(
                       WS-BODY-START:LS-BODY-LEN)
                       TO LS-REQUEST-BODY
               END-IF
           END-IF

           GOBACK.

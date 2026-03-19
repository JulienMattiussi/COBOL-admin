      *> Parses HTTP request to extract the path
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTTP-PARSE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-SPACE-POS         PIC 9(4) COMP-5 VALUE 0.
       01 WS-PATH-START        PIC 9(4) COMP-5 VALUE 0.
       01 WS-SCAN-IDX          PIC 9(4) COMP-5 VALUE 0.

       LINKAGE SECTION.
       01 LS-REQUEST-BUFFER    PIC X(4096).
       01 LS-REQUEST-PATH      PIC X(512).
       01 LS-PATH-LEN          PIC 9(4) COMP-5.

       PROCEDURE DIVISION USING
           LS-REQUEST-BUFFER LS-REQUEST-PATH LS-PATH-LEN.

       MAIN-LOGIC.
           MOVE SPACES TO LS-REQUEST-PATH
           MOVE 0 TO LS-PATH-LEN

      *> Find first space (after method)
           MOVE 0 TO WS-SPACE-POS
           INSPECT LS-REQUEST-BUFFER TALLYING WS-SPACE-POS
               FOR CHARACTERS BEFORE INITIAL SPACE

      *> Start of path is after the space
           COMPUTE WS-PATH-START = WS-SPACE-POS + 2

      *> Find end of path (next space or line ending)
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

           GOBACK.

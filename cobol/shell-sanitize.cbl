      *> Sanitizes a string for safe use in shell commands
      *> Only allows alphanumeric, dash, underscore, dot, colon,
      *> slash, at-sign, plus, comma, space, equals
      *> Rejects the string if any other character is found
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SHELL-SANITIZE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-SCAN              PIC 9(4) COMP-5 VALUE 0.
       01 WS-CHAR              PIC X(1).
       01 WS-VALID-CHARS       PIC X(80)
           VALUE "abcdefghijklmnopqrstuvwxyz"
               &  "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
               &  "0123456789"
               &  "-_.:/@ +,=".

       01 WS-CHECK             PIC 9(4) COMP-5 VALUE 0.
       01 WS-FOUND             PIC 9 VALUE 0.

       LINKAGE SECTION.
       01 LS-INPUT             PIC X(512).
       01 LS-INPUT-LEN         PIC 9(4) COMP-5.
       01 LS-SAFE              PIC 9.

       PROCEDURE DIVISION USING
           LS-INPUT LS-INPUT-LEN LS-SAFE.

       MAIN-LOGIC.
           MOVE 1 TO LS-SAFE

           IF LS-INPUT-LEN = 0
               GOBACK
           END-IF

           PERFORM VARYING WS-SCAN FROM 1 BY 1
               UNTIL WS-SCAN > LS-INPUT-LEN
               MOVE LS-INPUT(WS-SCAN:1) TO WS-CHAR
               MOVE 0 TO WS-FOUND
               INSPECT WS-VALID-CHARS TALLYING WS-FOUND
                   FOR ALL WS-CHAR
               IF WS-FOUND = 0
                   MOVE 0 TO LS-SAFE
                   GOBACK
               END-IF
           END-PERFORM

           GOBACK.

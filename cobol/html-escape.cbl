      *> Escapes HTML special characters in a string
      *> Replaces & < > " ' with HTML entities
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTML-ESCAPE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-SCAN              PIC 9(4) COMP-5 VALUE 0.
       01 WS-OUT-PTR           PIC 9(4) COMP-5 VALUE 0.
       01 WS-CHAR              PIC X(1).

       LINKAGE SECTION.
       01 LS-INPUT             PIC X(2048).
       01 LS-INPUT-LEN         PIC 9(4) COMP-5.
       01 LS-OUTPUT            PIC X(4096).
       01 LS-OUTPUT-LEN        PIC 9(4) COMP-5.

       PROCEDURE DIVISION USING
           LS-INPUT LS-INPUT-LEN
           LS-OUTPUT LS-OUTPUT-LEN.

       MAIN-LOGIC.
           MOVE LOW-VALUE TO LS-OUTPUT
           MOVE 1 TO WS-OUT-PTR

           PERFORM VARYING WS-SCAN FROM 1 BY 1
               UNTIL WS-SCAN > LS-INPUT-LEN
               MOVE LS-INPUT(WS-SCAN:1) TO WS-CHAR
               EVALUATE WS-CHAR
                   WHEN "&"
                       STRING "&amp;" DELIMITED BY SIZE
                           INTO LS-OUTPUT
                           WITH POINTER WS-OUT-PTR
                       END-STRING
                   WHEN "<"
                       STRING "&lt;" DELIMITED BY SIZE
                           INTO LS-OUTPUT
                           WITH POINTER WS-OUT-PTR
                       END-STRING
                   WHEN ">"
                       STRING "&gt;" DELIMITED BY SIZE
                           INTO LS-OUTPUT
                           WITH POINTER WS-OUT-PTR
                       END-STRING
                   WHEN '"'
                       STRING "&quot;" DELIMITED BY SIZE
                           INTO LS-OUTPUT
                           WITH POINTER WS-OUT-PTR
                       END-STRING
                   WHEN "'"
                       STRING "&#39;" DELIMITED BY SIZE
                           INTO LS-OUTPUT
                           WITH POINTER WS-OUT-PTR
                       END-STRING
                   WHEN OTHER
                       MOVE WS-CHAR TO
                           LS-OUTPUT(WS-OUT-PTR:1)
                       ADD 1 TO WS-OUT-PTR
               END-EVALUATE
           END-PERFORM

           COMPUTE LS-OUTPUT-LEN = WS-OUT-PTR - 1
           GOBACK.

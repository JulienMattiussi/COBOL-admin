      *> Simple template engine: replaces {{key}} placeholders
      *> with values from a key-value table.
      *> The special key {{content}} inserts from a separate
      *> content buffer (for layout wrapping).
      *>
      *> Actions:
      *>   "SET"    - set a variable (pass key in TPL-KEY, value
      *>              in TPL-VALUE)
      *>   "RENDER" - render template file into HTML-BODY
      *>              (pass file path in TPL-KEY)
      *>   "CLEAR"  - clear all variables
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEMPLATE-ENGINE IS INITIAL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *> File handling
       01 WS-FOPEN-MODE           PIC X(4) VALUE Z"r".
       01 WS-FILE-PTR             USAGE POINTER.
       01 WS-FGETS-PTR            USAGE POINTER.
       01 WS-TPL-LINE             PIC X(1024).
       01 WS-FILE-PATH            PIC X(256).

      *> Scanning
       01 WS-SCAN                 PIC 9(5) COMP-5.
       01 WS-LINE-LEN             PIC 9(5) COMP-5.
       01 WS-OPEN-POS             PIC 9(5) COMP-5.
       01 WS-CLOSE-POS            PIC 9(5) COMP-5.
       01 WS-COPY-START           PIC 9(5) COMP-5.
       01 WS-KEY-LEN              PIC 9(5) COMP-5.
       01 WS-CHUNK-LEN            PIC 9(5) COMP-5.
       01 WS-FOUND-KEY            PIC X(30).
       01 WS-VAR-IDX              PIC 99.
       01 WS-FOUND                PIC 9 VALUE 0.

       LINKAGE SECTION.
       01 LS-HTML-BODY            PIC X(32768).
       01 LS-HTML-LEN             PIC 9(8) COMP-5.
       01 LS-TPL-ACTION           PIC X(6).
       01 LS-TPL-KEY              PIC X(256).
       01 LS-TPL-VALUE            PIC X(1024).
       01 LS-TPL-VARS.
          05 LS-TPL-VAR-COUNT     PIC 99.
          05 LS-TPL-VAR OCCURS 50 TIMES.
             10 LS-TPL-VAR-KEY    PIC X(30).
             10 LS-TPL-VAR-VALUE  PIC X(1024).
       01 LS-CONTENT-BUF          PIC X(16384).
       01 LS-CONTENT-LEN          PIC 9(8) COMP-5.

       PROCEDURE DIVISION USING
           LS-HTML-BODY LS-HTML-LEN
           LS-TPL-ACTION LS-TPL-KEY LS-TPL-VALUE
           LS-TPL-VARS
           LS-CONTENT-BUF LS-CONTENT-LEN.

       MAIN-LOGIC.
           EVALUATE LS-TPL-ACTION
               WHEN "SET"
                   PERFORM SET-VARIABLE
               WHEN "RENDER"
                   PERFORM RENDER-TEMPLATE
               WHEN "CLEAR"
                   MOVE 0 TO LS-TPL-VAR-COUNT
                   INITIALIZE LS-TPL-VARS
           END-EVALUATE
           GOBACK.

      *> Add or update a variable in the table
       SET-VARIABLE.
      *> Check if key already exists
           PERFORM VARYING WS-VAR-IDX FROM 1 BY 1
               UNTIL WS-VAR-IDX > LS-TPL-VAR-COUNT
               IF LS-TPL-VAR-KEY(WS-VAR-IDX) = LS-TPL-KEY
                   MOVE LS-TPL-VALUE
                       TO LS-TPL-VAR-VALUE(WS-VAR-IDX)
                   GOBACK
               END-IF
           END-PERFORM
      *> Add new variable
           ADD 1 TO LS-TPL-VAR-COUNT
           MOVE LS-TPL-KEY
               TO LS-TPL-VAR-KEY(LS-TPL-VAR-COUNT)
           MOVE LS-TPL-VALUE
               TO LS-TPL-VAR-VALUE(LS-TPL-VAR-COUNT)
           .

      *> Read template file and replace {{key}} placeholders
       RENDER-TEMPLATE.
      *> Build null-terminated file path
           MOVE LOW-VALUE TO WS-FILE-PATH
           STRING
               FUNCTION TRIM(LS-TPL-KEY)
                   DELIMITED BY SIZE
               X"00" DELIMITED BY SIZE
               INTO WS-FILE-PATH
           END-STRING

           CALL "fopen" USING WS-FILE-PATH WS-FOPEN-MODE
               RETURNING WS-FILE-PTR
           END-CALL

           IF WS-FILE-PTR = NULL
               STRING
                   "<p>Template not found: "
                       DELIMITED BY SIZE
                   LS-TPL-KEY DELIMITED BY SPACE
                   "</p>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY
                       WITH POINTER LS-HTML-LEN
               END-STRING
               GOBACK
           END-IF

           PERFORM READ-TEMPLATE-LINE
               UNTIL WS-FILE-PTR = NULL
           .

      *> Read one line, process placeholders, append to HTML
       READ-TEMPLATE-LINE.
           MOVE SPACES TO WS-TPL-LINE
           CALL "fgets" USING
               BY REFERENCE WS-TPL-LINE
               BY VALUE 1024
               BY VALUE WS-FILE-PTR
               RETURNING WS-FGETS-PTR
           END-CALL

           IF WS-FGETS-PTR = NULL
               CALL "fclose" USING BY VALUE WS-FILE-PTR
               END-CALL
               MOVE NULL TO WS-FILE-PTR
           ELSE
      *> Clean up line endings
               INSPECT WS-TPL-LINE
                   REPLACING ALL X"0A" BY SPACE
               INSPECT WS-TPL-LINE
                   REPLACING ALL X"0D" BY SPACE

      *> Find effective line length
               MOVE 0 TO WS-LINE-LEN
               INSPECT WS-TPL-LINE TALLYING WS-LINE-LEN
                   FOR CHARACTERS BEFORE INITIAL LOW-VALUE
               IF WS-LINE-LEN = 0
                   MOVE FUNCTION LENGTH(
                       FUNCTION TRIM(WS-TPL-LINE TRAILING))
                       TO WS-LINE-LEN
               END-IF

               PERFORM PROCESS-LINE
           END-IF
           .

      *> Scan line for {{ and }}, replace with variable values
       PROCESS-LINE.
           MOVE 1 TO WS-COPY-START
           MOVE 1 TO WS-SCAN

           PERFORM UNTIL WS-SCAN >= WS-LINE-LEN
      *> Look for {{
               IF WS-SCAN < WS-LINE-LEN
                   AND WS-TPL-LINE(WS-SCAN:2) = "{{"
      *> Output everything before {{
                   IF WS-SCAN > WS-COPY-START
                       COMPUTE WS-CHUNK-LEN =
                           WS-SCAN - WS-COPY-START
                       STRING
                           WS-TPL-LINE(
                               WS-COPY-START:WS-CHUNK-LEN)
                               DELIMITED BY SIZE
                           INTO LS-HTML-BODY
                               WITH POINTER LS-HTML-LEN
                       END-STRING
                   END-IF

      *> Find closing }}
                   COMPUTE WS-OPEN-POS = WS-SCAN + 2
                   MOVE 0 TO WS-CLOSE-POS
                   PERFORM VARYING WS-CLOSE-POS
                       FROM WS-OPEN-POS BY 1
                       UNTIL WS-CLOSE-POS >= WS-LINE-LEN
                       IF WS-TPL-LINE(WS-CLOSE-POS:2)
                           = "}}"
                           EXIT PERFORM
                       END-IF
                   END-PERFORM

                   IF WS-CLOSE-POS < WS-LINE-LEN
                       OR WS-TPL-LINE(WS-CLOSE-POS:2)
                           = "}}"
      *> Extract key name
                       COMPUTE WS-KEY-LEN =
                           WS-CLOSE-POS - WS-OPEN-POS
                       MOVE SPACES TO WS-FOUND-KEY
                       MOVE WS-TPL-LINE(
                           WS-OPEN-POS:WS-KEY-LEN)
                           TO WS-FOUND-KEY
      *> Trim spaces from key
                       MOVE FUNCTION TRIM(WS-FOUND-KEY)
                           TO WS-FOUND-KEY

      *> Special key: {{content}} inserts content buffer
                       IF WS-FOUND-KEY = "content"
                           AND LS-CONTENT-LEN > 0
                           MOVE LS-CONTENT-BUF(
                               1:LS-CONTENT-LEN)
                               TO LS-HTML-BODY(
                                   LS-HTML-LEN:
                                   LS-CONTENT-LEN)
                           ADD LS-CONTENT-LEN
                               TO LS-HTML-LEN
                           MOVE 1 TO WS-FOUND
                       ELSE

      *> Look up in variables
                       MOVE 0 TO WS-FOUND
                       PERFORM VARYING WS-VAR-IDX
                           FROM 1 BY 1
                           UNTIL WS-VAR-IDX >
                               LS-TPL-VAR-COUNT
                           IF LS-TPL-VAR-KEY(WS-VAR-IDX)
                               = WS-FOUND-KEY
                               STRING
                                   LS-TPL-VAR-VALUE(
                                       WS-VAR-IDX)
                                       DELIMITED BY "  "
                                   INTO LS-HTML-BODY
                                       WITH POINTER
                                       LS-HTML-LEN
                               END-STRING
                               MOVE 1 TO WS-FOUND
                               EXIT PERFORM
                           END-IF
                       END-PERFORM

                       END-IF

      *> If not found, output placeholder as-is
                       IF WS-FOUND = 0
                           COMPUTE WS-CHUNK-LEN =
                               WS-CLOSE-POS - WS-SCAN + 2
                           STRING
                               WS-TPL-LINE(
                                   WS-SCAN:WS-CHUNK-LEN)
                                   DELIMITED BY SIZE
                               INTO LS-HTML-BODY
                                   WITH POINTER LS-HTML-LEN
                           END-STRING
                       END-IF

      *> Skip past }}
                       COMPUTE WS-SCAN =
                           WS-CLOSE-POS + 2
                       MOVE WS-SCAN TO WS-COPY-START
                   ELSE
      *> No closing }}, output {{ literally
                       STRING "{{" DELIMITED BY SIZE
                           INTO LS-HTML-BODY
                               WITH POINTER LS-HTML-LEN
                       END-STRING
                       COMPUTE WS-SCAN = WS-SCAN + 2
                       MOVE WS-SCAN TO WS-COPY-START
                   END-IF
               ELSE
                   ADD 1 TO WS-SCAN
               END-IF
           END-PERFORM

      *> Output remaining text after last placeholder
           IF WS-COPY-START <= WS-LINE-LEN
               COMPUTE WS-CHUNK-LEN =
                   WS-LINE-LEN - WS-COPY-START + 1
               IF WS-CHUNK-LEN > 0
                   STRING
                       WS-TPL-LINE(
                           WS-COPY-START:WS-CHUNK-LEN)
                           DELIMITED BY SIZE
                       INTO LS-HTML-BODY
                           WITH POINTER LS-HTML-LEN
                   END-STRING
               END-IF
           END-IF
           .

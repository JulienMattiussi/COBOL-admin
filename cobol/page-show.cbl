      *> Builds the show page: fetches one item, displays fields
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAGE-SHOW.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-CMD               PIC X(1024).
       01 WS-FOPEN-MODE        PIC X(4) VALUE Z"r".
       01 WS-FILE-PTR          USAGE POINTER.
       01 WS-FGETS-PTR         USAGE POINTER.
       01 WS-LINE              PIC X(2048).
       01 WS-READ-DONE         PIC 9 VALUE 0.
       01 WS-FIELD-IDX         PIC 99 VALUE 0.
       01 WS-DATA-FILE         PIC X(256)
           VALUE Z"/tmp/showdata.tsv".

       LINKAGE SECTION.
       01 LS-HTML-BODY         PIC X(32768).
       01 LS-HTML-LEN          PIC 9(8) COMP-5.
       01 LS-RESOURCE-NAME     PIC X(64).
       01 LS-RESOURCE-ID       PIC X(10).
       01 LS-API-URL           PIC X(256).
       01 LS-RESOURCE-TABLE.
          05 LS-RESOURCE-COUNT PIC 99.
          05 LS-RESOURCES OCCURS 20 TIMES.
             10 LS-RES-NAME    PIC X(64).
             10 LS-RES-FIELD-COUNT PIC 99.
             10 LS-RES-FIELDS OCCURS 20 TIMES.
                15 LS-RES-FIELD-NAME PIC X(64).
       01 LS-RES-IDX           PIC 99.

       PROCEDURE DIVISION USING
           LS-HTML-BODY LS-HTML-LEN
           LS-RESOURCE-NAME LS-RESOURCE-ID LS-API-URL
           LS-RESOURCE-TABLE LS-RES-IDX.

       MAIN-LOGIC.
           PERFORM FETCH-ITEM
           PERFORM BUILD-PAGE
           GOBACK.

      *> Fetch single item from API, convert to TSV line
       FETCH-ITEM.
           MOVE LOW-VALUE TO WS-CMD
           STRING
               "curl -s '" DELIMITED BY SIZE
               LS-API-URL DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               "' | jq -r '[" DELIMITED BY SIZE
               INTO WS-CMD
           END-STRING

      *> Append field selectors
           PERFORM VARYING WS-FIELD-IDX FROM 1 BY 1
               UNTIL WS-FIELD-IDX >
                   LS-RES-FIELD-COUNT(LS-RES-IDX)
               IF WS-FIELD-IDX > 1
                   STRING "," DELIMITED BY SIZE
                       INTO WS-CMD
                       WITH POINTER WS-FIELD-IDX
                   END-STRING
               END-IF
           END-PERFORM

      *> Need to rebuild cmd properly with pointer
           MOVE LOW-VALUE TO WS-CMD
           PERFORM BUILD-FETCH-CMD

           CALL "SYSTEM" USING FUNCTION TRIM(WS-CMD)
           END-CALL
           .

       BUILD-FETCH-CMD.
           MOVE LOW-VALUE TO WS-CMD
           MOVE 1 TO WS-FIELD-IDX

           STRING
               "curl -s '" DELIMITED BY SIZE
               LS-API-URL DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               "' | jq -r '" DELIMITED BY SIZE
               INTO WS-CMD
           END-STRING

      *> Find end of string for appending
           MOVE 0 TO WS-FIELD-IDX
           INSPECT WS-CMD TALLYING WS-FIELD-IDX
               FOR CHARACTERS BEFORE INITIAL LOW-VALUE
           ADD 1 TO WS-FIELD-IDX

      *> Append field extraction: outputs key<tab>value per field
           STRING
               "to_entries[]"
                   DELIMITED BY SIZE
               " | if .value|type==""array"""
                   DELIMITED BY SIZE
               " then [.key,(.value|map(tostring)"
                   DELIMITED BY SIZE
               "|join("", ""))]"
                   DELIMITED BY SIZE
               " else [.key,(.value|tostring)] end"
                   DELIMITED BY SIZE
               " | @tsv'"
                   DELIMITED BY SIZE
               " > /tmp/showdata.tsv"
                   DELIMITED BY SIZE
               INTO WS-CMD WITH POINTER WS-FIELD-IDX
           END-STRING
           .

      *> Build HTML: heading, back link, field table
       BUILD-PAGE.
      *> Heading + back link
           STRING
               "<h1>" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               " #" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               "</h1>" DELIMITED BY SIZE
               "<p><a href='/list/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "'>Back to list</a></p>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

      *> Field table (key-value pairs)
           STRING
               "<table class='show-table'>"
                   DELIMITED BY SIZE
               "<thead><tr><th>Field</th>"
                   DELIMITED BY SIZE
               "<th>Value</th></tr></thead>"
                   DELIMITED BY SIZE
               "<tbody>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

      *> Read TSV rows (field<tab>value per line)
           CALL "fopen" USING WS-DATA-FILE WS-FOPEN-MODE
               RETURNING WS-FILE-PTR
           END-CALL
           IF WS-FILE-PTR NOT = NULL
               MOVE 0 TO WS-READ-DONE
               PERFORM READ-FIELD-ROW
                   UNTIL WS-READ-DONE = 1
               CALL "fclose" USING BY VALUE WS-FILE-PTR
               END-CALL
           END-IF

           STRING
               "</tbody></table>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           .

       READ-FIELD-ROW.
           MOVE SPACES TO WS-LINE
           CALL "fgets" USING
               BY REFERENCE WS-LINE
               BY VALUE 2048
               BY VALUE WS-FILE-PTR
               RETURNING WS-FGETS-PTR
           END-CALL

           IF WS-FGETS-PTR = NULL
               MOVE 1 TO WS-READ-DONE
           ELSE
               INSPECT WS-LINE
                   REPLACING ALL X"0A" BY SPACE
               INSPECT WS-LINE
                   REPLACING ALL X"0D" BY SPACE

      *> Find tab separator
               MOVE 0 TO WS-FIELD-IDX
               INSPECT WS-LINE TALLYING WS-FIELD-IDX
                   FOR CHARACTERS BEFORE INITIAL X"09"

               IF WS-FIELD-IDX > 0
                   STRING
                       "<tr><td>" DELIMITED BY SIZE
                       WS-LINE(1:WS-FIELD-IDX)
                           DELIMITED BY SIZE
                       "</td><td>" DELIMITED BY SIZE
                       INTO LS-HTML-BODY
                           WITH POINTER LS-HTML-LEN
                   END-STRING
      *> Value after tab
                   ADD 2 TO WS-FIELD-IDX
                   STRING
                       FUNCTION TRIM(
                           WS-LINE(WS-FIELD-IDX:)
                           TRAILING)
                           DELIMITED BY SIZE
                       "</td></tr>" DELIMITED BY SIZE
                       INTO LS-HTML-BODY
                           WITH POINTER LS-HTML-LEN
                   END-STRING
               END-IF
           END-IF
           .

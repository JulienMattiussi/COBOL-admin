      *> Builds edit form or handles form submission
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAGE-EDIT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-CMD               PIC X(2048).
       01 WS-FOPEN-MODE        PIC X(4) VALUE Z"r".
       01 WS-FILE-PTR          USAGE POINTER.
       01 WS-FGETS-PTR         USAGE POINTER.
       01 WS-LINE              PIC X(2048).
       01 WS-READ-DONE         PIC 9 VALUE 0.
       01 WS-FIELD-IDX         PIC 99 VALUE 0.
       01 WS-DATA-FILE         PIC X(256)
           VALUE Z"/tmp/showdata.tsv".
       01 WS-FIELD-KEY         PIC X(64).
       01 WS-FIELD-VAL         PIC X(1024).
       01 WS-TAB-POS           PIC 9(4) COMP-5 VALUE 0.
       01 WS-FNAME-LEN         PIC 99 VALUE 0.
       01 WS-MATCH-IDX         PIC 99 VALUE 0.
       01 WS-FIELD-TYPE        PIC X(16).
       01 WS-FIELD-EDIT        PIC 9 VALUE 0.
       01 WS-INPUT-TYPE        PIC X(20).

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
                15 LS-RES-FIELD-TYPE PIC X(16).
                15 LS-RES-FIELD-EDIT PIC 9.
       01 LS-RES-IDX           PIC 99.

       PROCEDURE DIVISION USING
           LS-HTML-BODY LS-HTML-LEN
           LS-RESOURCE-NAME LS-RESOURCE-ID LS-API-URL
           LS-RESOURCE-TABLE LS-RES-IDX.

       MAIN-LOGIC.
           PERFORM FETCH-ITEM
           PERFORM BUILD-FORM
           GOBACK.

      *> Fetch current item data (same as show page)
       FETCH-ITEM.
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

           MOVE 0 TO WS-FIELD-IDX
           INSPECT WS-CMD TALLYING WS-FIELD-IDX
               FOR CHARACTERS BEFORE INITIAL LOW-VALUE
           ADD 1 TO WS-FIELD-IDX

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

           CALL "SYSTEM" USING FUNCTION TRIM(WS-CMD)
           END-CALL
           .

      *> Build HTML form
       BUILD-FORM.
      *> Header with cancel link
           STRING
               "<div class='show-header'>"
                   DELIMITED BY SIZE
               "<div><h1>Edit " DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               " #" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               "</h1>" DELIMITED BY SIZE
               "<a href='/show/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               "'>Cancel</a></div></div>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

      *> Form posts to /edit/{resource}/{id}
           STRING
               "<form method='POST' action='/edit/"
                   DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               "' class='edit-form'>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

      *> Read fields and render inputs
           CALL "fopen" USING WS-DATA-FILE WS-FOPEN-MODE
               RETURNING WS-FILE-PTR
           END-CALL
           IF WS-FILE-PTR NOT = NULL
               MOVE 0 TO WS-READ-DONE
               PERFORM READ-FORM-FIELD
                   UNTIL WS-READ-DONE = 1
               CALL "fclose" USING BY VALUE WS-FILE-PTR
               END-CALL
           END-IF

      *> Submit button
           STRING
               "<div class='form-actions'>"
                   DELIMITED BY SIZE
               "<button type='submit' class='btn'>"
                   DELIMITED BY SIZE
               "Save</button>"
                   DELIMITED BY SIZE
               "<a href='/show/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               "'>Cancel</a></div></form>"
                   DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           .

       READ-FORM-FIELD.
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

      *> Extract key and value
               MOVE 0 TO WS-TAB-POS
               INSPECT WS-LINE TALLYING WS-TAB-POS
                   FOR CHARACTERS BEFORE INITIAL X"09"

               IF WS-TAB-POS > 0
                   MOVE SPACES TO WS-FIELD-KEY
                   MOVE SPACES TO WS-FIELD-VAL
                   MOVE WS-LINE(1:WS-TAB-POS) TO WS-FIELD-KEY
                   COMPUTE WS-TAB-POS = WS-TAB-POS + 2
                   MOVE FUNCTION TRIM(
                       WS-LINE(WS-TAB-POS:) TRAILING)
                       TO WS-FIELD-VAL

      *> Look up field type and editability
                   MOVE "string" TO WS-FIELD-TYPE
                   MOVE 1 TO WS-FIELD-EDIT
                   PERFORM VARYING WS-MATCH-IDX FROM 1 BY 1
                       UNTIL WS-MATCH-IDX >
                           LS-RES-FIELD-COUNT(LS-RES-IDX)
                       IF LS-RES-FIELD-NAME(
                           LS-RES-IDX, WS-MATCH-IDX)
                           = WS-FIELD-KEY
                           MOVE LS-RES-FIELD-TYPE(
                               LS-RES-IDX, WS-MATCH-IDX)
                               TO WS-FIELD-TYPE
                           MOVE LS-RES-FIELD-EDIT(
                               LS-RES-IDX, WS-MATCH-IDX)
                               TO WS-FIELD-EDIT
                           EXIT PERFORM
                       END-IF
                   END-PERFORM

      *> Skip array fields
                   IF FUNCTION TRIM(WS-FIELD-TYPE) = "array"
                       CONTINUE
                   ELSE
                       PERFORM RENDER-INPUT
                   END-IF
               END-IF
           END-IF
           .

       RENDER-INPUT.
      *> Map schema type to HTML input type
           IF FUNCTION TRIM(WS-FIELD-TYPE) = "integer"
               MOVE "number" TO WS-INPUT-TYPE
           ELSE
               MOVE "text" TO WS-INPUT-TYPE
           END-IF

      *> Label
           STRING
               "<div class='form-field'>"
                   DELIMITED BY SIZE
               "<label for='" DELIMITED BY SIZE
               WS-FIELD-KEY DELIMITED BY SPACE
               "'>" DELIMITED BY SIZE
               WS-FIELD-KEY DELIMITED BY SPACE
               "</label>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

      *> Input (disabled if not editable)
           STRING
               "<input type='" DELIMITED BY SIZE
               WS-INPUT-TYPE DELIMITED BY SPACE
               "' name='" DELIMITED BY SIZE
               WS-FIELD-KEY DELIMITED BY SPACE
               "' id='" DELIMITED BY SIZE
               WS-FIELD-KEY DELIMITED BY SPACE
               "' value='" DELIMITED BY SIZE
               WS-FIELD-VAL DELIMITED BY SPACE
               "'" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

           IF WS-FIELD-EDIT = 0
               STRING " disabled" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-IF

           STRING "></div>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           .

      *> Builds the list page: fetches data from API, renders table
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAGE-LIST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-CMD               PIC X(1024).
       01 WS-FOPEN-MODE        PIC X(4) VALUE Z"r".
       01 WS-FILE-PTR          USAGE POINTER.
       01 WS-FGETS-PTR         USAGE POINTER.
       01 WS-DATA-LINE         PIC X(2048).
       01 WS-READ-DONE         PIC 9 VALUE 0.
       01 WS-FIELD-IDX         PIC 99 VALUE 0.
       01 WS-DATA-FILE         PIC X(256)
           VALUE Z"/tmp/listdata.tsv".
       01 WS-TOTAL-FILE        PIC X(256)
           VALUE Z"/tmp/total.txt".
       01 WS-TOTAL-LINE        PIC X(20).
       01 WS-CELL-START        PIC 9(4) COMP-5 VALUE 0.
       01 WS-CELL-END          PIC 9(4) COMP-5 VALUE 0.
       01 WS-SCAN              PIC 9(4) COMP-5 VALUE 0.
       01 WS-LINE-LEN          PIC 9(4) COMP-5 VALUE 0.
       01 WS-PAGE-STR          PIC ZZ9.
       01 WS-PERPAGE-STR       PIC ZZ9.
       01 WS-TOTAL-PAGES       PIC 999 VALUE 0.
       01 WS-PAGE-IDX          PIC 999 VALUE 0.
       01 WS-PAGE-IDX-STR      PIC ZZ9.
       01 WS-TOTAL-STR         PIC ZZZZZ9.
       01 WS-JQ-FIELDS         PIC X(512).
       01 WS-JQ-PTR            PIC 9(4) COMP-5 VALUE 0.

       LINKAGE SECTION.
       01 LS-HTML-BODY         PIC X(32768).
       01 LS-HTML-LEN          PIC 9(8) COMP-5.
       01 LS-RESOURCE-NAME     PIC X(64).
       01 LS-API-URL           PIC X(256).
       01 LS-PAGE              PIC 999.
       01 LS-PER-PAGE          PIC 999.
       01 LS-TOTAL-COUNT       PIC 99999.
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
           LS-RESOURCE-NAME LS-API-URL
           LS-PAGE LS-PER-PAGE LS-TOTAL-COUNT
           LS-RESOURCE-TABLE LS-RES-IDX.

       MAIN-LOGIC.
           PERFORM FETCH-DATA
           PERFORM BUILD-PAGE
           GOBACK.

      *> Fetch paginated data from API using curl + jq
       FETCH-DATA.
           MOVE LS-PAGE TO WS-PAGE-STR
           MOVE LS-PER-PAGE TO WS-PERPAGE-STR

      *> Build jq field selector: [.field1, .field2, ...]
           MOVE LOW-VALUE TO WS-JQ-FIELDS
           MOVE 1 TO WS-JQ-PTR
           STRING "[" DELIMITED BY SIZE
               INTO WS-JQ-FIELDS WITH POINTER WS-JQ-PTR
           END-STRING
           PERFORM VARYING WS-FIELD-IDX FROM 1 BY 1
               UNTIL WS-FIELD-IDX > LS-RES-FIELD-COUNT(LS-RES-IDX)
               IF WS-FIELD-IDX > 1
                   STRING "," DELIMITED BY SIZE
                       INTO WS-JQ-FIELDS
                       WITH POINTER WS-JQ-PTR
                   END-STRING
               END-IF
               STRING
                   "." DELIMITED BY SIZE
                   LS-RES-FIELD-NAME(LS-RES-IDX, WS-FIELD-IDX)
                       DELIMITED BY SPACE
                   INTO WS-JQ-FIELDS
                       WITH POINTER WS-JQ-PTR
               END-STRING
           END-PERFORM
           STRING "]" DELIMITED BY SIZE
               INTO WS-JQ-FIELDS WITH POINTER WS-JQ-PTR
           END-STRING

      *> curl API with pagination, pipe through jq to get TSV
           MOVE LOW-VALUE TO WS-CMD
           STRING
               "curl -sD /tmp/headers.txt '"
                   DELIMITED BY SIZE
               LS-API-URL DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "?page=" DELIMITED BY SIZE
               FUNCTION TRIM(WS-PAGE-STR)
                       DELIMITED BY SIZE
               "&perPage=" DELIMITED BY SIZE
               FUNCTION TRIM(WS-PERPAGE-STR)
                       DELIMITED BY SIZE
               "' | jq -r '.[] | "
                   DELIMITED BY SIZE
               WS-JQ-FIELDS DELIMITED BY LOW-VALUE
               " | map(tostring) | @tsv' > /tmp/listdata.tsv"
                   DELIMITED BY SIZE
               INTO WS-CMD
           END-STRING
           CALL "SYSTEM" USING FUNCTION TRIM(WS-CMD)
           END-CALL

      *> Extract X-Total-Count from response headers
           MOVE LOW-VALUE TO WS-CMD
           STRING
               "grep -i 'x-total-count' /tmp/headers.txt"
               " | tr -d '\r\n' | cut -d' ' -f2"
               " > /tmp/total.txt"
               DELIMITED BY SIZE
               INTO WS-CMD
           END-STRING
           CALL "SYSTEM" USING FUNCTION TRIM(WS-CMD)
           END-CALL

           CALL "fopen" USING WS-TOTAL-FILE WS-FOPEN-MODE
               RETURNING WS-FILE-PTR
           END-CALL
           IF WS-FILE-PTR NOT = NULL
               MOVE SPACES TO WS-TOTAL-LINE
               CALL "fgets" USING
                   BY REFERENCE WS-TOTAL-LINE
                   BY VALUE 20
                   BY VALUE WS-FILE-PTR
                   RETURNING WS-FGETS-PTR
               END-CALL
               CALL "fclose" USING BY VALUE WS-FILE-PTR
               END-CALL
               INSPECT WS-TOTAL-LINE
                   REPLACING ALL X"0A" BY SPACE
               INSPECT WS-TOTAL-LINE
                   REPLACING ALL X"0D" BY SPACE
               INSPECT WS-TOTAL-LINE
                   REPLACING ALL LOW-VALUE BY SPACE
               IF FUNCTION TRIM(WS-TOTAL-LINE TRAILING)
                   NOT = SPACES
                   COMPUTE LS-TOTAL-COUNT = FUNCTION NUMVAL(
                       FUNCTION TRIM(WS-TOTAL-LINE TRAILING))
               END-IF
           END-IF
           .

      *> Build HTML: heading, perPage selector, table, pagination
       BUILD-PAGE.
      *> Heading
           STRING
               "<h1>" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "</h1>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

      *> Per-page selector
           STRING
               "<div style='margin-bottom:16px;'>"
                   DELIMITED BY SIZE
               "<span>Show </span>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           PERFORM BUILD-PERPAGE-LINK-10
           PERFORM BUILD-PERPAGE-LINK-25
           PERFORM BUILD-PERPAGE-LINK-50
           PERFORM BUILD-PERPAGE-LINK-100
           STRING
               "<span style='margin-left:16px;color:#888;'>"
                   DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           MOVE LS-TOTAL-COUNT TO WS-TOTAL-STR
           STRING
               FUNCTION TRIM(WS-TOTAL-STR)
                   DELIMITED BY SIZE
               " total</span></div>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

      *> Table header
           STRING
               "<table style='width:100%;"
                   DELIMITED BY SIZE
               "border-collapse:collapse;'>"
                   DELIMITED BY SIZE
               "<thead><tr>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

           PERFORM VARYING WS-FIELD-IDX FROM 1 BY 1
               UNTIL WS-FIELD-IDX > LS-RES-FIELD-COUNT(LS-RES-IDX)
               STRING
                   "<th style='text-align:left;"
                       DELIMITED BY SIZE
                   "padding:8px;border-bottom:"
                       DELIMITED BY SIZE
                   "2px solid #2c3e50;'>"
                       DELIMITED BY SIZE
                   LS-RES-FIELD-NAME(LS-RES-IDX, WS-FIELD-IDX)
                       DELIMITED BY SPACE
                   "</th>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-PERFORM

           STRING
               "</tr></thead><tbody>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

      *> Table rows from TSV file
           CALL "fopen" USING WS-DATA-FILE WS-FOPEN-MODE
               RETURNING WS-FILE-PTR
           END-CALL
           IF WS-FILE-PTR NOT = NULL
               MOVE 0 TO WS-READ-DONE
               PERFORM READ-DATA-ROW
                   UNTIL WS-READ-DONE = 1
               CALL "fclose" USING BY VALUE WS-FILE-PTR
               END-CALL
           END-IF

           STRING
               "</tbody></table>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

      *> Pagination links
           PERFORM BUILD-PAGINATION
           .

       READ-DATA-ROW.
           MOVE SPACES TO WS-DATA-LINE
           CALL "fgets" USING
               BY REFERENCE WS-DATA-LINE
               BY VALUE 2048
               BY VALUE WS-FILE-PTR
               RETURNING WS-FGETS-PTR
           END-CALL

           IF WS-FGETS-PTR = NULL
               MOVE 1 TO WS-READ-DONE
           ELSE
               INSPECT WS-DATA-LINE
                   REPLACING ALL X"0A" BY SPACE
               INSPECT WS-DATA-LINE
                   REPLACING ALL X"0D" BY SPACE

      *> Parse TSV: split by tabs into table cells
               STRING "<tr>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING

               MOVE 0 TO WS-LINE-LEN
               INSPECT WS-DATA-LINE TALLYING WS-LINE-LEN
                   FOR CHARACTERS BEFORE INITIAL LOW-VALUE
               IF WS-LINE-LEN = 0
                   MOVE FUNCTION LENGTH(
                       FUNCTION TRIM(WS-DATA-LINE TRAILING))
                       TO WS-LINE-LEN
               END-IF

               MOVE 1 TO WS-CELL-START
               PERFORM VARYING WS-SCAN FROM 1 BY 1
                   UNTIL WS-SCAN > WS-LINE-LEN
                   IF WS-DATA-LINE(WS-SCAN:1) = X"09"
                       COMPUTE WS-CELL-END =
                           WS-SCAN - WS-CELL-START
                       PERFORM WRITE-CELL
                       COMPUTE WS-CELL-START = WS-SCAN + 1
                   END-IF
               END-PERFORM
      *> Last cell (after last tab)
               COMPUTE WS-CELL-END =
                   WS-LINE-LEN - WS-CELL-START + 1
               IF WS-CELL-END > 0
                   PERFORM WRITE-CELL
               END-IF

               STRING "</tr>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-IF
           .

       WRITE-CELL.
           STRING
               "<td style='padding:8px;"
                   DELIMITED BY SIZE
               "border-bottom:1px solid #ddd;'>"
                   DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           IF WS-CELL-END > 0
               STRING
                   WS-DATA-LINE(WS-CELL-START:WS-CELL-END)
                       DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-IF
           STRING "</td>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           .

      *> Pagination nav
       BUILD-PAGINATION.
           IF LS-TOTAL-COUNT = 0
               GOBACK
           END-IF

           COMPUTE WS-TOTAL-PAGES =
               (LS-TOTAL-COUNT + LS-PER-PAGE - 1)
               / LS-PER-PAGE

           IF WS-TOTAL-PAGES <= 1
               GOBACK
           END-IF

           STRING
               "<div style='margin-top:16px;"
                   DELIMITED BY SIZE
               "display:flex;gap:4px;'>"
                   DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

           MOVE LS-PER-PAGE TO WS-PERPAGE-STR

           PERFORM VARYING WS-PAGE-IDX FROM 1 BY 1
               UNTIL WS-PAGE-IDX > WS-TOTAL-PAGES
               MOVE WS-PAGE-IDX TO WS-PAGE-IDX-STR
               IF WS-PAGE-IDX = LS-PAGE
                   STRING
                       "<span style='padding:6px 12px;"
                           DELIMITED BY SIZE
                       "background:#2c3e50;color:#fff;"
                           DELIMITED BY SIZE
                       "border-radius:4px;'>"
                           DELIMITED BY SIZE
                       FUNCTION TRIM(WS-PAGE-IDX-STR)
                       DELIMITED BY SIZE
                       "</span>" DELIMITED BY SIZE
                       INTO LS-HTML-BODY
                           WITH POINTER LS-HTML-LEN
                   END-STRING
               ELSE
                   STRING
                       "<a href='/list/" DELIMITED BY SIZE
                       LS-RESOURCE-NAME DELIMITED BY SPACE
                       "?page=" DELIMITED BY SIZE
                       FUNCTION TRIM(WS-PAGE-IDX-STR)
                       DELIMITED BY SIZE
                       "&perPage=" DELIMITED BY SIZE
                       FUNCTION TRIM(WS-PERPAGE-STR)
                       DELIMITED BY SIZE
                       "' style='padding:6px 12px;"
                           DELIMITED BY SIZE
                       "border:1px solid #ddd;"
                           DELIMITED BY SIZE
                       "border-radius:4px;"
                           DELIMITED BY SIZE
                       "text-decoration:none;"
                           DELIMITED BY SIZE
                       "color:#2c3e50;'>"
                           DELIMITED BY SIZE
                       FUNCTION TRIM(WS-PAGE-IDX-STR)
                       DELIMITED BY SIZE
                       "</a>" DELIMITED BY SIZE
                       INTO LS-HTML-BODY
                           WITH POINTER LS-HTML-LEN
                   END-STRING
               END-IF
           END-PERFORM

           STRING "</div>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           .

       BUILD-PERPAGE-LINK-10.
           PERFORM BUILD-PERPAGE-LINK-COMMON-10
           .
       BUILD-PERPAGE-LINK-25.
           PERFORM BUILD-PERPAGE-LINK-COMMON-25
           .
       BUILD-PERPAGE-LINK-50.
           PERFORM BUILD-PERPAGE-LINK-COMMON-50
           .
       BUILD-PERPAGE-LINK-100.
           PERFORM BUILD-PERPAGE-LINK-COMMON-100
           .

       BUILD-PERPAGE-LINK-COMMON-10.
           IF LS-PER-PAGE = 10
               STRING
                   "<strong style='padding:4px 8px;'>"
                       DELIMITED BY SIZE
                   "10</strong>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           ELSE
               STRING
                   "<a href='/list/" DELIMITED BY SIZE
                   LS-RESOURCE-NAME DELIMITED BY SPACE
                   "?perPage=10' style='"
                       DELIMITED BY SIZE
                   "padding:4px 8px;"
                       DELIMITED BY SIZE
                   "text-decoration:none;'>10</a>"
                       DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-IF
           .

       BUILD-PERPAGE-LINK-COMMON-25.
           IF LS-PER-PAGE = 25
               STRING
                   "<strong style='padding:4px 8px;'>"
                       DELIMITED BY SIZE
                   "25</strong>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           ELSE
               STRING
                   "<a href='/list/" DELIMITED BY SIZE
                   LS-RESOURCE-NAME DELIMITED BY SPACE
                   "?perPage=25' style='"
                       DELIMITED BY SIZE
                   "padding:4px 8px;"
                       DELIMITED BY SIZE
                   "text-decoration:none;'>25</a>"
                       DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-IF
           .

       BUILD-PERPAGE-LINK-COMMON-50.
           IF LS-PER-PAGE = 50
               STRING
                   "<strong style='padding:4px 8px;'>"
                       DELIMITED BY SIZE
                   "50</strong>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           ELSE
               STRING
                   "<a href='/list/" DELIMITED BY SIZE
                   LS-RESOURCE-NAME DELIMITED BY SPACE
                   "?perPage=50' style='"
                       DELIMITED BY SIZE
                   "padding:4px 8px;"
                       DELIMITED BY SIZE
                   "text-decoration:none;'>50</a>"
                       DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-IF
           .

       BUILD-PERPAGE-LINK-COMMON-100.
           IF LS-PER-PAGE = 100
               STRING
                   "<strong style='padding:4px 8px;'>"
                       DELIMITED BY SIZE
                   "100</strong>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           ELSE
               STRING
                   "<a href='/list/" DELIMITED BY SIZE
                   LS-RESOURCE-NAME DELIMITED BY SPACE
                   "?perPage=100' style='"
                       DELIMITED BY SIZE
                   "padding:4px 8px;"
                       DELIMITED BY SIZE
                   "text-decoration:none;'>100</a>"
                       DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-IF
           .

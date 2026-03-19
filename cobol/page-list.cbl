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
       01 WS-TOTAL-STR         PIC ZZZZZ9.
       01 WS-ID-COL            PIC 99 VALUE 0.
       01 WS-COL-IDX           PIC 99 VALUE 0.
       01 WS-ROW-ID            PIC X(10).
       01 WS-JQ-FIELDS         PIC X(512).
       01 WS-JQ-PTR            PIC 9(4) COMP-5 VALUE 0.

      *> Reference detection per column
       01 WS-COL-REF-TABLE.
          05 WS-COL-REFS OCCURS 20 TIMES.
             10 WS-COL-REF-RES PIC X(64).
       01 WS-FNAME-LEN         PIC 99 VALUE 0.
       01 WS-REF-CANDIDATE     PIC X(64).
       01 WS-REF-CHECK-IDX     PIC 99 VALUE 0.
       01 WS-CELL-VALUE        PIC X(256).

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
                15 LS-RES-FIELD-TYPE PIC X(16).
                15 LS-RES-FIELD-EDIT PIC 9.
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
               " | map(if type==""array"" then"
                   DELIMITED BY SIZE
               " map(tostring)|join("", "")"
                   DELIMITED BY SIZE
               " else tostring end)"
                   DELIMITED BY SIZE
               " | @tsv' > /tmp/listdata.tsv"
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
               "<div class='list-toolbar'>"
                   DELIMITED BY SIZE
               "<span class='perpage-selector'>"
                   DELIMITED BY SIZE
               "Show " DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           PERFORM BUILD-PERPAGE-LINK-10
           PERFORM BUILD-PERPAGE-LINK-25
           PERFORM BUILD-PERPAGE-LINK-50
           PERFORM BUILD-PERPAGE-LINK-100
           STRING
               "</span>"
                   DELIMITED BY SIZE
               "<span class='total'>"
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

      *> Find id column and build reference map per column
           MOVE 0 TO WS-ID-COL
           INITIALIZE WS-COL-REF-TABLE
           PERFORM VARYING WS-FIELD-IDX FROM 1 BY 1
               UNTIL WS-FIELD-IDX >
                   LS-RES-FIELD-COUNT(LS-RES-IDX)
               IF LS-RES-FIELD-NAME(LS-RES-IDX, WS-FIELD-IDX)
                   = "id"
                   MOVE WS-FIELD-IDX TO WS-ID-COL
               END-IF
      *> Check if field ends with "Id" → reference
               MOVE FUNCTION LENGTH(FUNCTION TRIM(
                   LS-RES-FIELD-NAME(LS-RES-IDX, WS-FIELD-IDX)))
                   TO WS-FNAME-LEN
               IF WS-FNAME-LEN > 2
                   IF LS-RES-FIELD-NAME(
                       LS-RES-IDX, WS-FIELD-IDX)
                       (WS-FNAME-LEN - 1:2) = "Id"
      *> Strip "Id", append "s" to get resource name
                       MOVE SPACES TO WS-REF-CANDIDATE
                       STRING
                           LS-RES-FIELD-NAME(
                               LS-RES-IDX, WS-FIELD-IDX)
                               (1:WS-FNAME-LEN - 2)
                               DELIMITED BY SIZE
                           "s" DELIMITED BY SIZE
                           INTO WS-REF-CANDIDATE
                       END-STRING
      *> Check if this resource exists
                       PERFORM VARYING WS-REF-CHECK-IDX
                           FROM 1 BY 1
                           UNTIL WS-REF-CHECK-IDX >
                               LS-RESOURCE-COUNT
                           IF LS-RES-NAME(WS-REF-CHECK-IDX)
                               = WS-REF-CANDIDATE
                               MOVE WS-REF-CANDIDATE
                                   TO WS-COL-REF-RES(
                                       WS-FIELD-IDX)
                               EXIT PERFORM
                           END-IF
                       END-PERFORM
                   END-IF
               END-IF
           END-PERFORM

      *> Table header
           STRING
               "<table>"
                   DELIMITED BY SIZE
               "<thead><tr>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

           PERFORM VARYING WS-FIELD-IDX FROM 1 BY 1
               UNTIL WS-FIELD-IDX > LS-RES-FIELD-COUNT(LS-RES-IDX)
               STRING
                   "<th>" DELIMITED BY SIZE
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

      *> First pass: find id value for the row link
               MOVE 1 TO WS-COL-IDX
               MOVE SPACES TO WS-ROW-ID
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
                       IF WS-COL-IDX = WS-ID-COL
                           COMPUTE WS-CELL-END =
                               WS-SCAN - WS-CELL-START
                           MOVE WS-DATA-LINE(
                               WS-CELL-START:WS-CELL-END)
                               TO WS-ROW-ID
                       END-IF
                       COMPUTE WS-CELL-START = WS-SCAN + 1
                       ADD 1 TO WS-COL-IDX
                   END-IF
               END-PERFORM
               IF WS-COL-IDX = WS-ID-COL
                   COMPUTE WS-CELL-END =
                       WS-LINE-LEN - WS-CELL-START + 1
                   MOVE WS-DATA-LINE(
                       WS-CELL-START:WS-CELL-END)
                       TO WS-ROW-ID
               END-IF

      *> Write <tr>
               STRING "<tr>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY
                       WITH POINTER LS-HTML-LEN
               END-STRING

               MOVE 0 TO WS-LINE-LEN
               INSPECT WS-DATA-LINE TALLYING WS-LINE-LEN
                   FOR CHARACTERS BEFORE INITIAL LOW-VALUE
               IF WS-LINE-LEN = 0
                   MOVE FUNCTION LENGTH(
                       FUNCTION TRIM(WS-DATA-LINE TRAILING))
                       TO WS-LINE-LEN
               END-IF

      *> Second pass: write cells with links
               MOVE 1 TO WS-COL-IDX
               MOVE 1 TO WS-CELL-START
               PERFORM VARYING WS-SCAN FROM 1 BY 1
                   UNTIL WS-SCAN > WS-LINE-LEN
                   IF WS-DATA-LINE(WS-SCAN:1) = X"09"
                       COMPUTE WS-CELL-END =
                           WS-SCAN - WS-CELL-START
                       PERFORM WRITE-CELL
                       COMPUTE WS-CELL-START = WS-SCAN + 1
                       ADD 1 TO WS-COL-IDX
                   END-IF
               END-PERFORM
      *> Last cell
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
           STRING "<td>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

      *> Extract cell value for link target
           MOVE SPACES TO WS-CELL-VALUE
           IF WS-CELL-END > 0
               MOVE WS-DATA-LINE(WS-CELL-START:WS-CELL-END)
                   TO WS-CELL-VALUE
           END-IF

      *> Determine link: reference field → ref resource,
      *>                  otherwise → current resource show
           IF WS-COL-REF-RES(WS-COL-IDX) NOT = SPACES
               STRING
                   "<a class='ref-link' href='/show/"
                       DELIMITED BY SIZE
                   WS-COL-REF-RES(WS-COL-IDX)
                       DELIMITED BY SPACE
                   "/" DELIMITED BY SIZE
                   WS-CELL-VALUE DELIMITED BY SPACE
                   "'>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           ELSE
               IF WS-ID-COL > 0
                   STRING
                       "<a href='/show/" DELIMITED BY SIZE
                       LS-RESOURCE-NAME DELIMITED BY SPACE
                       "/" DELIMITED BY SIZE
                       WS-ROW-ID DELIMITED BY SPACE
                       "'>" DELIMITED BY SIZE
                       INTO LS-HTML-BODY
                           WITH POINTER LS-HTML-LEN
                   END-STRING
               END-IF
           END-IF

           IF WS-CELL-END > 0
               STRING
                   WS-DATA-LINE(WS-CELL-START:WS-CELL-END)
                       DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-IF

      *> Close link
           IF WS-COL-REF-RES(WS-COL-IDX) NOT = SPACES
               STRING "</a>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           ELSE
               IF WS-ID-COL > 0
                   STRING "</a>" DELIMITED BY SIZE
                       INTO LS-HTML-BODY
                           WITH POINTER LS-HTML-LEN
                   END-STRING
               END-IF
           END-IF

           STRING "</td>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           .

       BUILD-PAGINATION.
           CALL "PAGINATION" USING
               LS-HTML-BODY LS-HTML-LEN
               LS-RESOURCE-NAME
               LS-PAGE LS-PER-PAGE LS-TOTAL-COUNT
           END-CALL
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
               STRING "<strong class='active'>10</strong>"
                   DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           ELSE
               STRING
                   "<a href='/list/" DELIMITED BY SIZE
                   LS-RESOURCE-NAME DELIMITED BY SPACE
                   "?perPage=10'>10</a>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-IF
           .

       BUILD-PERPAGE-LINK-COMMON-25.
           IF LS-PER-PAGE = 25
               STRING "<strong class='active'>25</strong>"
                   DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           ELSE
               STRING
                   "<a href='/list/" DELIMITED BY SIZE
                   LS-RESOURCE-NAME DELIMITED BY SPACE
                   "?perPage=25'>25</a>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-IF
           .

       BUILD-PERPAGE-LINK-COMMON-50.
           IF LS-PER-PAGE = 50
               STRING "<strong class='active'>50</strong>"
                   DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           ELSE
               STRING
                   "<a href='/list/" DELIMITED BY SIZE
                   LS-RESOURCE-NAME DELIMITED BY SPACE
                   "?perPage=50'>50</a>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-IF
           .

       BUILD-PERPAGE-LINK-COMMON-100.
           IF LS-PER-PAGE = 100
               STRING "<strong class='active'>100</strong>"
                   DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           ELSE
               STRING
                   "<a href='/list/" DELIMITED BY SIZE
                   LS-RESOURCE-NAME DELIMITED BY SPACE
                   "?perPage=100'>100</a>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-IF
           .

      *> Reusable pagination component
      *> Renders: < 1 ... 5 6 7 8 9 ... last >
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAGINATION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TOTAL-PAGES       PIC 999 VALUE 0.
       01 WS-PAGE-IDX          PIC 999 VALUE 0.
       01 WS-PAGE-IDX-STR      PIC ZZ9.
       01 WS-PERPAGE-STR       PIC ZZ9.
       01 WS-WIN-START         PIC 999 VALUE 0.
       01 WS-WIN-END           PIC 999 VALUE 0.
       01 WS-PREV-PAGE         PIC 999 VALUE 0.
       01 WS-NEXT-PAGE         PIC 999 VALUE 0.

       LINKAGE SECTION.
       01 LS-HTML-BODY         PIC X(32768).
       01 LS-HTML-LEN          PIC 9(8) COMP-5.
       01 LS-RESOURCE-NAME     PIC X(64).
       01 LS-PAGE              PIC 999.
       01 LS-PER-PAGE          PIC 999.
       01 LS-TOTAL-COUNT       PIC 99999.

       PROCEDURE DIVISION USING
           LS-HTML-BODY LS-HTML-LEN
           LS-RESOURCE-NAME
           LS-PAGE LS-PER-PAGE LS-TOTAL-COUNT.

       MAIN-LOGIC.
           IF LS-TOTAL-COUNT = 0
               GOBACK
           END-IF

           COMPUTE WS-TOTAL-PAGES =
               (LS-TOTAL-COUNT + LS-PER-PAGE - 1)
               / LS-PER-PAGE

           IF WS-TOTAL-PAGES <= 1
               GOBACK
           END-IF

           MOVE LS-PER-PAGE TO WS-PERPAGE-STR

      *> Compute sliding window of 5 pages
           COMPUTE WS-WIN-START = LS-PAGE - 2
           IF WS-WIN-START < 1
               MOVE 1 TO WS-WIN-START
           END-IF
           COMPUTE WS-WIN-END = WS-WIN-START + 4
           IF WS-WIN-END > WS-TOTAL-PAGES
               MOVE WS-TOTAL-PAGES TO WS-WIN-END
               COMPUTE WS-WIN-START = WS-WIN-END - 4
               IF WS-WIN-START < 1
                   MOVE 1 TO WS-WIN-START
               END-IF
           END-IF

           STRING "<div class='pagination'>"
               DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

      *> Previous button
           IF LS-PAGE > 1
               COMPUTE WS-PREV-PAGE = LS-PAGE - 1
               MOVE WS-PREV-PAGE TO WS-PAGE-IDX-STR
               PERFORM WRITE-NAV-LINK-PREV
           ELSE
               PERFORM WRITE-NAV-DISABLED-PREV
           END-IF

      *> First page + left ellipsis
           IF WS-WIN-START > 1
               MOVE 1 TO WS-PAGE-IDX
               MOVE WS-PAGE-IDX TO WS-PAGE-IDX-STR
               PERFORM WRITE-PAGE-LINK
               IF WS-WIN-START > 2
                   PERFORM WRITE-ELLIPSIS
               END-IF
           END-IF

      *> Page number buttons (window)
           PERFORM VARYING WS-PAGE-IDX
               FROM WS-WIN-START BY 1
               UNTIL WS-PAGE-IDX > WS-WIN-END
               MOVE WS-PAGE-IDX TO WS-PAGE-IDX-STR
               IF WS-PAGE-IDX = LS-PAGE
                   PERFORM WRITE-CURRENT-PAGE
               ELSE
                   PERFORM WRITE-PAGE-LINK
               END-IF
           END-PERFORM

      *> Right ellipsis + last page
           IF WS-WIN-END < WS-TOTAL-PAGES
               IF WS-WIN-END < WS-TOTAL-PAGES - 1
                   PERFORM WRITE-ELLIPSIS
               END-IF
               MOVE WS-TOTAL-PAGES TO WS-PAGE-IDX
               MOVE WS-PAGE-IDX TO WS-PAGE-IDX-STR
               PERFORM WRITE-PAGE-LINK
           END-IF

      *> Next button
           IF LS-PAGE < WS-TOTAL-PAGES
               COMPUTE WS-NEXT-PAGE = LS-PAGE + 1
               MOVE WS-NEXT-PAGE TO WS-PAGE-IDX-STR
               PERFORM WRITE-NAV-LINK-NEXT
           ELSE
               PERFORM WRITE-NAV-DISABLED-NEXT
           END-IF

           STRING "</div>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

           GOBACK.

       WRITE-CURRENT-PAGE.
           STRING
               "<span class='current'>"
                   DELIMITED BY SIZE
               FUNCTION TRIM(WS-PAGE-IDX-STR)
                   DELIMITED BY SIZE
               "</span>" DELIMITED BY SIZE
               INTO LS-HTML-BODY
                   WITH POINTER LS-HTML-LEN
           END-STRING
           .

       WRITE-ELLIPSIS.
           STRING
               "<span class='ellipsis'>...</span>"
                   DELIMITED BY SIZE
               INTO LS-HTML-BODY
                   WITH POINTER LS-HTML-LEN
           END-STRING
           .

       WRITE-PAGE-LINK.
           STRING
               "<a href='/list/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "?page=" DELIMITED BY SIZE
               FUNCTION TRIM(WS-PAGE-IDX-STR)
                   DELIMITED BY SIZE
               "&perPage=" DELIMITED BY SIZE
               FUNCTION TRIM(WS-PERPAGE-STR)
                   DELIMITED BY SIZE
               "'>" DELIMITED BY SIZE
               FUNCTION TRIM(WS-PAGE-IDX-STR)
                   DELIMITED BY SIZE
               "</a>" DELIMITED BY SIZE
               INTO LS-HTML-BODY
                   WITH POINTER LS-HTML-LEN
           END-STRING
           .

       WRITE-NAV-LINK-PREV.
           STRING
               "<a href='/list/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "?page=" DELIMITED BY SIZE
               FUNCTION TRIM(WS-PAGE-IDX-STR)
                   DELIMITED BY SIZE
               "&perPage=" DELIMITED BY SIZE
               FUNCTION TRIM(WS-PERPAGE-STR)
                   DELIMITED BY SIZE
               "'>&lt;</a>" DELIMITED BY SIZE
               INTO LS-HTML-BODY
                   WITH POINTER LS-HTML-LEN
           END-STRING
           .

       WRITE-NAV-DISABLED-PREV.
           STRING
               "<span class='disabled'>&lt;</span>"
                   DELIMITED BY SIZE
               INTO LS-HTML-BODY
                   WITH POINTER LS-HTML-LEN
           END-STRING
           .

       WRITE-NAV-LINK-NEXT.
           STRING
               "<a href='/list/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "?page=" DELIMITED BY SIZE
               FUNCTION TRIM(WS-PAGE-IDX-STR)
                   DELIMITED BY SIZE
               "&perPage=" DELIMITED BY SIZE
               FUNCTION TRIM(WS-PERPAGE-STR)
                   DELIMITED BY SIZE
               "'>&gt;</a>" DELIMITED BY SIZE
               INTO LS-HTML-BODY
                   WITH POINTER LS-HTML-LEN
           END-STRING
           .

       WRITE-NAV-DISABLED-NEXT.
           STRING
               "<span class='disabled'>&gt;</span>"
                   DELIMITED BY SIZE
               INTO LS-HTML-BODY
                   WITH POINTER LS-HTML-LEN
           END-STRING
           .

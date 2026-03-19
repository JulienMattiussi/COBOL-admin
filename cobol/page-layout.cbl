      *> Shared HTML layout: head with CSS + sidebar nav, and footer
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAGE-LAYOUT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX               PIC 99 VALUE 0.

       LINKAGE SECTION.
       01 LS-HTML-BODY         PIC X(32768).
       01 LS-HTML-LEN          PIC 9(8) COMP-5.
       01 LS-RESOURCE-TABLE.
          05 LS-RESOURCE-COUNT PIC 99.
          05 LS-RESOURCES OCCURS 20 TIMES.
             10 LS-RES-NAME    PIC X(64).
             10 LS-RES-FIELD-COUNT PIC 99.
             10 LS-RES-FIELDS OCCURS 20 TIMES.
                15 LS-RES-FIELD-NAME PIC X(64).
       01 LS-ACTION            PIC X(5).

       PROCEDURE DIVISION USING
           LS-HTML-BODY LS-HTML-LEN
           LS-RESOURCE-TABLE LS-ACTION.

       MAIN-LOGIC.
           EVALUATE LS-ACTION
               WHEN "HEAD"
                   PERFORM BUILD-HEAD
               WHEN "FOOT"
                   PERFORM BUILD-FOOT
           END-EVALUATE
           GOBACK.

       BUILD-HEAD.
           STRING
               "<!DOCTYPE html><html><head>" DELIMITED BY SIZE
               "<meta charset='utf-8'>" DELIMITED BY SIZE
               "<title>COBOL Admin</title>" DELIMITED BY SIZE
               "<link rel='stylesheet'"
                   DELIMITED BY SIZE
               " href='/static/style.css'>"
                   DELIMITED BY SIZE
               "</head><body>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

      *> Sidebar nav
           STRING
               "<nav>" DELIMITED BY SIZE
               "<h2><a href='/'>COBOL Admin</a></h2>"
                   DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > LS-RESOURCE-COUNT
               STRING
                   "<a href='/list/" DELIMITED BY SIZE
                   LS-RES-NAME(WS-IDX) DELIMITED BY SPACE
                   "'>" DELIMITED BY SIZE
                   LS-RES-NAME(WS-IDX) DELIMITED BY SPACE
                   "</a>" DELIMITED BY SIZE
                   INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
               END-STRING
           END-PERFORM

           STRING
               "</nav><main>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           .

       BUILD-FOOT.
           STRING
               "</main></body></html>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           .

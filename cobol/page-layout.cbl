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
               "<style>" DELIMITED BY SIZE
               "*{box-sizing:border-box;margin:0;padding:0;}"
                   DELIMITED BY SIZE
               "body{font-family:sans-serif;display:flex;"
                   DELIMITED BY SIZE
               "min-height:100vh;}" DELIMITED BY SIZE
               "nav{width:220px;background:#2c3e50;"
                   DELIMITED BY SIZE
               "color:#fff;padding:20px;flex-shrink:0;}"
                   DELIMITED BY SIZE
               "nav h2{font-size:16px;margin-bottom:16px;"
                   DELIMITED BY SIZE
               "padding-bottom:8px;border-bottom:1px solid"
                   DELIMITED BY SIZE
               " #3d566e;}" DELIMITED BY SIZE
               "nav a{display:block;color:#ecf0f1;"
                   DELIMITED BY SIZE
               "text-decoration:none;padding:8px 12px;"
                   DELIMITED BY SIZE
               "border-radius:4px;margin-bottom:4px;"
                   DELIMITED BY SIZE
               "font-size:14px;}" DELIMITED BY SIZE
               "nav a:hover{background:#34495e;}"
                   DELIMITED BY SIZE
               "main{flex:1;padding:32px;}"
                   DELIMITED BY SIZE
               "h1{color:#2c3e50;margin-bottom:16px;}"
                   DELIMITED BY SIZE
               "p{color:#555;line-height:1.6;}"
                   DELIMITED BY SIZE
               "</style></head><body>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

      *> Sidebar nav
           STRING
               "<nav>" DELIMITED BY SIZE
               "<h2><a href='/' style='color:#fff;"
                   DELIMITED BY SIZE
               "text-decoration:none'>COBOL Admin</a></h2>"
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

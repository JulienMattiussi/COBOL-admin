      *> Builds the 404 page content
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAGE-404.

       DATA DIVISION.
       LINKAGE SECTION.
       01 LS-HTML-BODY         PIC X(32768).
       01 LS-HTML-LEN          PIC 9(8) COMP-5.

       PROCEDURE DIVISION USING LS-HTML-BODY LS-HTML-LEN.

       MAIN-LOGIC.
           STRING
               "<h1>404 - Not Found</h1>" DELIMITED BY SIZE
               "<p><a href='/'>Back to home</a></p>"
                   DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           GOBACK.

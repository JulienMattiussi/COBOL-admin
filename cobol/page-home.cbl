      *> Builds the home page content
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAGE-HOME.

       DATA DIVISION.
       LINKAGE SECTION.
       01 LS-HTML-BODY         PIC X(32768).
       01 LS-HTML-LEN          PIC 9(8) COMP-5.

       PROCEDURE DIVISION USING LS-HTML-BODY LS-HTML-LEN.

       MAIN-LOGIC.
           STRING
               "<h1>Hello, COBOL Admin!</h1>" DELIMITED BY SIZE
               "<p>Served by GnuCOBOL. Select a resource"
                   DELIMITED BY SIZE
               " from the menu.</p>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           GOBACK.

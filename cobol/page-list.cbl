      *> Builds the list page content for a resource
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAGE-LIST.

       DATA DIVISION.
       LINKAGE SECTION.
       01 LS-HTML-BODY         PIC X(32768).
       01 LS-HTML-LEN          PIC 9(8) COMP-5.
       01 LS-RESOURCE-NAME     PIC X(64).

       PROCEDURE DIVISION USING
           LS-HTML-BODY LS-HTML-LEN LS-RESOURCE-NAME.

       MAIN-LOGIC.
           STRING
               "<h1>" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "</h1>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING
           GOBACK.

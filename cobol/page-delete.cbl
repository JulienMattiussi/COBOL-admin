      *> Builds delete confirmation page
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAGE-DELETE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       LINKAGE SECTION.
       01 LS-HTML-BODY         PIC X(32768).
       01 LS-HTML-LEN          PIC 9(8) COMP-5.
       01 LS-RESOURCE-NAME     PIC X(64).
       01 LS-RESOURCE-ID       PIC X(10).

       PROCEDURE DIVISION USING
           LS-HTML-BODY LS-HTML-LEN
           LS-RESOURCE-NAME LS-RESOURCE-ID.

       MAIN-LOGIC.
           STRING
               "<div class='delete-confirm'>"
                   DELIMITED BY SIZE
               "<h1>Delete " DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               " #" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               "</h1>" DELIMITED BY SIZE
               "<p>Are you sure you want to delete this "
                   DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "? This action cannot be undone.</p>"
                   DELIMITED BY SIZE
               "<form method='POST' action='/delete/"
                   DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               "' class='form-actions'>"
                   DELIMITED BY SIZE
               "<button type='submit' class='btn btn-danger'>"
                   DELIMITED BY SIZE
               "Delete</button>" DELIMITED BY SIZE
               "<a href='/show/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               "'>Cancel</a>" DELIMITED BY SIZE
               "</form></div>" DELIMITED BY SIZE
               INTO LS-HTML-BODY WITH POINTER LS-HTML-LEN
           END-STRING

           GOBACK.

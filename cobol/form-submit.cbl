      *> Handles form submission: converts form data to JSON, PUTs
      *> Uses C helpers: cobol_form_to_json, cobol_http_put
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FORM-SUBMIT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-URL-Z             PIC X(512).
       01 WS-BODY-FILE         PIC X(256)
           VALUE Z"/tmp/formbody.txt".
       01 WS-JSON-FILE         PIC X(256)
           VALUE Z"/tmp/formjson.json".
       01 WS-FOPEN-MODE-W      PIC X(4) VALUE Z"w".
       01 WS-FILE-PTR          USAGE POINTER.
       01 WS-WRITE-RESULT      PIC S9(9) COMP-5.
       01 WS-C-RESULT          PIC S9(9) COMP-5 VALUE 0.

       LINKAGE SECTION.
       01 LS-API-URL           PIC X(256).
       01 LS-RESOURCE-NAME     PIC X(64).
       01 LS-RESOURCE-ID       PIC X(10).
       01 LS-FORM-BODY         PIC X(4096).
       01 LS-BODY-LEN          PIC 9(4) COMP-5.
       01 LS-STATUS            PIC 9.

       PROCEDURE DIVISION USING
           LS-API-URL LS-RESOURCE-NAME LS-RESOURCE-ID
           LS-FORM-BODY LS-BODY-LEN LS-STATUS.

       MAIN-LOGIC.
           MOVE 1 TO LS-STATUS

      *> Write form body to file
           CALL "fopen" USING WS-BODY-FILE WS-FOPEN-MODE-W
               RETURNING WS-FILE-PTR
           END-CALL
           IF WS-FILE-PTR = NULL
               DISPLAY "Failed to write form body"
               GOBACK
           END-IF
           CALL "fwrite" USING
               BY REFERENCE LS-FORM-BODY
               BY VALUE 1 BY VALUE LS-BODY-LEN
               BY VALUE WS-FILE-PTR
               RETURNING WS-WRITE-RESULT
           END-CALL
           CALL "fclose" USING BY VALUE WS-FILE-PTR
           END-CALL

      *> Convert URL-encoded form data to JSON
           CALL "cobol_form_to_json" USING
               BY REFERENCE WS-BODY-FILE
               BY REFERENCE WS-JSON-FILE
               RETURNING WS-C-RESULT
           END-CALL

           IF WS-C-RESULT NOT = 0
               DISPLAY "Form to JSON conversion failed: "
                   WS-C-RESULT
               MOVE 0 TO LS-STATUS
               GOBACK
           END-IF

      *> Build PUT URL
           MOVE LOW-VALUE TO WS-URL-Z
           STRING
               FUNCTION TRIM(LS-API-URL) DELIMITED BY SIZE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               LOW-VALUE DELIMITED BY SIZE
               INTO WS-URL-Z
           END-STRING

      *> PUT to API
           CALL "cobol_http_put" USING
               BY REFERENCE WS-URL-Z
               BY REFERENCE WS-JSON-FILE
               RETURNING WS-C-RESULT
           END-CALL

           IF WS-C-RESULT NOT = 0
               DISPLAY "PUT failed: " WS-C-RESULT
               MOVE 0 TO LS-STATUS
           END-IF

           GOBACK.

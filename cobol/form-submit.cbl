      *> Handles form submission: converts form data to JSON, PUTs
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FORM-SUBMIT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-CMD               PIC X(4096).
       01 WS-SANITIZE-BUF      PIC X(512).
       01 WS-SANITIZE-LEN      PIC 9(4) COMP-5 VALUE 0.
       01 WS-SANITIZE-OK       PIC 9 VALUE 0.
       01 WS-BODY-FILE         PIC X(256)
           VALUE Z"/tmp/formbody.txt".
       01 WS-JSON-FILE         PIC X(256)
           VALUE Z"/tmp/formjson.json".
       01 WS-FOPEN-MODE-W      PIC X(4) VALUE Z"w".
       01 WS-FILE-PTR          USAGE POINTER.
       01 WS-WRITE-RESULT      PIC S9(9) COMP-5.

       LINKAGE SECTION.
       01 LS-API-URL           PIC X(256).
       01 LS-RESOURCE-NAME     PIC X(64).
       01 LS-RESOURCE-ID       PIC X(10).
       01 LS-FORM-BODY         PIC X(4096).
       01 LS-BODY-LEN          PIC 9(4) COMP-5.

       PROCEDURE DIVISION USING
           LS-API-URL LS-RESOURCE-NAME LS-RESOURCE-ID
           LS-FORM-BODY LS-BODY-LEN.

       MAIN-LOGIC.
      *> Validate resource ID
           MOVE LS-RESOURCE-ID TO WS-SANITIZE-BUF
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(LS-RESOURCE-ID))
               TO WS-SANITIZE-LEN
           CALL "SHELL-SANITIZE" USING
               WS-SANITIZE-BUF WS-SANITIZE-LEN WS-SANITIZE-OK
           END-CALL
           IF WS-SANITIZE-OK = 0
               DISPLAY "Rejected unsafe resource ID"
               GOBACK
           END-IF
      *> Validate resource name
           MOVE LS-RESOURCE-NAME TO WS-SANITIZE-BUF
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(LS-RESOURCE-NAME))
               TO WS-SANITIZE-LEN
           CALL "SHELL-SANITIZE" USING
               WS-SANITIZE-BUF WS-SANITIZE-LEN WS-SANITIZE-OK
           END-CALL
           IF WS-SANITIZE-OK = 0
               DISPLAY "Rejected unsafe resource name"
               GOBACK
           END-IF

      *> Write form body to file for processing
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

      *> Convert URL-encoded form data to JSON using shell
      *> Then PUT to API
           MOVE LOW-VALUE TO WS-CMD
           STRING
               "python3 -c """
                   DELIMITED BY SIZE
               "import urllib.parse,json,sys;"
                   DELIMITED BY SIZE
               "d=urllib.parse.parse_qs("
                   DELIMITED BY SIZE
               "open('/tmp/formbody.txt').read(),"
                   DELIMITED BY SIZE
               "keep_blank_values=True);"
                   DELIMITED BY SIZE
               "r={k:v[0] for k,v in d.items()};"
                   DELIMITED BY SIZE
               "json.dump(r,open('/tmp/formjson.json','w'))"
                   DELIMITED BY SIZE
               """" DELIMITED BY SIZE
               INTO WS-CMD
           END-STRING
           CALL "SYSTEM" USING FUNCTION TRIM(WS-CMD)
           END-CALL

      *> PUT to API
           MOVE LOW-VALUE TO WS-CMD
           STRING
               "curl -s -X PUT '"
                   DELIMITED BY SIZE
               LS-API-URL DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               "' -H 'Content-Type: application/json'"
                   DELIMITED BY SIZE
               " -d @/tmp/formjson.json"
                   DELIMITED BY SIZE
               " > /dev/null"
                   DELIMITED BY SIZE
               INTO WS-CMD
           END-STRING
           CALL "SYSTEM" USING FUNCTION TRIM(WS-CMD)
           END-CALL

           GOBACK.

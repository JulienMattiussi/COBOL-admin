      *> Fetches a single item from the API as key-value TSV
      *> Uses C helper: cobol_http_get + cobol_json_to_tsv
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FETCH-ITEM.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-URL               PIC X(512).
       01 WS-URL-Z             PIC X(512).
       01 WS-RESP-FILE         PIC X(256)
           VALUE Z"/tmp/response.json".
       01 WS-TSV-FILE          PIC X(256)
           VALUE Z"/tmp/showdata.tsv".
       01 WS-EMPTY             PIC X(1) VALUE Z" ".
       01 WS-MODE              PIC X(8) VALUE Z"object".
       01 WS-RESULT            PIC S9(9) COMP-5 VALUE 0.

       LINKAGE SECTION.
       01 LS-API-URL           PIC X(256).
       01 LS-RESOURCE-NAME     PIC X(64).
       01 LS-RESOURCE-ID       PIC X(10).
       01 LS-STATUS            PIC 9.

       PROCEDURE DIVISION USING
           LS-API-URL LS-RESOURCE-NAME LS-RESOURCE-ID
           LS-STATUS.

       MAIN-LOGIC.
           MOVE 1 TO LS-STATUS

      *> Build URL
           MOVE LOW-VALUE TO WS-URL
           STRING
               LS-API-URL DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               INTO WS-URL
           END-STRING

      *> Null-terminate
           MOVE LOW-VALUE TO WS-URL-Z
           STRING
               FUNCTION TRIM(WS-URL) DELIMITED BY SIZE
               LOW-VALUE DELIMITED BY SIZE
               INTO WS-URL-Z
           END-STRING

      *> HTTP GET
           CALL "cobol_http_get" USING
               BY REFERENCE WS-URL-Z
               BY REFERENCE WS-RESP-FILE
               BY REFERENCE WS-EMPTY
               RETURNING WS-RESULT
           END-CALL

           IF WS-RESULT NOT = 0
               DISPLAY "HTTP GET failed: " WS-RESULT
               MOVE 0 TO LS-STATUS
               GOBACK
           END-IF

      *> Convert JSON to TSV
           CALL "cobol_json_to_tsv" USING
               BY REFERENCE WS-RESP-FILE
               BY REFERENCE WS-TSV-FILE
               BY REFERENCE WS-MODE
               BY REFERENCE WS-EMPTY
               RETURNING WS-RESULT
           END-CALL

           GOBACK.

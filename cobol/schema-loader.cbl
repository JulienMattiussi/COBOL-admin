      *> Fetches OpenAPI spec and extracts resource names
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SCHEMA-LOADER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-CMD               PIC X(512).
       01 WS-FOPEN-MODE        PIC X(4) VALUE Z"r".
       01 WS-FILE-PTR          USAGE POINTER.
       01 WS-FGETS-PTR         USAGE POINTER.
       01 WS-RES-LINE          PIC X(64).
       01 WS-RES-READ-DONE     PIC 9 VALUE 0.
       01 WS-RESOURCE-FILE     PIC X(256)
           VALUE Z"/tmp/resources.txt".
       01 WS-JSON-PATH         PIC X(256)
           VALUE Z"/tmp/openapi.json".

       LINKAGE SECTION.
       01 LS-API-URL           PIC X(256).
       01 LS-RESOURCE-TABLE.
          05 LS-RESOURCE-COUNT PIC 99.
          05 LS-RESOURCES OCCURS 20 TIMES.
             10 LS-RES-NAME    PIC X(64).

       PROCEDURE DIVISION USING LS-API-URL LS-RESOURCE-TABLE.

       MAIN-LOGIC.
           PERFORM FETCH-SCHEMA
           PERFORM PARSE-RESOURCES
           GOBACK.

       FETCH-SCHEMA.
           DISPLAY "Fetching OpenAPI spec..."

           MOVE LOW-VALUE TO WS-CMD
           STRING
               "curl -s " DELIMITED BY SIZE
               LS-API-URL DELIMITED BY SPACE
               "/openapi.json -o /tmp/openapi.json"
                   DELIMITED BY SIZE
               INTO WS-CMD
           END-STRING
           CALL "SYSTEM" USING FUNCTION TRIM(WS-CMD)
           END-CALL
           .

       PARSE-RESOURCES.
           DISPLAY "Extracting resources..."

           MOVE LOW-VALUE TO WS-CMD
           STRING
               "jq -r '.paths|keys[]|split(""/"")[1]'"
               " /tmp/openapi.json|sort -u"
               " > /tmp/resources.txt"
               DELIMITED BY SIZE
               INTO WS-CMD
           END-STRING
           CALL "SYSTEM" USING FUNCTION TRIM(WS-CMD)
           END-CALL

           CALL "fopen" USING WS-RESOURCE-FILE WS-FOPEN-MODE
               RETURNING WS-FILE-PTR
           END-CALL
           IF WS-FILE-PTR = NULL
               DISPLAY "Failed to open resources file"
               GOBACK
           END-IF

           MOVE 0 TO LS-RESOURCE-COUNT
           MOVE 0 TO WS-RES-READ-DONE
           PERFORM READ-RESOURCES
               UNTIL WS-RES-READ-DONE = 1

           CALL "fclose" USING BY VALUE WS-FILE-PTR
           END-CALL

           DISPLAY "Found " LS-RESOURCE-COUNT " resources"
           .

       READ-RESOURCES.
           MOVE SPACES TO WS-RES-LINE
           CALL "fgets" USING
               BY REFERENCE WS-RES-LINE
               BY VALUE 64
               BY VALUE WS-FILE-PTR
               RETURNING WS-FGETS-PTR
           END-CALL

           IF WS-FGETS-PTR = NULL
               MOVE 1 TO WS-RES-READ-DONE
           ELSE
               INSPECT WS-RES-LINE
                   REPLACING ALL X"0A" BY SPACE
               INSPECT WS-RES-LINE
                   REPLACING ALL X"0D" BY SPACE
               INSPECT WS-RES-LINE
                   REPLACING ALL LOW-VALUE BY SPACE
               IF FUNCTION TRIM(WS-RES-LINE TRAILING)
                   NOT = SPACES
                   ADD 1 TO LS-RESOURCE-COUNT
                   MOVE SPACES
                       TO LS-RES-NAME(LS-RESOURCE-COUNT)
                   MOVE FUNCTION TRIM(WS-RES-LINE TRAILING)
                       TO LS-RES-NAME(LS-RESOURCE-COUNT)
               END-IF
           END-IF
           .

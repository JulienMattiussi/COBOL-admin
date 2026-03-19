      *> Fetches OpenAPI spec and extracts resources + fields
      *> Uses C helpers: cobol_http_get, cobol_json_resources,
      *>                 cobol_json_fields
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SCHEMA-LOADER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-URL               PIC X(512).
       01 WS-URL-Z             PIC X(512).
       01 WS-FOPEN-MODE        PIC X(4) VALUE Z"r".
       01 WS-FILE-PTR          USAGE POINTER.
       01 WS-FGETS-PTR         USAGE POINTER.
       01 WS-LINE              PIC X(256).
       01 WS-TAB1-POS          PIC 9(4) COMP-5 VALUE 0.
       01 WS-TAB2-POS          PIC 9(4) COMP-5 VALUE 0.
       01 WS-SCAN              PIC 9(4) COMP-5 VALUE 0.
       01 WS-LINE-LEN          PIC 9(4) COMP-5 VALUE 0.
       01 WS-READ-DONE         PIC 9 VALUE 0.
       01 WS-RESOURCE-FILE     PIC X(256)
           VALUE Z"/tmp/resources.txt".
       01 WS-FIELDS-FILE       PIC X(256)
           VALUE Z"/tmp/fields.txt".
       01 WS-JSON-FILE         PIC X(256)
           VALUE Z"/tmp/openapi.json".
       01 WS-EMPTY             PIC X(1) VALUE Z" ".
       01 WS-IDX               PIC 99 VALUE 0.
       01 WS-RES-NAME-Z        PIC X(65).
       01 WS-RESULT            PIC S9(9) COMP-5 VALUE 0.

       LINKAGE SECTION.
       01 LS-API-URL           PIC X(256).
       01 LS-RESOURCE-TABLE.
          05 LS-RESOURCE-COUNT PIC 99.
          05 LS-RESOURCES OCCURS 20 TIMES.
             10 LS-RES-NAME    PIC X(64).
             10 LS-RES-FIELD-COUNT PIC 99.
             10 LS-RES-FIELDS OCCURS 20 TIMES.
                15 LS-RES-FIELD-NAME PIC X(64).
                15 LS-RES-FIELD-TYPE PIC X(16).
                15 LS-RES-FIELD-EDIT PIC 9.

       PROCEDURE DIVISION USING LS-API-URL LS-RESOURCE-TABLE.

       MAIN-LOGIC.
           PERFORM FETCH-SCHEMA
           PERFORM PARSE-RESOURCES
           PERFORM PARSE-FIELDS
           GOBACK.

       FETCH-SCHEMA.
           DISPLAY "Fetching OpenAPI spec..."

      *> Build URL
           MOVE LOW-VALUE TO WS-URL-Z
           STRING
               FUNCTION TRIM(LS-API-URL) DELIMITED BY SIZE
               "/openapi.json" DELIMITED BY SIZE
               LOW-VALUE DELIMITED BY SIZE
               INTO WS-URL-Z
           END-STRING

           CALL "cobol_http_get" USING
               BY REFERENCE WS-URL-Z
               BY REFERENCE WS-JSON-FILE
               BY REFERENCE WS-EMPTY
               RETURNING WS-RESULT
           END-CALL

           IF WS-RESULT NOT = 0
               DISPLAY "Failed to fetch OpenAPI spec: "
                   WS-RESULT
           END-IF
           .

       PARSE-RESOURCES.
           DISPLAY "Extracting resources..."

           CALL "cobol_json_resources" USING
               BY REFERENCE WS-JSON-FILE
               BY REFERENCE WS-RESOURCE-FILE
               RETURNING WS-RESULT
           END-CALL

           IF WS-RESULT NOT = 0
               DISPLAY "Failed to parse resources: " WS-RESULT
               GOBACK
           END-IF

           CALL "fopen" USING WS-RESOURCE-FILE WS-FOPEN-MODE
               RETURNING WS-FILE-PTR
           END-CALL
           IF WS-FILE-PTR = NULL
               DISPLAY "Failed to open resources file"
               GOBACK
           END-IF

           MOVE 0 TO LS-RESOURCE-COUNT
           MOVE 0 TO WS-READ-DONE
           PERFORM READ-RESOURCE-LINE
               UNTIL WS-READ-DONE = 1

           CALL "fclose" USING BY VALUE WS-FILE-PTR
           END-CALL

           DISPLAY "Found " LS-RESOURCE-COUNT " resources"
           .

       READ-RESOURCE-LINE.
           MOVE LOW-VALUE TO WS-LINE
           CALL "fgets" USING
               BY REFERENCE WS-LINE
               BY VALUE 64
               BY VALUE WS-FILE-PTR
               RETURNING WS-FGETS-PTR
           END-CALL

           IF WS-FGETS-PTR = NULL
               MOVE 1 TO WS-READ-DONE
           ELSE
               PERFORM CLEAN-LINE
               IF FUNCTION TRIM(WS-LINE TRAILING)
                   NOT = SPACES
                   ADD 1 TO LS-RESOURCE-COUNT
                   MOVE SPACES
                       TO LS-RES-NAME(LS-RESOURCE-COUNT)
                   MOVE FUNCTION TRIM(WS-LINE TRAILING)
                       TO LS-RES-NAME(LS-RESOURCE-COUNT)
                   MOVE 0 TO
                       LS-RES-FIELD-COUNT(LS-RESOURCE-COUNT)
               END-IF
           END-IF
           .

      *> Extract fields for each resource
       PARSE-FIELDS.
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > LS-RESOURCE-COUNT

      *> Null-terminate resource name for C call
               MOVE LOW-VALUE TO WS-RES-NAME-Z
               STRING
                   FUNCTION TRIM(LS-RES-NAME(WS-IDX))
                       DELIMITED BY SIZE
                   LOW-VALUE DELIMITED BY SIZE
                   INTO WS-RES-NAME-Z
               END-STRING

               CALL "cobol_json_fields" USING
                   BY REFERENCE WS-JSON-FILE
                   BY REFERENCE WS-RES-NAME-Z
                   BY REFERENCE WS-FIELDS-FILE
                   RETURNING WS-RESULT
               END-CALL

               IF WS-RESULT NOT = 0
                   DISPLAY "  No fields for "
                       LS-RES-NAME(WS-IDX)
               ELSE
                   CALL "fopen" USING
                       WS-FIELDS-FILE WS-FOPEN-MODE
                       RETURNING WS-FILE-PTR
                   END-CALL
                   IF WS-FILE-PTR NOT = NULL
                       MOVE 0 TO WS-READ-DONE
                       PERFORM READ-FIELD-LINE
                           UNTIL WS-READ-DONE = 1
                       CALL "fclose" USING
                           BY VALUE WS-FILE-PTR
                       END-CALL
                   END-IF
               END-IF

               DISPLAY "  "
                   FUNCTION TRIM(LS-RES-NAME(WS-IDX))
                   ": "
                   LS-RES-FIELD-COUNT(WS-IDX)
                   " fields"
           END-PERFORM
           .

       READ-FIELD-LINE.
           MOVE LOW-VALUE TO WS-LINE
           CALL "fgets" USING
               BY REFERENCE WS-LINE
               BY VALUE 256
               BY VALUE WS-FILE-PTR
               RETURNING WS-FGETS-PTR
           END-CALL

           IF WS-FGETS-PTR = NULL
               MOVE 1 TO WS-READ-DONE
           ELSE
               PERFORM CLEAN-LINE
               IF FUNCTION TRIM(WS-LINE TRAILING)
                   NOT = SPACES
                   ADD 1 TO LS-RES-FIELD-COUNT(WS-IDX)
      *> Parse TSV: name<tab>type<tab>editable
                   MOVE 0 TO WS-TAB1-POS
                   MOVE 0 TO WS-TAB2-POS
                   MOVE FUNCTION LENGTH(
                       FUNCTION TRIM(WS-LINE TRAILING))
                       TO WS-LINE-LEN
                   PERFORM VARYING WS-SCAN FROM 1 BY 1
                       UNTIL WS-SCAN > WS-LINE-LEN
                       IF WS-LINE(WS-SCAN:1) = X"09"
                           IF WS-TAB1-POS = 0
                               MOVE WS-SCAN TO WS-TAB1-POS
                           ELSE
                               MOVE WS-SCAN TO WS-TAB2-POS
                               EXIT PERFORM
                           END-IF
                       END-IF
                   END-PERFORM
                   IF WS-TAB1-POS > 1
                       MOVE SPACES TO LS-RES-FIELD-NAME(
                           WS-IDX,
                           LS-RES-FIELD-COUNT(WS-IDX))
                       MOVE WS-LINE(1:WS-TAB1-POS - 1)
                           TO LS-RES-FIELD-NAME(
                               WS-IDX,
                               LS-RES-FIELD-COUNT(WS-IDX))
                   END-IF
                   IF WS-TAB2-POS > WS-TAB1-POS
                       MOVE SPACES TO LS-RES-FIELD-TYPE(
                           WS-IDX,
                           LS-RES-FIELD-COUNT(WS-IDX))
                       MOVE WS-LINE(
                           WS-TAB1-POS + 1:
                           WS-TAB2-POS - WS-TAB1-POS - 1)
                           TO LS-RES-FIELD-TYPE(
                               WS-IDX,
                               LS-RES-FIELD-COUNT(WS-IDX))
                   END-IF
                   IF WS-TAB2-POS > 0
                       IF WS-LINE(WS-TAB2-POS + 1:1) = "1"
                           MOVE 1 TO LS-RES-FIELD-EDIT(
                               WS-IDX,
                               LS-RES-FIELD-COUNT(WS-IDX))
                       ELSE
                           MOVE 0 TO LS-RES-FIELD-EDIT(
                               WS-IDX,
                               LS-RES-FIELD-COUNT(WS-IDX))
                       END-IF
                   END-IF
               END-IF
           END-IF
           .

       CLEAN-LINE.
           INSPECT WS-LINE
               REPLACING ALL X"0A" BY SPACE
           INSPECT WS-LINE
               REPLACING ALL X"0D" BY SPACE
           INSPECT WS-LINE
               REPLACING ALL LOW-VALUE BY SPACE
           .

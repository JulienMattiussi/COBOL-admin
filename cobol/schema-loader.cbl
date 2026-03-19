      *> Fetches OpenAPI spec and extracts resources + fields
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SCHEMA-LOADER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-CMD               PIC X(512).
       01 WS-FOPEN-MODE        PIC X(4) VALUE Z"r".
       01 WS-FILE-PTR          USAGE POINTER.
       01 WS-FGETS-PTR         USAGE POINTER.
       01 WS-LINE              PIC X(64).
       01 WS-READ-DONE         PIC 9 VALUE 0.
       01 WS-RESOURCE-FILE     PIC X(256)
           VALUE Z"/tmp/resources.txt".
       01 WS-FIELDS-FILE       PIC X(256)
           VALUE Z"/tmp/fields.txt".
       01 WS-IDX               PIC 99 VALUE 0.
       01 WS-RES-NAME-UPPER    PIC X(64).

       LINKAGE SECTION.
       01 LS-API-URL           PIC X(256).
       01 LS-RESOURCE-TABLE.
          05 LS-RESOURCE-COUNT PIC 99.
          05 LS-RESOURCES OCCURS 20 TIMES.
             10 LS-RES-NAME    PIC X(64).
             10 LS-RES-FIELD-COUNT PIC 99.
             10 LS-RES-FIELDS OCCURS 20 TIMES.
                15 LS-RES-FIELD-NAME PIC X(64).

       PROCEDURE DIVISION USING LS-API-URL LS-RESOURCE-TABLE.

       MAIN-LOGIC.
           PERFORM FETCH-SCHEMA
           PERFORM PARSE-RESOURCES
           PERFORM PARSE-FIELDS
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
           MOVE 0 TO WS-READ-DONE
           PERFORM READ-RESOURCE-LINE
               UNTIL WS-READ-DONE = 1

           CALL "fclose" USING BY VALUE WS-FILE-PTR
           END-CALL

           DISPLAY "Found " LS-RESOURCE-COUNT " resources"
           .

       READ-RESOURCE-LINE.
           MOVE SPACES TO WS-LINE
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

      *> Extract fields for each resource from the OpenAPI schema
       PARSE-FIELDS.
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > LS-RESOURCE-COUNT

      *> Derive schema name: capitalize first letter
      *> e.g. "authors" -> "Author" (singular, capitalized)
      *> Use jq to find the schema that matches the resource
               MOVE LOW-VALUE TO WS-CMD
               STRING
                   "jq -r --arg res ""/"
                       DELIMITED BY SIZE
                   LS-RES-NAME(WS-IDX) DELIMITED BY SPACE
                   """ '" DELIMITED BY SIZE
                   ". as $root"
                       DELIMITED BY SIZE
                   " | (.paths[$res].get"
                       DELIMITED BY SIZE
                   ".responses[""200""]"
                       DELIMITED BY SIZE
                   ".content[""application/json""]"
                       DELIMITED BY SIZE
                   ".schema.items[""$ref""]"
                       DELIMITED BY SIZE
                   " // .paths[$res].get"
                       DELIMITED BY SIZE
                   ".responses[""200""]"
                       DELIMITED BY SIZE
                   ".content[""application/json""]"
                       DELIMITED BY SIZE
                   ".schema[""$ref""])"
                       DELIMITED BY SIZE
                   " | split(""/"")[-1] as $s"
                       DELIMITED BY SIZE
                   " | $root.components"
                       DELIMITED BY SIZE
                   ".schemas[$s]"
                       DELIMITED BY SIZE
                   ".properties|keys[]'"
                       DELIMITED BY SIZE
                   " /tmp/openapi.json"
                       DELIMITED BY SIZE
                   " > /tmp/fields.txt"
                       DELIMITED BY SIZE
                   INTO WS-CMD
               END-STRING
               CALL "SYSTEM" USING FUNCTION TRIM(WS-CMD)
               END-CALL

               CALL "fopen" USING WS-FIELDS-FILE WS-FOPEN-MODE
                   RETURNING WS-FILE-PTR
               END-CALL
               IF WS-FILE-PTR = NULL
                   DISPLAY "  No fields for "
                       LS-RES-NAME(WS-IDX)
               ELSE
                   MOVE 0 TO WS-READ-DONE
                   PERFORM READ-FIELD-LINE
                       UNTIL WS-READ-DONE = 1
                   CALL "fclose" USING BY VALUE WS-FILE-PTR
                   END-CALL
               END-IF

               DISPLAY "  "
                   FUNCTION TRIM(LS-RES-NAME(WS-IDX))
                   ": "
                   LS-RES-FIELD-COUNT(WS-IDX)
                   " fields"
           END-PERFORM
           .

       READ-FIELD-LINE.
           MOVE SPACES TO WS-LINE
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
                   ADD 1 TO LS-RES-FIELD-COUNT(WS-IDX)
                   MOVE SPACES TO LS-RES-FIELD-NAME(
                       WS-IDX,
                       LS-RES-FIELD-COUNT(WS-IDX))
                   MOVE FUNCTION TRIM(WS-LINE TRAILING)
                       TO LS-RES-FIELD-NAME(
                           WS-IDX,
                           LS-RES-FIELD-COUNT(WS-IDX))
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

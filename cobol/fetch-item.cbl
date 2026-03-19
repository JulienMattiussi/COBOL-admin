      *> Fetches a single item from the API as key-value TSV
      *> Outputs to /tmp/showdata.tsv with format: key<tab>value
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FETCH-ITEM.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-CMD               PIC X(1024).
       01 WS-CMD-PTR           PIC 9(4) COMP-5 VALUE 0.

       LINKAGE SECTION.
       01 LS-API-URL           PIC X(256).
       01 LS-RESOURCE-NAME     PIC X(64).
       01 LS-RESOURCE-ID       PIC X(10).

       PROCEDURE DIVISION USING
           LS-API-URL LS-RESOURCE-NAME LS-RESOURCE-ID.

       MAIN-LOGIC.
           MOVE LOW-VALUE TO WS-CMD
           STRING
               "curl -s '" DELIMITED BY SIZE
               LS-API-URL DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-NAME DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               LS-RESOURCE-ID DELIMITED BY SPACE
               "' | jq -r '" DELIMITED BY SIZE
               INTO WS-CMD
           END-STRING

      *> Find end of string for appending
           MOVE 0 TO WS-CMD-PTR
           INSPECT WS-CMD TALLYING WS-CMD-PTR
               FOR CHARACTERS BEFORE INITIAL LOW-VALUE
           ADD 1 TO WS-CMD-PTR

      *> jq: convert object to key<tab>value lines
      *> Arrays are joined with ", "
           STRING
               "to_entries[]"
                   DELIMITED BY SIZE
               " | if .value|type==""array"""
                   DELIMITED BY SIZE
               " then [.key,(.value|map(tostring)"
                   DELIMITED BY SIZE
               "|join("", ""))]"
                   DELIMITED BY SIZE
               " else [.key,(.value|tostring)] end"
                   DELIMITED BY SIZE
               " | @tsv'"
                   DELIMITED BY SIZE
               " > /tmp/showdata.tsv"
                   DELIMITED BY SIZE
               INTO WS-CMD WITH POINTER WS-CMD-PTR
           END-STRING

           CALL "SYSTEM" USING FUNCTION TRIM(WS-CMD)
           END-CALL

           GOBACK.

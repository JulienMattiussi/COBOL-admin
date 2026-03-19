      *> Detects if a field name references another resource
      *> Convention: field "postId" → resource "posts"
      *> Returns the resource name or SPACES if no match
       IDENTIFICATION DIVISION.
       PROGRAM-ID. REF-DETECT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FNAME-LEN         PIC 99 VALUE 0.
       01 WS-CANDIDATE          PIC X(64).
       01 WS-IDX               PIC 99 VALUE 0.

       LINKAGE SECTION.
       01 LS-FIELD-NAME        PIC X(64).
       01 LS-RESOURCE-TABLE.
          05 LS-RESOURCE-COUNT PIC 99.
          05 LS-RESOURCES OCCURS 20 TIMES.
             10 LS-RES-NAME    PIC X(64).
             10 LS-RES-FIELD-COUNT PIC 99.
             10 LS-RES-FIELDS OCCURS 20 TIMES.
                15 LS-RES-FIELD-NAME PIC X(64).
                15 LS-RES-FIELD-TYPE PIC X(16).
                15 LS-RES-FIELD-EDIT PIC 9.
       01 LS-REF-RESOURCE      PIC X(64).

       PROCEDURE DIVISION USING
           LS-FIELD-NAME LS-RESOURCE-TABLE LS-REF-RESOURCE.

       MAIN-LOGIC.
           MOVE SPACES TO LS-REF-RESOURCE

      *> Check if field name ends with "Id"
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(LS-FIELD-NAME))
               TO WS-FNAME-LEN

           IF WS-FNAME-LEN <= 2
               GOBACK
           END-IF

           IF LS-FIELD-NAME(WS-FNAME-LEN - 1:2)
               NOT = "Id"
               GOBACK
           END-IF

      *> Strip "Id", append "s"
           MOVE SPACES TO WS-CANDIDATE
           STRING
               LS-FIELD-NAME(1:WS-FNAME-LEN - 2)
                   DELIMITED BY SIZE
               "s" DELIMITED BY SIZE
               INTO WS-CANDIDATE
           END-STRING

      *> Check if resource exists
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > LS-RESOURCE-COUNT
               IF LS-RES-NAME(WS-IDX) = WS-CANDIDATE
                   MOVE WS-CANDIDATE TO LS-REF-RESOURCE
                   EXIT PERFORM
               END-IF
           END-PERFORM

           GOBACK.

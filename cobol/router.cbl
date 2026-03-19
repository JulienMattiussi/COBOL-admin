      *> Matches a request path to a route type
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ROUTER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX               PIC 99 VALUE 0.

       LINKAGE SECTION.
       01 LS-REQUEST-PATH      PIC X(512).
       01 LS-PATH-LEN          PIC 9(4) COMP-5.
       01 LS-ROUTE-TYPE        PIC X(10).
       01 LS-ROUTE-RESOURCE    PIC X(64).
       01 LS-RESOURCE-TABLE.
          05 LS-RESOURCE-COUNT PIC 99.
          05 LS-RESOURCES OCCURS 20 TIMES.
             10 LS-RES-NAME    PIC X(64).

       PROCEDURE DIVISION USING
           LS-REQUEST-PATH LS-PATH-LEN
           LS-ROUTE-TYPE LS-ROUTE-RESOURCE
           LS-RESOURCE-TABLE.

       MAIN-LOGIC.
           MOVE "NOTFOUND" TO LS-ROUTE-TYPE
           MOVE SPACES TO LS-ROUTE-RESOURCE

           IF FUNCTION TRIM(LS-REQUEST-PATH) = "/"
               MOVE "HOME" TO LS-ROUTE-TYPE
           ELSE
               IF LS-PATH-LEN > 6
                   IF LS-REQUEST-PATH(1:6) = "/list/"
                       MOVE LS-REQUEST-PATH(
                           7:LS-PATH-LEN - 6)
                           TO LS-ROUTE-RESOURCE
                       PERFORM VARYING WS-IDX FROM 1 BY 1
                           UNTIL WS-IDX > LS-RESOURCE-COUNT
                           IF LS-RES-NAME(WS-IDX)
                               = LS-ROUTE-RESOURCE
                               MOVE "LIST" TO LS-ROUTE-TYPE
                               EXIT PERFORM
                           END-IF
                       END-PERFORM
                   END-IF
               END-IF
           END-IF

           GOBACK.

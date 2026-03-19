      *> Resource table (populated from OpenAPI spec)
       01 WS-RESOURCE-TABLE.
          05 WS-RESOURCE-COUNT PIC 99 VALUE 0.
          05 WS-RESOURCES OCCURS 20 TIMES.
             10 WS-RES-NAME    PIC X(64).
             10 WS-RES-FIELD-COUNT PIC 99 VALUE 0.
             10 WS-RES-FIELDS OCCURS 20 TIMES.
                15 WS-RES-FIELD-NAME PIC X(64).
       01 WS-RES-IDX           PIC 99 VALUE 0.

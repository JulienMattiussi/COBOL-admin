      *> COBOL Admin - Main entry point
      *> Orchestrates HTTP server, routing, and page rendering
       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBOL-ADMIN.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "ws-config.cpy".
       COPY "ws-socket.cpy".
       COPY "ws-http.cpy".
       COPY "ws-html.cpy".
       COPY "ws-resource.cpy".
       COPY "ws-route.cpy".

      *> Send loop
       01 WS-SEND-OFFSET       PIC 9(8) COMP-5 VALUE 0.
       01 WS-SEND-REMAINING    PIC 9(8) COMP-5 VALUE 0.

      *> Layout action
       01 WS-LAYOUT-ACTION     PIC X(5).

      *> Resource lookup
       01 WS-MATCHED-RES-IDX   PIC 99 VALUE 0.

      *> Static file serving
       01 WS-STATIC-BODY       PIC X(32768).
       01 WS-STATIC-LEN        PIC 9(8) COMP-5 VALUE 0.
       01 WS-CONTENT-TYPE      PIC X(64).
       01 WS-STATIC-FOUND      PIC 9 VALUE 0.

       PROCEDURE DIVISION.

       MAIN-LOGIC.
           DISPLAY "COBOL Admin Server starting..."

      *> Read API URL from environment, fallback to default
           ACCEPT API-BASE-URL FROM ENVIRONMENT "API_BASE_URL"
           IF API-BASE-URL = SPACES
               MOVE "http://server:3000" TO API-BASE-URL
           END-IF
           DISPLAY "API URL: " FUNCTION TRIM(API-BASE-URL)

           CALL "SCHEMA-LOADER" USING
               API-BASE-URL WS-RESOURCE-TABLE
           END-CALL

           PERFORM INIT-SOCKET
           IF SOCKET-HANDLE < 0
               DISPLAY "Failed to initialize socket"
               STOP RUN
           END-IF

           PERFORM ACCEPT-LOOP UNTIL 1 = 0
           STOP RUN.

      *>
      *> INIT-SOCKET: Create, bind and listen on TCP socket
      *>
       INIT-SOCKET.
           CALL "socket" USING
               BY VALUE 2 BY VALUE 1 BY VALUE 0
               RETURNING SOCKET-HANDLE
           END-CALL
           IF SOCKET-HANDLE < 0
               DISPLAY "Socket creation failed"
               GOBACK
           END-IF

           CALL "setsockopt" USING
               BY VALUE SOCKET-HANDLE
               BY VALUE 1 BY VALUE 2
               BY REFERENCE SOCKET-OPT BY VALUE 4
               RETURNING SOCKET-RESULT
           END-CALL

           COMPUTE WS-PORT-NETWORK =
               FUNCTION MOD(SERVER-PORT, 256) * 256 +
               SERVER-PORT / 256
           MOVE WS-PORT-NETWORK TO SA-PORT
           MOVE FUNCTION BYTE-LENGTH(SERVER-ADDRESS) TO ADDR-LEN

           CALL "bind" USING
               BY VALUE SOCKET-HANDLE
               BY REFERENCE SERVER-ADDRESS
               BY VALUE ADDR-LEN
               RETURNING SOCKET-RESULT
           END-CALL
           IF SOCKET-RESULT < 0
               DISPLAY "Bind failed"
               GOBACK
           END-IF

           CALL "listen" USING
               BY VALUE SOCKET-HANDLE BY VALUE 10
               RETURNING SOCKET-RESULT
           END-CALL
           IF SOCKET-RESULT < 0
               DISPLAY "Listen failed"
               GOBACK
           END-IF

           DISPLAY "Server listening on port " SERVER-PORT
           .

      *>
      *> ACCEPT-LOOP: Accept client connections
      *>
       ACCEPT-LOOP.
           MOVE FUNCTION BYTE-LENGTH(SERVER-ADDRESS) TO ADDR-LEN

           CALL "accept" USING
               BY VALUE SOCKET-HANDLE
               BY REFERENCE SERVER-ADDRESS
               BY REFERENCE ADDR-LEN
               RETURNING CLIENT-SOCKET
           END-CALL

           IF CLIENT-SOCKET < 0
               DISPLAY "Accept failed"
               GOBACK
           END-IF

           ADD 1 TO WS-REQUEST-COUNT
           PERFORM HANDLE-REQUEST

           CALL "close" USING BY VALUE CLIENT-SOCKET
           END-CALL
           .

      *>
      *> HANDLE-REQUEST: Read, route, build page, respond
      *>
       HANDLE-REQUEST.
           MOVE LOW-VALUE TO REQUEST-BUFFER
           MOVE LOW-VALUE TO RESPONSE-BUFFER
           MOVE 0 TO RESPONSE-LEN

           CALL "recv" USING
               BY VALUE CLIENT-SOCKET
               BY REFERENCE REQUEST-BUFFER
               BY VALUE 4096 BY VALUE 0
               RETURNING BYTES-READ
           END-CALL

           IF BYTES-READ <= 0
               GOBACK
           END-IF

      *> Parse request
           CALL "HTTP-PARSE" USING
               REQUEST-BUFFER WS-REQUEST-METHOD
               WS-REQUEST-PATH WS-PATH-LEN
               WS-REQUEST-BODY WS-BODY-LEN
           END-CALL

           DISPLAY "Request #" WS-REQUEST-COUNT " "
               FUNCTION TRIM(WS-REQUEST-METHOD) " "
               FUNCTION TRIM(WS-REQUEST-PATH)

      *> Route the request
           CALL "ROUTER" USING
               WS-REQUEST-PATH WS-PATH-LEN
               WS-ROUTE-TYPE WS-ROUTE-RESOURCE
               WS-RESOURCE-TABLE
               WS-PAGE WS-PER-PAGE
               WS-ROUTE-ID WS-STATIC-PATH
           END-CALL

      *> Handle POST on edit: submit form and redirect
           IF ROUTE-EDIT AND
               FUNCTION TRIM(WS-REQUEST-METHOD) = "POST"
               PERFORM VARYING WS-MATCHED-RES-IDX
                   FROM 1 BY 1
                   UNTIL WS-MATCHED-RES-IDX >
                       WS-RESOURCE-COUNT
                   IF WS-RES-NAME(WS-MATCHED-RES-IDX)
                       = WS-ROUTE-RESOURCE
                       EXIT PERFORM
                   END-IF
               END-PERFORM
               CALL "FORM-SUBMIT" USING
                   API-BASE-URL WS-ROUTE-RESOURCE
                   WS-ROUTE-ID
                   WS-REQUEST-BODY WS-BODY-LEN
               END-CALL
               PERFORM SEND-REDIRECT
           ELSE

      *> Handle static files separately
           IF ROUTE-STATIC
               CALL "SERVE-STATIC" USING
                   WS-STATIC-PATH
                   WS-STATIC-BODY WS-STATIC-LEN
                   WS-CONTENT-TYPE WS-STATIC-FOUND
               END-CALL
               IF WS-STATIC-FOUND = 1
                   PERFORM SEND-STATIC-RESPONSE
               ELSE
                   MOVE "NOTFOUND" TO WS-ROUTE-TYPE
               END-IF
           END-IF

           IF NOT ROUTE-STATIC
      *> Build HTML page
               MOVE LOW-VALUE TO HTML-BODY
               MOVE 1 TO HTML-LEN

               MOVE "HEAD" TO WS-LAYOUT-ACTION
               CALL "PAGE-LAYOUT" USING
                   HTML-BODY HTML-LEN
                   WS-RESOURCE-TABLE WS-LAYOUT-ACTION
               END-CALL

               EVALUATE TRUE
                   WHEN ROUTE-HOME
                       CALL "PAGE-HOME" USING
                           HTML-BODY HTML-LEN
                   WHEN ROUTE-LIST
                       PERFORM VARYING WS-MATCHED-RES-IDX
                           FROM 1 BY 1
                           UNTIL WS-MATCHED-RES-IDX >
                               WS-RESOURCE-COUNT
                           IF WS-RES-NAME(WS-MATCHED-RES-IDX)
                               = WS-ROUTE-RESOURCE
                               EXIT PERFORM
                           END-IF
                       END-PERFORM
                       CALL "PAGE-LIST" USING
                           HTML-BODY HTML-LEN
                           WS-ROUTE-RESOURCE
                           API-BASE-URL
                           WS-PAGE WS-PER-PAGE WS-TOTAL-COUNT
                           WS-RESOURCE-TABLE
                           WS-MATCHED-RES-IDX
                   WHEN ROUTE-SHOW
                       PERFORM VARYING WS-MATCHED-RES-IDX
                           FROM 1 BY 1
                           UNTIL WS-MATCHED-RES-IDX >
                               WS-RESOURCE-COUNT
                           IF WS-RES-NAME(WS-MATCHED-RES-IDX)
                               = WS-ROUTE-RESOURCE
                               EXIT PERFORM
                           END-IF
                       END-PERFORM
                       CALL "PAGE-SHOW" USING
                           HTML-BODY HTML-LEN
                           WS-ROUTE-RESOURCE WS-ROUTE-ID
                           API-BASE-URL
                           WS-RESOURCE-TABLE
                           WS-MATCHED-RES-IDX
                   WHEN ROUTE-EDIT
                       PERFORM VARYING WS-MATCHED-RES-IDX
                           FROM 1 BY 1
                           UNTIL WS-MATCHED-RES-IDX >
                               WS-RESOURCE-COUNT
                           IF WS-RES-NAME(WS-MATCHED-RES-IDX)
                               = WS-ROUTE-RESOURCE
                               EXIT PERFORM
                           END-IF
                       END-PERFORM
                       CALL "PAGE-EDIT" USING
                           HTML-BODY HTML-LEN
                           WS-ROUTE-RESOURCE WS-ROUTE-ID
                           API-BASE-URL
                           WS-RESOURCE-TABLE
                           WS-MATCHED-RES-IDX
                   WHEN ROUTE-NOT-FOUND
                       CALL "PAGE-404" USING
                           HTML-BODY HTML-LEN
               END-EVALUATE

               MOVE "FOOT" TO WS-LAYOUT-ACTION
               CALL "PAGE-LAYOUT" USING
                   HTML-BODY HTML-LEN
                   WS-RESOURCE-TABLE WS-LAYOUT-ACTION
               END-CALL

               SUBTRACT 1 FROM HTML-LEN
               PERFORM SEND-RESPONSE
           END-IF
           END-IF
           .

      *>
      *> SEND-STATIC-RESPONSE: Send static file with content-type
      *>
       SEND-REDIRECT.
           MOVE LOW-VALUE TO RESPONSE-BUFFER

           STRING
               "HTTP/1.1 303 See Other" DELIMITED BY SIZE
               WS-CRLF DELIMITED BY SIZE
               "Location: /show/" DELIMITED BY SIZE
               WS-ROUTE-RESOURCE DELIMITED BY SPACE
               "/" DELIMITED BY SIZE
               WS-ROUTE-ID DELIMITED BY SPACE
               WS-CRLF DELIMITED BY SIZE
               "Connection: close" DELIMITED BY SIZE
               WS-CRLF DELIMITED BY SIZE
               WS-CRLF DELIMITED BY SIZE
               INTO RESPONSE-BUFFER
           END-STRING

           MOVE 0 TO RESPONSE-LEN
           INSPECT RESPONSE-BUFFER TALLYING RESPONSE-LEN
               FOR CHARACTERS BEFORE INITIAL LOW-VALUE

           CALL "send" USING
               BY VALUE CLIENT-SOCKET
               BY REFERENCE RESPONSE-BUFFER
               BY VALUE RESPONSE-LEN
               BY VALUE 0
               RETURNING BYTES-SENT
           END-CALL
           .

      *>
       SEND-STATIC-RESPONSE.
           MOVE LOW-VALUE TO RESPONSE-BUFFER
           MOVE WS-STATIC-LEN TO WS-LEN-STR

           STRING
               "HTTP/1.1 200 OK" DELIMITED BY SIZE
               WS-CRLF DELIMITED BY SIZE
               "Content-Type: " DELIMITED BY SIZE
               WS-CONTENT-TYPE DELIMITED BY SPACE
               WS-CRLF DELIMITED BY SIZE
               "Content-Length: " DELIMITED BY SIZE
               WS-LEN-STR DELIMITED BY SPACE
               WS-CRLF DELIMITED BY SIZE
               "Connection: close" DELIMITED BY SIZE
               WS-CRLF DELIMITED BY SIZE
               WS-CRLF DELIMITED BY SIZE
               INTO RESPONSE-BUFFER
           END-STRING

           MOVE 0 TO RESPONSE-LEN
           INSPECT RESPONSE-BUFFER TALLYING RESPONSE-LEN
               FOR CHARACTERS BEFORE INITIAL LOW-VALUE

           MOVE WS-STATIC-BODY(1:WS-STATIC-LEN)
               TO RESPONSE-BUFFER(RESPONSE-LEN + 1:
                   WS-STATIC-LEN)
           ADD WS-STATIC-LEN TO RESPONSE-LEN

           MOVE 0 TO WS-SEND-OFFSET
           MOVE RESPONSE-LEN TO WS-SEND-REMAINING

           PERFORM UNTIL WS-SEND-REMAINING <= 0
               CALL "send" USING
                   BY VALUE CLIENT-SOCKET
                   BY REFERENCE
                       RESPONSE-BUFFER(WS-SEND-OFFSET + 1:
                           WS-SEND-REMAINING)
                   BY VALUE WS-SEND-REMAINING
                   BY VALUE 0
                   RETURNING BYTES-SENT
               END-CALL
               IF BYTES-SENT <= 0
                   EXIT PERFORM
               END-IF
               ADD BYTES-SENT TO WS-SEND-OFFSET
               SUBTRACT BYTES-SENT FROM WS-SEND-REMAINING
           END-PERFORM
           .

      *>
      *> SEND-RESPONSE: Build HTTP headers and send
      *>
       SEND-RESPONSE.
           MOVE LOW-VALUE TO RESPONSE-BUFFER
           MOVE HTML-LEN TO WS-LEN-STR

           STRING
               "HTTP/1.1 200 OK" DELIMITED BY SIZE
               WS-CRLF DELIMITED BY SIZE
               "Content-Type: text/html; charset=utf-8"
                   DELIMITED BY SIZE
               WS-CRLF DELIMITED BY SIZE
               "Content-Length: " DELIMITED BY SIZE
               WS-LEN-STR DELIMITED BY SPACE
               WS-CRLF DELIMITED BY SIZE
               "Connection: close" DELIMITED BY SIZE
               WS-CRLF DELIMITED BY SIZE
               WS-CRLF DELIMITED BY SIZE
               INTO RESPONSE-BUFFER
           END-STRING

           MOVE 0 TO RESPONSE-LEN
           INSPECT RESPONSE-BUFFER TALLYING RESPONSE-LEN
               FOR CHARACTERS BEFORE INITIAL LOW-VALUE

           MOVE HTML-BODY(1:HTML-LEN)
               TO RESPONSE-BUFFER(RESPONSE-LEN + 1:HTML-LEN)
           ADD HTML-LEN TO RESPONSE-LEN

           MOVE 0 TO WS-SEND-OFFSET
           MOVE RESPONSE-LEN TO WS-SEND-REMAINING

           PERFORM UNTIL WS-SEND-REMAINING <= 0
               CALL "send" USING
                   BY VALUE CLIENT-SOCKET
                   BY REFERENCE
                       RESPONSE-BUFFER(WS-SEND-OFFSET + 1:
                           WS-SEND-REMAINING)
                   BY VALUE WS-SEND-REMAINING
                   BY VALUE 0
                   RETURNING BYTES-SENT
               END-CALL
               IF BYTES-SENT <= 0
                   EXIT PERFORM
               END-IF
               ADD BYTES-SENT TO WS-SEND-OFFSET
               SUBTRACT BYTES-SENT FROM WS-SEND-REMAINING
           END-PERFORM
           .

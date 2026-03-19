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

       PROCEDURE DIVISION.

       MAIN-LOGIC.
           DISPLAY "COBOL Admin Server starting..."

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
           MOVE SPACES TO REQUEST-BUFFER
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

      *> Parse request path
           CALL "HTTP-PARSE" USING
               REQUEST-BUFFER WS-REQUEST-PATH WS-PATH-LEN
           END-CALL

           DISPLAY "Request #" WS-REQUEST-COUNT " "
               FUNCTION TRIM(WS-REQUEST-PATH)

      *> Route the request
           CALL "ROUTER" USING
               WS-REQUEST-PATH WS-PATH-LEN
               WS-ROUTE-TYPE WS-ROUTE-RESOURCE
               WS-RESOURCE-TABLE
           END-CALL

      *> Build page
           MOVE LOW-VALUE TO HTML-BODY
           MOVE 1 TO HTML-LEN

           MOVE "HEAD" TO WS-LAYOUT-ACTION
           CALL "PAGE-LAYOUT" USING
               HTML-BODY HTML-LEN
               WS-RESOURCE-TABLE WS-LAYOUT-ACTION
           END-CALL

           EVALUATE TRUE
               WHEN ROUTE-HOME
                   CALL "PAGE-HOME" USING HTML-BODY HTML-LEN
               WHEN ROUTE-LIST
                   CALL "PAGE-LIST" USING
                       HTML-BODY HTML-LEN WS-ROUTE-RESOURCE
               WHEN ROUTE-NOT-FOUND
                   CALL "PAGE-404" USING HTML-BODY HTML-LEN
           END-EVALUATE

           MOVE "FOOT" TO WS-LAYOUT-ACTION
           CALL "PAGE-LAYOUT" USING
               HTML-BODY HTML-LEN
               WS-RESOURCE-TABLE WS-LAYOUT-ACTION
           END-CALL

           SUBTRACT 1 FROM HTML-LEN

      *> Send HTTP response
           PERFORM SEND-RESPONSE
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

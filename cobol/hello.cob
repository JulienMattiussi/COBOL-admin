      *> COBOL HTTP server that fetches OpenAPI spec and displays it
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLO-SERVER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      *> Socket variables
       01 SOCKET-HANDLE        PIC S9(9) COMP-5.
       01 CLIENT-SOCKET        PIC S9(9) COMP-5.
       01 SOCKET-RESULT        PIC S9(9) COMP-5.
       01 BYTES-READ           PIC S9(9) COMP-5.
       01 BYTES-SENT           PIC S9(9) COMP-5.
       01 SOCKET-OPT           PIC 9(9) COMP-5 VALUE 1.

      *> Socket address structure (struct sockaddr_in)
       01 SERVER-ADDRESS.
          05 SA-FAMILY         PIC 9(4) COMP-5 VALUE 2.
          05 SA-PORT           PIC 9(4) COMP-5.
          05 SA-ADDR           PIC 9(8) COMP-5 VALUE 0.
          05 FILLER            PIC X(8) VALUE SPACES.
       01 ADDR-LEN             PIC 9(9) COMP-5 VALUE 16.

      *> Server config
       01 SERVER-PORT          PIC 9(5) VALUE 8080.
       01 WS-PORT-NETWORK      PIC 9(4) COMP-5.

      *> Buffers
       01 REQUEST-BUFFER       PIC X(4096).
       01 RESPONSE-BUFFER      PIC X(65536).
       01 RESPONSE-LEN         PIC 9(8) COMP-5 VALUE 0.

      *> HTTP helpers
       01 WS-CRLF              PIC XX VALUE X"0D0A".
       01 WS-REQUEST-COUNT     PIC 9(8) VALUE 0.

      *> HTML body
       01 HTML-BODY            PIC X(32768).
       01 HTML-LEN             PIC 9(8) COMP-5 VALUE 0.
       01 WS-LEN-STR           PIC X(10).

      *> JSON fetch via C file I/O
       01 WS-JSON-PATH         PIC X(256) VALUE Z"/tmp/openapi.json".
       01 WS-FOPEN-MODE        PIC X(4) VALUE Z"r".
       01 WS-FILE-PTR          USAGE POINTER.
       01 WS-JSON-DATA         PIC X(24576).
       01 WS-JSON-LEN          PIC 9(8) COMP-5 VALUE 0.
       01 WS-CURL-CMD          PIC X(512).

      *> Send loop
       01 WS-SEND-OFFSET       PIC 9(8) COMP-5 VALUE 0.
       01 WS-SEND-REMAINING    PIC 9(8) COMP-5 VALUE 0.

       PROCEDURE DIVISION.

       MAIN-LOGIC.
           DISPLAY "COBOL Admin Server starting..."

           PERFORM FETCH-SCHEMA

           PERFORM INIT-SOCKET
           IF SOCKET-HANDLE < 0
               DISPLAY "Failed to initialize socket"
               STOP RUN
           END-IF

           PERFORM ACCEPT-LOOP UNTIL 1 = 0
           STOP RUN.

       FETCH-SCHEMA.
           DISPLAY "Fetching OpenAPI spec from server..."

           MOVE LOW-VALUE TO WS-CURL-CMD
           STRING
               "curl -s http://server:3000/openapi.json"
               " -o /tmp/openapi.json"
               DELIMITED BY SIZE
               INTO WS-CURL-CMD
           END-STRING

           CALL "SYSTEM" USING
               FUNCTION TRIM(WS-CURL-CMD)
           END-CALL

      *> Read entire file using C fread
           MOVE LOW-VALUE TO WS-JSON-DATA

           CALL "fopen" USING
               WS-JSON-PATH
               WS-FOPEN-MODE
               RETURNING WS-FILE-PTR
           END-CALL

           IF WS-FILE-PTR = NULL
               DISPLAY "Failed to open JSON file"
               GOBACK
           END-IF

           CALL "fread" USING
               BY REFERENCE WS-JSON-DATA
               BY VALUE 1
               BY VALUE 24576
               BY VALUE WS-FILE-PTR
               RETURNING WS-JSON-LEN
           END-CALL

           CALL "fclose" USING
               BY VALUE WS-FILE-PTR
           END-CALL

           DISPLAY "OpenAPI spec loaded: " WS-JSON-LEN " bytes"
           .

       INIT-SOCKET.
      *> Create TCP socket
           CALL "socket" USING
               BY VALUE 2 BY VALUE 1 BY VALUE 0
               RETURNING SOCKET-HANDLE
           END-CALL
           IF SOCKET-HANDLE < 0
               DISPLAY "Socket creation failed"
               GOBACK
           END-IF

      *> Set SO_REUSEADDR
           CALL "setsockopt" USING
               BY VALUE SOCKET-HANDLE
               BY VALUE 1 BY VALUE 2
               BY REFERENCE SOCKET-OPT
               BY VALUE 4
               RETURNING SOCKET-RESULT
           END-CALL

      *> Convert port to network byte order
           COMPUTE WS-PORT-NETWORK =
               FUNCTION MOD(SERVER-PORT, 256) * 256 +
               SERVER-PORT / 256
           MOVE WS-PORT-NETWORK TO SA-PORT
           MOVE FUNCTION BYTE-LENGTH(SERVER-ADDRESS) TO ADDR-LEN

      *> Bind
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

      *> Listen
           CALL "listen" USING
               BY VALUE SOCKET-HANDLE
               BY VALUE 10
               RETURNING SOCKET-RESULT
           END-CALL
           IF SOCKET-RESULT < 0
               DISPLAY "Listen failed"
               GOBACK
           END-IF

           DISPLAY "Server listening on port " SERVER-PORT
           .

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

       HANDLE-REQUEST.
           MOVE SPACES TO REQUEST-BUFFER
           MOVE LOW-VALUE TO RESPONSE-BUFFER
           MOVE 0 TO RESPONSE-LEN

      *> Read request
           CALL "recv" USING
               BY VALUE CLIENT-SOCKET
               BY REFERENCE REQUEST-BUFFER
               BY VALUE 4096
               BY VALUE 0
               RETURNING BYTES-READ
           END-CALL

           IF BYTES-READ <= 0
               GOBACK
           END-IF

           DISPLAY "Request #" WS-REQUEST-COUNT

      *> Build HTML body
           PERFORM BUILD-HTML

      *> Build HTTP response headers
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

      *> Calculate header length
           MOVE 0 TO RESPONSE-LEN
           INSPECT RESPONSE-BUFFER TALLYING RESPONSE-LEN
               FOR CHARACTERS BEFORE INITIAL LOW-VALUE

      *> Append HTML body after headers
           MOVE HTML-BODY(1:HTML-LEN)
               TO RESPONSE-BUFFER(RESPONSE-LEN + 1:HTML-LEN)
           ADD HTML-LEN TO RESPONSE-LEN

      *> Send response (may need multiple sends for large responses)
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

       BUILD-HTML.
           MOVE LOW-VALUE TO HTML-BODY
           MOVE 1 TO HTML-LEN

           STRING
               "<!DOCTYPE html>" DELIMITED BY SIZE
               "<html><head>"    DELIMITED BY SIZE
               "<meta charset='utf-8'>" DELIMITED BY SIZE
               "<title>COBOL Admin</title>" DELIMITED BY SIZE
               "<style>"         DELIMITED BY SIZE
               "body{font-family:sans-serif;margin:40px auto;"
                   DELIMITED BY SIZE
               "max-width:900px;padding:0 10px;}"
                   DELIMITED BY SIZE
               "h1{color:#2c3e50;}"
                   DELIMITED BY SIZE
               "pre{background:#f4f4f4;padding:16px;"
                   DELIMITED BY SIZE
               "border-radius:8px;overflow-x:auto;"
                   DELIMITED BY SIZE
               "font-size:13px;max-height:600px;"
                   DELIMITED BY SIZE
               "overflow-y:auto;white-space:pre-wrap;}"
                   DELIMITED BY SIZE
               "</style>"        DELIMITED BY SIZE
               "</head><body>"   DELIMITED BY SIZE
               "<h1>Hello, COBOL Admin!</h1>" DELIMITED BY SIZE
               "<p>Served by GnuCOBOL.</p>" DELIMITED BY SIZE
               "<h2>OpenAPI Schema</h2>" DELIMITED BY SIZE
               "<pre>" DELIMITED BY SIZE
               INTO HTML-BODY
               WITH POINTER HTML-LEN
           END-STRING

      *> Append JSON data directly (it may contain spaces, newlines)
           MOVE WS-JSON-DATA(1:WS-JSON-LEN)
               TO HTML-BODY(HTML-LEN:WS-JSON-LEN)
           ADD WS-JSON-LEN TO HTML-LEN

      *> Append closing tags
           STRING
               "</pre>" DELIMITED BY SIZE
               "</body></html>"  DELIMITED BY SIZE
               INTO HTML-BODY
               WITH POINTER HTML-LEN
           END-STRING

           SUBTRACT 1 FROM HTML-LEN
           .

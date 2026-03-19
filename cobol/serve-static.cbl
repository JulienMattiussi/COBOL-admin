      *> Serves a static file from the static/ directory
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SERVE-STATIC.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FILE-PATH-Z       PIC X(512).
       01 WS-FOPEN-MODE        PIC X(4) VALUE Z"r".
       01 WS-FILE-PTR          USAGE POINTER.
       01 WS-PATH-LEN          PIC 9(4) COMP-5 VALUE 0.
       01 WS-SCAN              PIC 9(4) COMP-5 VALUE 0.
       01 WS-PATH-VALID        PIC 9 VALUE 0.

       LINKAGE SECTION.
       01 LS-STATIC-PATH       PIC X(512).
       01 LS-BODY              PIC X(32768).
       01 LS-BODY-LEN          PIC 9(8) COMP-5.
       01 LS-CONTENT-TYPE      PIC X(64).
       01 LS-FOUND             PIC 9.

       PROCEDURE DIVISION USING
           LS-STATIC-PATH LS-BODY LS-BODY-LEN
           LS-CONTENT-TYPE LS-FOUND.

       MAIN-LOGIC.
           MOVE 0 TO LS-FOUND
           MOVE 0 TO LS-BODY-LEN
           MOVE SPACES TO LS-CONTENT-TYPE

      *> Validate path: reject traversal and unsafe chars
           PERFORM VALIDATE-PATH
           IF WS-PATH-VALID = 0
               GOBACK
           END-IF

      *> Determine content type
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(LS-STATIC-PATH)) TO WS-PATH-LEN
           IF WS-PATH-LEN >= 4
               IF LS-STATIC-PATH(WS-PATH-LEN - 3:4) = ".css"
                   MOVE "text/css" TO LS-CONTENT-TYPE
               ELSE
                   MOVE "application/octet-stream"
                       TO LS-CONTENT-TYPE
               END-IF
           END-IF

      *> Build null-terminated path: static/ + requested path
           MOVE LOW-VALUE TO WS-FILE-PATH-Z
           STRING
               "static/" DELIMITED BY SIZE
               LS-STATIC-PATH DELIMITED BY SPACE
               LOW-VALUE DELIMITED BY SIZE
               INTO WS-FILE-PATH-Z
           END-STRING

      *> Read file
           CALL "fopen" USING
               WS-FILE-PATH-Z WS-FOPEN-MODE
               RETURNING WS-FILE-PTR
           END-CALL

           IF WS-FILE-PTR = NULL
               GOBACK
           END-IF

           MOVE LOW-VALUE TO LS-BODY
           CALL "fread" USING
               BY REFERENCE LS-BODY
               BY VALUE 1 BY VALUE 32768
               BY VALUE WS-FILE-PTR
               RETURNING LS-BODY-LEN
           END-CALL

           CALL "fclose" USING BY VALUE WS-FILE-PTR
           END-CALL

           MOVE 1 TO LS-FOUND
           GOBACK.

       VALIDATE-PATH.
           MOVE 1 TO WS-PATH-VALID
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(LS-STATIC-PATH)) TO WS-PATH-LEN

      *> Reject empty paths
           IF WS-PATH-LEN = 0
               MOVE 0 TO WS-PATH-VALID
               GOBACK
           END-IF

      *> Reject paths starting with /
           IF LS-STATIC-PATH(1:1) = "/"
               MOVE 0 TO WS-PATH-VALID
               GOBACK
           END-IF

      *> Reject paths containing ".."
           PERFORM VARYING WS-SCAN FROM 1 BY 1
               UNTIL WS-SCAN >= WS-PATH-LEN
               IF LS-STATIC-PATH(WS-SCAN:2) = ".."
                   MOVE 0 TO WS-PATH-VALID
                   GOBACK
               END-IF
           END-PERFORM

      *> Reject paths containing null bytes
           PERFORM VARYING WS-SCAN FROM 1 BY 1
               UNTIL WS-SCAN > WS-PATH-LEN
               IF LS-STATIC-PATH(WS-SCAN:1) = LOW-VALUE
                   MOVE 0 TO WS-PATH-VALID
                   GOBACK
               END-IF
           END-PERFORM
           .

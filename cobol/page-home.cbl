      *> Builds the home page content using template engine
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAGE-HOME.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "ws-template.cpy".
       01 WS-TPL-ACTION          PIC X(6).
       01 WS-TPL-KEY             PIC X(256).
       01 WS-TPL-VALUE           PIC X(1024).
       01 WS-DUMMY-CONTENT       PIC X(1).
       01 WS-DUMMY-LEN           PIC 9(8) COMP-5 VALUE 0.

       LINKAGE SECTION.
       01 LS-HTML-BODY         PIC X(32768).
       01 LS-HTML-LEN          PIC 9(8) COMP-5.

       PROCEDURE DIVISION USING LS-HTML-BODY LS-HTML-LEN.

       MAIN-LOGIC.
           MOVE "RENDER" TO WS-TPL-ACTION
           MOVE "templates/home.html" TO WS-TPL-KEY
           MOVE SPACES TO WS-TPL-VALUE
           CALL "TEMPLATE-ENGINE" USING
               LS-HTML-BODY LS-HTML-LEN
               WS-TPL-ACTION WS-TPL-KEY WS-TPL-VALUE
               WS-TPL-VARS
               WS-DUMMY-CONTENT WS-DUMMY-LEN
           END-CALL
           GOBACK.

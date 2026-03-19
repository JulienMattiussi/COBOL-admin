       >>SOURCE FORMAT FREE
*> Tests for HTTP-PARSE module
identification division.
program-id. test-http-parse.

data division.
working-storage section.
01 ws-request-buffer    pic x(4096).
01 ws-request-method    pic x(10).
01 ws-request-path      pic x(512).
01 ws-path-len          pic 9(4) comp-5.
01 ws-request-body      pic x(4096).
01 ws-body-len          pic 9(4) comp-5.
01 ws-expected-len      pic 9(4) comp-5.

procedure division.

    perform test-simple-get.
    perform test-root-path.
    perform test-list-path.
    perform test-post-method.
    goback.

test-simple-get section.
    move spaces to ws-request-buffer
    move "GET /hello HTTP/1.1" to ws-request-buffer
    call "HTTP-PARSE" using
        ws-request-buffer ws-request-method
        ws-request-path ws-path-len
        ws-request-body ws-body-len
    end-call
    call "assert-equals" using "GET", ws-request-method(1:3).
    call "assert-equals" using "/hello", ws-request-path(1:6).
    move 6 to ws-expected-len
    call "assert-equals" using ws-expected-len, ws-path-len.

test-root-path section.
    move spaces to ws-request-buffer
    move "GET / HTTP/1.1" to ws-request-buffer
    call "HTTP-PARSE" using
        ws-request-buffer ws-request-method
        ws-request-path ws-path-len
        ws-request-body ws-body-len
    end-call
    call "assert-equals" using "/", ws-request-path(1:1).
    move 1 to ws-expected-len
    call "assert-equals" using ws-expected-len, ws-path-len.

test-list-path section.
    move spaces to ws-request-buffer
    move "GET /list/authors HTTP/1.1" to ws-request-buffer
    call "HTTP-PARSE" using
        ws-request-buffer ws-request-method
        ws-request-path ws-path-len
        ws-request-body ws-body-len
    end-call
    call "assert-equals" using "/list/authors",
        ws-request-path(1:13).
    move 13 to ws-expected-len
    call "assert-equals" using ws-expected-len, ws-path-len.

test-post-method section.
    move spaces to ws-request-buffer
    move "POST /edit/authors/1 HTTP/1.1" to ws-request-buffer
    call "HTTP-PARSE" using
        ws-request-buffer ws-request-method
        ws-request-path ws-path-len
        ws-request-body ws-body-len
    end-call
    call "assert-equals" using "POST", ws-request-method(1:4).
    call "assert-equals" using "/edit/authors/1",
        ws-request-path(1:15).

end program test-http-parse.

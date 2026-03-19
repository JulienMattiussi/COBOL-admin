       >>SOURCE FORMAT FREE
*> Tests for ROUTER module
identification division.
program-id. test-router.

data division.
working-storage section.
01 ws-request-path      pic x(512).
01 ws-path-len          pic 9(4) comp-5.
01 ws-route-type        pic x(10).
01 ws-route-resource    pic x(64).
01 ws-resource-table.
   05 ws-resource-count pic 99 value 3.
   05 ws-resources occurs 20 times.
      10 ws-res-name    pic x(64).

procedure division.

    *> Set up test resource table
    move "authors" to ws-res-name(1).
    move "posts" to ws-res-name(2).
    move "tags" to ws-res-name(3).

    perform test-home-route.
    perform test-list-valid.
    perform test-list-invalid.
    perform test-unknown-path.
    perform test-list-second-resource.
    goback.

test-home-route section.
    move spaces to ws-request-path
    move "/" to ws-request-path
    move 1 to ws-path-len
    call "ROUTER" using
        ws-request-path ws-path-len
        ws-route-type ws-route-resource
        ws-resource-table
    end-call
    call "assert-equals" using "HOME", ws-route-type(1:4).

test-list-valid section.
    move spaces to ws-request-path
    move "/list/authors" to ws-request-path
    move 13 to ws-path-len
    call "ROUTER" using
        ws-request-path ws-path-len
        ws-route-type ws-route-resource
        ws-resource-table
    end-call
    call "assert-equals" using "LIST", ws-route-type(1:4).
    call "assert-equals" using "authors", ws-route-resource(1:7).

test-list-invalid section.
    move spaces to ws-request-path
    move "/list/bogus" to ws-request-path
    move 11 to ws-path-len
    call "ROUTER" using
        ws-request-path ws-path-len
        ws-route-type ws-route-resource
        ws-resource-table
    end-call
    call "assert-equals" using "NOTFOUND", ws-route-type(1:8).

test-unknown-path section.
    move spaces to ws-request-path
    move "/something" to ws-request-path
    move 10 to ws-path-len
    call "ROUTER" using
        ws-request-path ws-path-len
        ws-route-type ws-route-resource
        ws-resource-table
    end-call
    call "assert-equals" using "NOTFOUND", ws-route-type(1:8).

test-list-second-resource section.
    move spaces to ws-request-path
    move "/list/posts" to ws-request-path
    move 11 to ws-path-len
    call "ROUTER" using
        ws-request-path ws-path-len
        ws-route-type ws-route-resource
        ws-resource-table
    end-call
    call "assert-equals" using "LIST", ws-route-type(1:4).
    call "assert-equals" using "posts", ws-route-resource(1:5).

end program test-router.

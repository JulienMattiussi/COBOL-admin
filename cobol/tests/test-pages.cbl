       >>SOURCE FORMAT FREE
*> Tests for page builder modules
identification division.
program-id. test-pages.

data division.
working-storage section.
01 ws-html-body         pic x(32768).
01 ws-html-len          pic 9(8) comp-5.
01 ws-resource-name     pic x(64).
01 ws-resource-table.
   05 ws-resource-count pic 99 value 2.
   05 ws-resources occurs 20 times.
      10 ws-res-name    pic x(64).
01 ws-action            pic x(5).

procedure division.

    move "authors" to ws-res-name(1).
    move "posts" to ws-res-name(2).

    perform test-page-home.
    perform test-page-list.
    perform test-page-404.
    perform test-layout-head.
    perform test-layout-foot.
    goback.

test-page-home section.
    move low-value to ws-html-body
    move 1 to ws-html-len
    call "PAGE-HOME" using ws-html-body ws-html-len
    end-call
    *> Check that output contains expected text
    call "assert-equals" using "<h1>Hello, COBOL Admin!</h1>",
        ws-html-body(1:28).

test-page-list section.
    move low-value to ws-html-body
    move 1 to ws-html-len
    move "posts" to ws-resource-name
    call "PAGE-LIST" using
        ws-html-body ws-html-len ws-resource-name
    end-call
    call "assert-equals" using "<h1>posts</h1>",
        ws-html-body(1:14).

test-page-404 section.
    move low-value to ws-html-body
    move 1 to ws-html-len
    call "PAGE-404" using ws-html-body ws-html-len
    end-call
    call "assert-equals" using "<h1>404 - Not Found</h1>",
        ws-html-body(1:24).

test-layout-head section.
    move low-value to ws-html-body
    move 1 to ws-html-len
    move "HEAD" to ws-action
    call "PAGE-LAYOUT" using
        ws-html-body ws-html-len
        ws-resource-table ws-action
    end-call
    *> Should start with DOCTYPE
    call "assert-equals" using "<!DOCTYPE html>",
        ws-html-body(1:15).

test-layout-foot section.
    move low-value to ws-html-body
    move 1 to ws-html-len
    move "FOOT" to ws-action
    call "PAGE-LAYOUT" using
        ws-html-body ws-html-len
        ws-resource-table ws-action
    end-call
    call "assert-equals" using "</main></body></html>",
        ws-html-body(1:21).

end program test-pages.

       >>SOURCE FORMAT FREE
*> Tests for HTML-ESCAPE module
identification division.
program-id. test-html-escape.

data division.
working-storage section.
01 ws-input            pic x(2048).
01 ws-input-len        pic 9(4) comp-5.
01 ws-output           pic x(4096).
01 ws-output-len       pic 9(4) comp-5.

procedure division.

    perform test-plain-text.
    perform test-angle-brackets.
    perform test-ampersand.
    perform test-quotes.
    perform test-mixed.
    goback.

test-plain-text section.
    move "hello world" to ws-input
    move 11 to ws-input-len
    call "HTML-ESCAPE" using
        ws-input ws-input-len ws-output ws-output-len
    end-call
    call "assert-equals" using "hello world",
        ws-output(1:11).

test-angle-brackets section.
    move "<script>alert(1)</script>" to ws-input
    move 31 to ws-input-len
    call "HTML-ESCAPE" using
        ws-input ws-input-len ws-output ws-output-len
    end-call
    call "assert-equals" using "&lt;script&gt;",
        ws-output(1:20).

test-ampersand section.
    move "a&b" to ws-input
    move 3 to ws-input-len
    call "HTML-ESCAPE" using
        ws-input ws-input-len ws-output ws-output-len
    end-call
    call "assert-equals" using "a&amp;b",
        ws-output(1:6).

test-quotes section.
    move 'say "hi"' to ws-input
    move 8 to ws-input-len
    call "HTML-ESCAPE" using
        ws-input ws-input-len ws-output ws-output-len
    end-call
    call "assert-equals" using "say &quot;hi&quot;",
        ws-output(1:17).

test-mixed section.
    move "<b>R&D</b>" to ws-input
    move 14 to ws-input-len
    call "HTML-ESCAPE" using
        ws-input ws-input-len ws-output ws-output-len
    end-call
    call "assert-equals" using "&lt;b&gt;R&amp;D&lt;/b&gt;",
        ws-output(1:27).

end program test-html-escape.

       >>SOURCE FORMAT FREE
*> Tests for SHELL-SANITIZE module
identification division.
program-id. test-shell-sanitize.

data division.
working-storage section.
01 ws-input            pic x(512).
01 ws-input-len        pic 9(4) comp-5.
01 ws-safe             pic 9.
01 ws-expected         pic 9.

procedure division.

    perform test-safe-id.
    perform test-safe-url.
    perform test-semicolon.
    perform test-backtick.
    perform test-pipe.
    perform test-dollar.
    perform test-ampersand.
    perform test-parentheses.
    goback.

test-safe-id section.
    move "42" to ws-input
    move 2 to ws-input-len
    call "SHELL-SANITIZE" using ws-input ws-input-len ws-safe
    end-call
    move 1 to ws-expected
    call "assert-equals" using ws-expected, ws-safe.

test-safe-url section.
    move "http://server:3000" to ws-input
    move 18 to ws-input-len
    call "SHELL-SANITIZE" using ws-input ws-input-len ws-safe
    end-call
    move 1 to ws-expected
    call "assert-equals" using ws-expected, ws-safe.

test-semicolon section.
    move "1;rm -rf /" to ws-input
    move 11 to ws-input-len
    call "SHELL-SANITIZE" using ws-input ws-input-len ws-safe
    end-call
    move 0 to ws-expected
    call "assert-equals" using ws-expected, ws-safe.

test-backtick section.
    move "1`whoami`" to ws-input
    move 9 to ws-input-len
    call "SHELL-SANITIZE" using ws-input ws-input-len ws-safe
    end-call
    move 0 to ws-expected
    call "assert-equals" using ws-expected, ws-safe.

test-pipe section.
    move "1|cat /etc/passwd" to ws-input
    move 17 to ws-input-len
    call "SHELL-SANITIZE" using ws-input ws-input-len ws-safe
    end-call
    move 0 to ws-expected
    call "assert-equals" using ws-expected, ws-safe.

test-dollar section.
    move "$(whoami)" to ws-input
    move 9 to ws-input-len
    call "SHELL-SANITIZE" using ws-input ws-input-len ws-safe
    end-call
    move 0 to ws-expected
    call "assert-equals" using ws-expected, ws-safe.

test-ampersand section.
    move "1&&echo hacked" to ws-input
    move 14 to ws-input-len
    call "SHELL-SANITIZE" using ws-input ws-input-len ws-safe
    end-call
    move 0 to ws-expected
    call "assert-equals" using ws-expected, ws-safe.

test-parentheses section.
    move "1$(id)" to ws-input
    move 6 to ws-input-len
    call "SHELL-SANITIZE" using ws-input ws-input-len ws-safe
    end-call
    move 0 to ws-expected
    call "assert-equals" using ws-expected, ws-safe.

end program test-shell-sanitize.

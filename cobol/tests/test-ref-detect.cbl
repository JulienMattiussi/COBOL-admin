       >>SOURCE FORMAT FREE
*> Tests for REF-DETECT module
identification division.
program-id. test-ref-detect.

data division.
working-storage section.
01 ws-field-name       pic x(64).
01 ws-ref-result       pic x(64).
01 ws-resource-table.
   05 ws-resource-count pic 99 value 3.
   05 ws-resources occurs 20 times.
      10 ws-res-name    pic x(64).
      10 ws-res-field-count pic 99.
      10 ws-res-fields occurs 20 times.
         15 ws-res-field-name pic x(64).
         15 ws-res-field-type pic x(16).
         15 ws-res-field-edit pic 9.

procedure division.

    initialize ws-resource-table
    move 3 to ws-resource-count
    move "authors" to ws-res-name(1)
    move "posts" to ws-res-name(2)
    move "tags" to ws-res-name(3)

    perform test-valid-ref.
    perform test-valid-ref-2.
    perform test-no-match.
    perform test-not-ref-field.
    perform test-id-field.
    goback.

test-valid-ref section.
    move "authorId" to ws-field-name
    call "REF-DETECT" using
        ws-field-name ws-resource-table ws-ref-result
    end-call
    call "assert-equals" using "authors",
        ws-ref-result(1:7).

test-valid-ref-2 section.
    move "postId" to ws-field-name
    call "REF-DETECT" using
        ws-field-name ws-resource-table ws-ref-result
    end-call
    call "assert-equals" using "posts",
        ws-ref-result(1:5).

test-no-match section.
    move "categoryId" to ws-field-name
    call "REF-DETECT" using
        ws-field-name ws-resource-table ws-ref-result
    end-call
    call "assert-equals" using " ",
        ws-ref-result(1:1).

test-not-ref-field section.
    move "email" to ws-field-name
    call "REF-DETECT" using
        ws-field-name ws-resource-table ws-ref-result
    end-call
    call "assert-equals" using " ",
        ws-ref-result(1:1).

test-id-field section.
    move "id" to ws-field-name
    call "REF-DETECT" using
        ws-field-name ws-resource-table ws-ref-result
    end-call
    call "assert-equals" using " ",
        ws-ref-result(1:1).

end program test-ref-detect.

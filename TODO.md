# COBOL Admin — TODO

## Critical (Security)

- [x] Add path validation to serve-static.cbl (prevent path traversal like `../../etc/passwd`)
- [x] Add HTML escaping for all values injected into HTML (XSS risk in page-list, page-show, page-edit)
- [x] Sanitize resource names and field values before interpolating into `CALL "SYSTEM"` shell commands (command injection)
- [x] Replace all `CALL "SYSTEM"` (curl/jq/python3) with C library calls (libcurl + cJSON) — zero shell attack surface

## High (Code Duplication / Maintainability)

- [x] Extract shared `fetch-item.cbl` module — FETCH-ITEM logic is duplicated between page-show.cbl and page-edit.cbl
- [x] Extract shared `ref-detect.cbl` module — reference detection ("ends with Id, pluralize, check resource table") is duplicated between page-list.cbl and page-show.cbl
- [x] Extract resource lookup loop in main.cbl to a shared paragraph — the "find WS-MATCHED-RES-IDX" block is repeated 4 times
- [x] Consolidate 3 near-identical SEND-* paragraphs in main.cbl (SEND-RESPONSE, SEND-STATIC-RESPONSE, SEND-REDIRECT) — extract shared send loop
- [x] Consolidate 4 identical BUILD-PERPAGE-LINK-COMMON-* paragraphs in page-list.cbl into a single parameterized paragraph

## Medium (Robustness)

- [x] Add error handling for C helper failures — show user-friendly error when API is down or returns errors
- [ ] Clean up temp files after use — hardcoded `/tmp/` files; concurrent requests cause race conditions
- [x] Validate API responses — handle 404/500 from the API instead of silently rendering empty pages
- [x] Validate page/perPage range — prevent extreme values like `perPage=99999`
- [x] Handle form submit errors — show error message if PUT fails instead of silently redirecting

## Low (Quality / Performance)

- [ ] Refactor main.cbl — extract socket accept loop and send logic (currently ~415 lines doing too much)
- [ ] Move schema-loader's jq command (~50 lines of STRING concatenation) to an external shell script
- [ ] Document buffer limits (4KB request, 32KB HTML, 20 resources, 20 fields) and handle overflow gracefully
- [ ] Standardize buffer initialization — use LOW-VALUE consistently instead of mixing with SPACES
- [ ] Add unit tests for page-list, page-show, page-edit, pagination, form-submit, serve-static, schema-loader

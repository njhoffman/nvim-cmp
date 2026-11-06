# TODO

Open issues and suggestions for the njhoffman/nvim-cmp fork. GitHub issues are disabled on this fork, so this file is the tracker.

Reviewed: 2026-11-06

Baseline at review: `make test` 83/83 passing and `luacheck` clean on NVIM v0.13.0-dev. `main` is 69 ahead and 107 behind `upstream/main` (fe29aba, 2026-11-05), merge-base 51260c0 (2023-10-24). Items marked "reproduced" were confirmed with a throwaway spec; the others come from reading the code or diff, and say so where it matters.

## 1. Fork bugs

- [x] **Icon column width is never measured.** (p1) [bug] Any non-empty `icon` renders jammed against the next column, and the window is mis-sized. Reproduced.
      Where: `lua/cmp/view/custom_entries_view.lua:152-154` updates only abbr, kind and menu, while `:96`, `:173-174` and `:303` read `column_width.icon`.
      Cause: 5a7ce31 (icon field) was cherry-picked without its dependency 28ab7f7, which loops over `formatting.fields`.
      Evidence: `fields = {'icon','abbr','menu'}` with icon `XXXX` gives `icon = 0`, `kind = 4` (a field not displayed) and the line ` XXXXalpha mm  `. By reading, the extmark offsets at `:96` shift too, because `column_width - width` goes negative.
      Fix: applied 28ab7f7's loop, which also stops hidden fields from widening the window. Spec: `lua/cmp/view/custom_entries_view_spec.lua`.

- [x] **`cmp.setup()` stacks a new set of autocmds on every call.** (p1) [bug] Each call adds another full set of event subscribers, and calling only `cmp.setup.cmdline/filetype/buffer/global` adds none. Reproduced.
      Where: `lua/cmp/init.lua` `__call` runs `autocmds.setup(cmp)` each time; `lua/cmp/autocmds.lua` has no guard. Fork-only since b1e64f3; upstream subscribes once at module load.
      Evidence: `autocmd.events.TextChangedI` holds 0, then 1, then 2 subscribers across two `cmp.setup({})` calls.
      Impact: after 3 calls, `CmdlineChanged` ran `on_change` 3 times and `CursorMovedI` ran `on_moved` 3 times (measured), and `complete_done`/`confirm_done` handlers fire N times, so `recently_used` records N times. `TextChangedI` ran once, only because all `async.debounce` closures share one timer. Calling `cmp.setup` several times is common with plugin managers and per-project config.
      Also: `trigger_debounce` is read once at subscribe time, so later `cmp.setup` calls and filetype or buffer overrides are ignored. It was also missing from `doc/cmp.txt`.
      Fix: subscribe once at load, as upstream does, and read the debounce value on each change. Documented `performance.trigger_debounce`.

- [x] **`cmp.query` leaves its synthetic results in live sources.** (p1) [bug] After `:CmpQuery`, real completion can be served stale query items and skip the source request. Reproduced at source level.
      Where: `lua/cmp/init.lua` `cmp.query` calls `s:reset()` and `s:complete(ctx)` on the sources registered in `cmp.core.sources`, and never restores them.
      Evidence: after `cmp.query({query='pri'})` the source stays COMPLETED with `request_offset = 1`. A real typed `x` at column 1 returns nil, makes no new request (calls stays 1) and keeps `prior_item`. `CmdlineLeave` resets before the command body runs, so it does not clear this; any request offset equal to the query's is affected.
      Fix: probes through a throwaway `source.new(name, s.source)`, which also stops it wiping a live menu's entries. Specs are in `lua/cmp/init_spec.lua`.

- [x] **Source hangs in FETCHING when `items` is `vim.NIL`.** (p1) [bug] The response handler raises on `#vim.NIL`, so the callback never fires. Reproduced.
      Where: `lua/cmp/source.lua:354-355`.
      Evidence: a source returning `{ items = vim.NIL }` stays in status FETCHING with the callback never called. The 0.1.1 `vim.NIL` cherry-pick covers item fields only, not this check. Upstream hit it with arduino-language-server.
      Fix: ported 7d850f3 by hand (it conflicted on the fork's `debug.log_retrieval` lines) and also handled `response` itself being `vim.NIL`.

- [ ] **`async.debounce` shares one timer and has a no-op wrapper.** (p3) [bug] Every debounced function cancels every other, and `vim.schedule_wrap` does nothing there.
      Where: `lua/cmp/utils/async.lua:26-37`. `timer_id` is module-level, which is harmless while `autocmds.lua` is the only caller. `vim.schedule_wrap(func(unpack(args)))` calls `func` immediately and wraps its return value, so the wrapper is never used.
      Fix: move `timer_id` into the closure and call `func` directly from the timer callback.

- [x] **Finish the `vim.str_byteindex` migration.** (p2) [bug] `to_utf8` still uses the legacy signature, on the default UTF-16 path. Reproduced (`vim.deprecate` fires).
      Where: `lua/cmp/types/lsp.lua:68`, missed by 52d75e8.
      Risk: the legacy form is scheduled for removal in Neovim 1.0. The call sits inside `pcall`, whose failure branch returns the position unconverted, so removal would silently produce wrong columns on multibyte lines instead of an error.
      Fix: uses the new signature on 0.11+ and keeps the old one on 0.10 until a minimum version is chosen. Specs in `lua/cmp/types/lsp_spec.lua`.

- [x] **`:CmpQuery` popup ignores keys on source rows.** (p2) [bug] `table.insert(line_map, nil)` is a no-op, so `line_map` was offset from the buffer. Found while writing view specs.
      Where: `lua/cmp/view/query_view.lua`. Reproduced: the cursor parked on the summary line and `<CR>` did nothing on a source row. Fixed, with `lua/cmp/view/query_view_spec.lua`.

- [ ] **`:CmpQuery` differs from `:CmpStatus` and blocks the UI.** (p3) [bug] `main` ignores buffer config, and the callback-style API is actually synchronous.
      Where: `resolve_query_sources` reads `config.global.sources`, while `:CmpStatus main` reflects the active config. `cmp.query` spins in `vim.wait` for up to `timeout` (2s by default) on the main loop.
      Also: `:CmpQuery` cannot choose a cmdtype (`sub`), and `count` is the raw source total rather than matches for the query, which may surprise given the "query" framing.
      Fix: use `config.get()` semantics for `main`, finish via callback instead of waiting, and add a `sub` argument.

- [ ] **Menu can disappear when `top_padding` exceeds the space above.** (p3) [bug] With little room, the menu flips above the cursor and the height calculation goes negative.
      Where: `lua/cmp/view/custom_entries_view.lua:203`, `height = math.min(height, row - 1 - top_padding)`.
      Evidence: `lines=10`, `row=1`, `top_padding=5` flips to `bottom_up` without an error. That the window then fails to show is from reading the code, not observed. Only affects very small terminals.
      Fix: skip the flip when the space above is smaller than the space below. Compare upstream PR #2234 before writing this.

## 2. Upstream sync

- [x] **Decide on `compare.sort_text` as a default comparator.** (p2) [feature] Upstream enabled it in 8c82d0b; the fork has it commented out, so LSP `sortText` ordering is ignored by default.
      Where: `lua/cmp/config/default.lua:77`. Applies cleanly, but changes result ordering for everyone without custom comparators, and `CLAUDE.md` documents the current order. I found no record of whether this was deliberate. Decided: enabled, between kind and length as upstream has it, and documented.

- [x] **Port `cmp.resubscribe` for mini.snippets.** (p2) [bug] 1250990 is absent, yet the README's setup example mentions `MiniSnippets` (`README.md:85`), so following it can give outdated completion items.
      Done. The pick applied cleanly but needed an `autocmd` require in `lua/cmp/init.lua`, which the hook caught. The README and `doc/cmp.txt` text was already there and called a function that did not exist.

- [x] **Default `snippet.expand` to `vim.snippet`.** (p2) [feature] The fork's default still raises "snippet engine is not configured"; upstream uses `vim.snippet` on 0.10+.
      Where: `lua/cmp/config/default.lua:36`. Done by hand, with no version check now that the minimum is 0.11.

- [x] **Take the November 2026 perf commits.** (p2) [perf] Four upstream perf changes from 2026-11-05, none yet in the fork.
      Applies cleanly: fe29aba (`char.lua` lookup tables), 0cff98b (`str.oneline`), 9db1d76 (lazy entry cache). Conflicts: e04302f (`view.open` filters each source once); `lua/cmp/view.lua` has the same double `get_entries` call, so it is worth porting by hand.
      Done, not benchmarked. Open upstream PRs #2243 and #2244 (`ensure_nil`) moved to the watch list.

- [ ] **Do not cherry-pick 2ffe79f (TextChanged only on text added) by itself.** (p2) [chore] It has known regressions, and it overlaps with the fork's debounce.
      Its author's open follow-up #2228 says it discards pastes and other plugins' text changes. From the diff, it only fires on a cursor advance of exactly one byte, so multibyte input is also suppressed. The conflict is with `lua/cmp/autocmds.lua`, which upstream does not have.
      Fix: test whether upstream issue #1303 reproduces under `trigger_debounce` first; if it does, port 2ffe79f and #2228 together. The commit's `docs_view` `row` fix is already in the fork.

- [x] **Preserve `buflisted` when applying text edits.** (p3) [bug] 1e1900b was absent. It does not reproduce on 0.13-dev, but v0.11.0's `apply_text_edits` forces `buflisted = true`.
      Where: `lua/cmp/core.lua:435,439,488` call `vim.lsp.util.apply_text_edits` directly. Ported once the minimum became 0.11. The v0.11.0 behaviour was read from its source, and CI covers that version.

- [x] **Record the upstream sync point.** (p2) [chore] The nominal "107 behind" is mostly noise and has to be re-derived each time, because adapted cherry-picks hash differently.
      Apart from the commits named in projects 1 and 2, the review found these already applied or superseded: keymap regexes (`keymap.lua:20` is a superset), `vim.uv` over `vim.loop`, `get_selected_index`, resolve merging, `CmdwinEnter` (`autocmds.lua:39`) and reverse lookup (`misc.tbl_add_reverse_lookup`). c273707 (typos) is applied. 4c1ca82 is already present; cd2cf0c, 2fb2a3c and a70bdcf do not apply cleanly and were not reviewed line by line.
      Done: `UPSTREAM.md` keeps the last-reviewed hash (fe29aba) and a skip list with reasons, so the next scan only reads new commits. A line-matching script needs comments stripped: it scored 8c82d0b as 100% applied because of the commented-out line.

- [ ] **Watch open upstream PRs.** (p3) [chore] Possibly useful, judged by title only (not reviewed).
      #2177 feedkeys inserting text into the buffer, #2234 and #2235 menu position and anchoring, #2231 mapping fallbacks losing abbreviations, #2165 redundant `UIEnter` subscription (`plugin/cmp.lua:31`), #2032 docs height with wrapped lines, #2230 `PreselectMode` type, #2243 and #2244 `ensure_nil` perf.

## 3. Compatibility

- [x] **Declare a minimum Neovim version and remove dead gates.** (p2) [refactor] The real floor is at least 0.10, but the code and docs imply otherwise.
      `vim.uv` is used unconditionally (`utils/async.lua:191` at require time, so older versions fail on load), while gates for 0.8 remain (`utils/keymap.lua:19,267`, `view/custom_entries_view.lua:475`) and `plugin/cmp.lua:6` still checks for `nvim_create_autocmd`.
      `misc.to_vimindex` (`utils/misc.lua:229`) and `types/lsp.lua:89,112` use the 0.11 signature with no gate, while `misc.to_utfindex` has one. By reading, on 0.10 the `pcall` swallows the error and returns wrong indexes silently.
      Fix: the floor is 0.11. It is stated in the README and `:h cmp`, fails clearly below it, and is tested in CI.

- [ ] **Private API dependency in the docs view.** (p3) [chore] `vim.lsp.util._make_floating_popup_size` can change without notice. Where: `lua/cmp/view/docs_view.lua:82`. It exists on 0.13-dev, and upstream uses it too. Consider a small local implementation if it ever breaks.

## 4. Tooling and release

- [x] **`.githooks/pre-commit` silently skips lint and tests.** (p2) [bug] Under dash, `${BASH_SOURCE[0]}` is a bad substitution, and the script keeps going. Reproduced for the path step only; the hook itself was not run.
      The shebang is `#!/bin/sh`. Evaluated under `sh`, `DIR` resolves to `~/ghq/github.com`, so by reading, `make pre-commit` fails there, and without `set -e` the exit status comes from the final loop, so the commit proceeds. It is also not installed in this clone (`.git/hooks/pre-commit` is absent).
      Second bug: re-adding every staged path stages unstaged hunks in partially staged files.
      `init.sh` has no shebang, uses the same `BASH_SOURCE`, and runs `rm .git/hooks/*`.
      Fix: uses `git rev-parse --show-toplevel` and `set -e`, drops the `git add` loop, and `init.sh` now sets `core.hooksPath` instead of copying. Tested with real commits in a scratch clone. Run `./init.sh` to enable it in a clone.

- [x] **Resolve the release flow and CHANGELOG format.** (p2) [chore] release-please's generated format conflicts with the project's Keep a Changelog convention, and unreleased changes are not recorded.
      `CHANGELOG.md` has no `[Unreleased]` section and is mixed hand and generated text. Neither 5457e71 nor 52d75e8 is in it on `main`. The unmerged `origin/release-please--branches--main` (0.1.9) lists only 52d75e8, because release-please leaves `refactor:` commits out of its notes, so the deprecated API work in 5457e71 is unrecorded everywhere. There is no `VERSION` or `version.txt`, although `release-type: simple` normally tracks `version.txt`.
      Decided: removed the workflow; `CHANGELOG.md` and `VERSION` are maintained by hand with `vX.Y.Z` tags. Older entries keep their original format. The pending PR #1 and its branch `release-please--branches--main` still need closing on GitHub.

- [x] **Modernize CI.** (p2) [chore] CI only tests nightly, so the compatibility gates and any stable-release break go unnoticed.
      Where: `.github/workflows/integration.yaml` (`checkout@v2`), `format.yaml` (`checkout@v3`, stylua v0.16.1).
      Fix: added a matrix of v0.11.0, stable and nightly, bumped actions and stylua, and added a format check job.

- [x] **Formatting has drifted.** (p3) [chore] Since auto-format was turned off in ce3f840, nothing enforces it.
      `lua/` is clean and CI now checks it, with `make format-check` locally. `plugin/cmp.lua` is still outside that path and has inconsistent quoting and spacing.

- [ ] **Remove stale pull-request remotes.** (p3) [chore] All six have since merged upstream, so they only slow down `git fetch` and clutter branch listings.
      `pull-1420` (82ba05c), `pull-1677` (5e1fa02), `pull-1688` (0b751f6), `pull-1689` (55734c8), `pull-1701` (5124cdd), `pull-1723` (c01a038). `pull-1701/feat/always_indicate_snippets` is unmerged upstream, but the fork already has it as 66d6057. Remove with `git remote remove`.

## 5. Tests

- [ ] **Add view-layer specs.** (p2) [test] `lua/cmp/view/` has no specs, and that is where the fork's custom features live; the icon bug in project 1 went through this gap.
      Done: column widths, `vertical_positioning`, `top_padding` on the completion menu, `query_view`, and the `expandable_indicator` marker.
      Still to do: `lua/cmp/view/docs_view.lua` (`col_offset`, `top_padding`), `native_entries_view`, `wildmenu_entries_view` and `ghost_text_view`.

- [ ] **Add regression specs alongside the fixes above.** (p2) [test] Each p1 bug in project 1 needs a spec with its fix. Repeated `cmp.setup`, `vim.NIL` responses and `cmp.query` state isolation are done.
      Also add `lua/cmp/config/compare.lua` and `lua/cmp/utils/window.lua`, which have no direct spec today, and take upstream's fuzzy matcher placeholder from 36eb3a6 (`#1420`) as a real test case.

## 6. Documentation

- [x] **README and rockspec still describe upstream.** (p2) [docs] Install instructions and metadata point away from this fork.
      `README.md:46` and `doc/cmp.txt:55` use `Plug 'hrsh7th/nvim-cmp'`; `nvim-cmp-scm-1.rockspec` has hrsh7th for `homepage` and `source`.
      The fork notice (`README.md:12`) says "on top of upstream `v0.1.0`" with a small set of maintenance commits. In fact the fork branched in 2023 and adds its own features (`top_padding`, `:CmpStatus` contexts, `:CmpQuery`, `:CmpDebugOn`), and upstream's own 0.1.0 is still an unmerged release PR (#2211), so the number is also ambiguous.
      Fix: rewrote the notice with a feature list, pointed it at `UPSTREAM.md`, and stated that version numbers are the fork's own. Install examples and the rockspec now point at this fork.

- [ ] **Small comment and doc corrections.** (p3) [docs] Several comments are wrong or stale.
      `CLAUDE.md`: the async budget is "1us per step", but `async_budget = 1` is in ms (`utils/async.lua:194`, `types/cmp.lua:110`).
      `lua/cmp/source.lua`, `source.complete`: "Return true if not trigger completion" is inverted; it returns true when the request was sent, and `cmp.query` relies on that.
      `lua/cmp/init.lua`, `cmp.gather_status`: `@param context` does not match the parameter name `scope`.
      Marker comments to resolve: `lua/cmp/entry.lua:94` and `lua/cmp/types/lsp.lua:287`.

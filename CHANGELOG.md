# Changelog

## [0.1.7](https://github.com/njhoffman/nvim-cmp/compare/v0.1.6...v0.1.7) (2026-04-26)

### Features

- `:CmpStatus` (any context) now lists ready / unavailable sources in priority order — group index first, then position within the group — and annotates each name with a `G.O` suffix (e.g. `lazydev 1.1`, `copilot 2.1`, `nvim_lsp 2.2`). Sources without an explicit `group_index` default to group `1`.

## [0.1.6](https://github.com/njhoffman/nvim-cmp/compare/v0.1.5...v0.1.6) (2026-04-26)

### Bug Fixes

- `:CmpStatus main` no longer lists sources that are only configured for `cmdline` / `filetype` / `buffer` contexts. Sources owned by those scopes (e.g. `cmdline`, `cmdline_history`) appear under their own `:CmpStatus cmdline` / `:CmpStatus filetype` output instead of cluttering main's "unused" bucket. Truly registered-but-unconfigured sources still show up there.

## [0.1.5](https://github.com/njhoffman/nvim-cmp/compare/v0.1.4...v0.1.5) (2026-04-25)

### Bug Fixes

- forward `top_padding` through `cmp.config.window.bordered()`. The helper curates an explicit list of keys it forwards from its `opts` argument; `top_padding` was missing from that list, so values passed via `cmp.config.window.bordered({ top_padding = N })` were silently dropped before the merge.

## [0.1.4](https://github.com/njhoffman/nvim-cmp/compare/v0.1.3...v0.1.4) (2026-04-25)

### Features

- new `window.completion.top_padding` and `window.documentation.top_padding` options. Integer ≥ 0 (default `0`); inserts that many rows of vertical gap between the cursor and the window. Applied symmetrically when the window opens above the cursor (`view.entries.vertical_positioning = 'above'|'auto'`). The two windows have independent settings.

### Chores

- ci: `format.yaml` workflow switched to `workflow_dispatch` so stylua no longer auto-rewrites code on push.

## [0.1.3](https://github.com/njhoffman/nvim-cmp/compare/v0.1.2...v0.1.3) (2026-04-25)

### Features

- `:CmpStatus` now accepts an optional context argument: `main` (default), `cmdline`, or `filetype`. Cmdline and filetype contexts list one section per registered cmdtype/filetype with that scope's configured sources only.
- new `:CmpDebugOn` / `:CmpDebugOff` toggle pair for `cmp.utils.debug.flag`. Only one of the two is registered at any time; invoking it flips the flag and swaps which command is available.
- new `cmp.gather_status(context)` helper that returns the structured status buckets per scope (used internally by `:CmpStatus`, available for plugin authors).

## [0.1.2](https://github.com/njhoffman/nvim-cmp/compare/v0.1.1...v0.1.2) (2026-04-25)

### Bug Fixes

- run the `CmdlineEnter` handler synchronously so `cmp.core:prepare()` registers cmdline mappings while `is_cmdline_mode()` still returns true (partial port of upstream [#2214](https://github.com/hrsh7th/nvim-cmp/pull/2214)). The PR's other change (config merge order) was deliberately not applied — it inverts the documented `onetime > cmdline > filetype > buffer > global` priority because `misc.merge` resolves leaf collisions in favor of `tbl1`, not `tbl2`.

## [0.1.1](https://github.com/njhoffman/nvim-cmp/compare/v0.1.0...v0.1.1) (2026-04-25)

### Bug Fixes

- convert `vim.NIL` in client response items and `itemDefaults` to `nil` ([#2217](https://github.com/hrsh7th/nvim-cmp/issues/2217)) ([3d28a52](https://github.com/hrsh7th/nvim-cmp/commit/3d28a52587567e9b63c804d73bdb0a13d0170b37)), fixes [#2212](https://github.com/hrsh7th/nvim-cmp/issues/2212)

### Chores

- format Lua sources with stylua (CI auto-format)

## [0.1.0](https://github.com/njhoffman/nvim-cmp/compare/v0.0.2...v0.1.0) (2026-04-25)

This release tracks upstream `hrsh7th/nvim-cmp` `v0.1.0` and adds three
fork-specific maintenance commits.

### Features (from upstream v0.1.0)

- `view.entries.vertical_positioning = 'above' | 'below' | 'auto'` ([#1701](https://github.com/hrsh7th/nvim-cmp/issues/1701)) ([5124cdd](https://github.com/hrsh7th/nvim-cmp/commit/5124cdd05549b7dac75b1968cf5f63091bd84b6f))
- `window.completion.max_height` for the completion window ([#2202](https://github.com/hrsh7th/nvim-cmp/issues/2202)) ([d78fb3b](https://github.com/hrsh7th/nvim-cmp/commit/d78fb3b64eedb701c9939f97361c06483af575e0))
- `col_offset` option for the docs view ([de894da](https://github.com/hrsh7th/nvim-cmp/commit/de894daa2dd81f021038e3fe3a185703e7b57642)), closes [#1528](https://github.com/hrsh7th/nvim-cmp/issues/1528)
- icon and icon highlight separation ([#2190](https://github.com/hrsh7th/nvim-cmp/issues/2190)) ([5a7ce31](https://github.com/hrsh7th/nvim-cmp/commit/5a7ce3198d74537be7d9c92825fed00f5b4546e4))
- respect the `winborder` global variable for completion / documentation borders ([#2206](https://github.com/hrsh7th/nvim-cmp/issues/2206)) ([0aa22f4](https://github.com/hrsh7th/nvim-cmp/commit/0aa22f42e63b4976161433b292db754e2723fa4d))

### Bug Fixes (from upstream v0.1.0)

- handle `winborder` in Neovim 0.11 ([#2150](https://github.com/hrsh7th/nvim-cmp/issues/2150)) ([30d2593](https://github.com/hrsh7th/nvim-cmp/commit/30d259327208bf2129724e7db22a912d8b9be6a2))
- use `vim.lsp.config` instead of `require('lspconfig')` ([cf22c9e](https://github.com/hrsh7th/nvim-cmp/commit/cf22c9e))
- use `winborder` for window menu and fix scrollbar window ([#2158](https://github.com/hrsh7th/nvim-cmp/issues/2158)) ([686c17a](https://github.com/hrsh7th/nvim-cmp/commit/686c17addb51401fd2d1faf2fcd1f9327797e712))
- unicode partial-char completion ([#2183](https://github.com/hrsh7th/nvim-cmp/issues/2183)) ([2c019de](https://github.com/hrsh7th/nvim-cmp/commit/2c019de76894f2f9b57ce341755ce354f019ec1b))
- type mismatch in documentation configuration ([#2182](https://github.com/hrsh7th/nvim-cmp/issues/2182)) ([c4f7dc7](https://github.com/hrsh7th/nvim-cmp/commit/c4f7dc770cdebfc9723333175bcd88d9cdbe8408))
- missing required fields in formatting config ([b5311ab](https://github.com/hrsh7th/nvim-cmp/commit/b5311ab))
- ref-fix backward compatibility ([059e894](https://github.com/hrsh7th/nvim-cmp/commit/059e89495b3ec09395262f16b1ad441a38081d04))
- improve backward compatibility ([3fce8d9](https://github.com/hrsh7th/nvim-cmp/commit/3fce8d9))
- remove redundant `and true` ([#2207](https://github.com/hrsh7th/nvim-cmp/issues/2207)) ([9a0a90a](https://github.com/hrsh7th/nvim-cmp/commit/9a0a90a6f722c813272cbbd8bde2b350988843a9))

### Chores (from upstream v0.1.0)

- automated releases and luarocks uploads ([#1923](https://github.com/hrsh7th/nvim-cmp/issues/1923)) ([85bbfad](https://github.com/hrsh7th/nvim-cmp/commit/85bbfad))
- update `nvim-neorocks/luarocks-tag-release` ([#2199](https://github.com/hrsh7th/nvim-cmp/issues/2199)) ([106c4bc](https://github.com/hrsh7th/nvim-cmp/commit/106c4bcc053a5da783bf4a9d907b6f22485c2ea0))
- fix `Setup tools` step failure ([a4182e0](https://github.com/hrsh7th/nvim-cmp/commit/a4182e0))
- stop using deprecated functions ([c4c784a](https://github.com/hrsh7th/nvim-cmp/commit/c4c784a))

### Fork-specific

- fix docs view row positioning under bottom-up layout (`be45fd2`)
- remove dead code and the unused `hashstring` utility (`a6f46a4`)
- migrate deprecated Neovim APIs to modern equivalents (`f7a980e`)

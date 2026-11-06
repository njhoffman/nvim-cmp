# Upstream sync

This fork takes changes from [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp) selectively. `git rev-list --count` overstates how far behind it is, because adapted cherry-picks get new hashes.

Last reviewed upstream commit: `fe29aba` (2026-11-05). To see what is new: `git log fe29aba..upstream/main`.

## Reviewed and not applied

| Upstream | Change | Why not |
| --- | --- | --- |
| `2ffe79f` | TextChanged only updates on added text | Drops pastes and multibyte input. Its follow-up PR #2228 is a large unrelated bundle. The fork fixes the reported case (#1303) by skipping changes that remove lines |
| `cd2cf0c`, `2fb2a3c`, `a70bdcf` | README and doc edits | Do not apply cleanly; not reviewed line by line |

## Open upstream PRs

Reviewed at `fe29aba`. These are unmerged upstream, so check them again when they land.

| PR | Change | Status here |
| --- | --- | --- |
| #2230 | `PreselectMode` type | Applied |
| #2234 | Keep the menu inside the editor | Applied |
| #2243, #2244 | In-place `ensure_nil`, keep `data` unchanged | Applied |
| #2177 | Schedule instead of feedkeys | Already present |
| #2032 | Docs height for wrapped lines | Already present |
| #2165 | Drop the `UIEnter` subscription | Not applied: the report is not reproduced here, and it changes when highlights are set |
| #2231 | Expand abbreviations in fallbacks | Not applied: about 170 lines for a narrow case |
| #2235 | Anchor windows for GUIs | Not applied: wide change, only affects GUIs with panels |

## Superseded in the fork

Upstream changes whose effect the fork already has in a different form: keymap regexes (`2c93d5e`, `7d40510`, `40a03dc`, `6fade6d`, `ca4d333`), `vim.uv` without the `vim.loop` fallback (`ed31156`), `vim.bo` over option getters (`5260e5e`, `abacd4c`), reverse lookup (`31a2939`, `2c35020`), and `CmdwinEnter` handling (`5a9ad0d`).

## Reviewing by matching lines

When comparing added lines against the tree, strip comments first. A commented-out line otherwise counts as applied, which hid `8c82d0b` at first.

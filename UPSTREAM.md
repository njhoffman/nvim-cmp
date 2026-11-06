# Upstream sync

This fork takes changes from [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp) selectively. `git rev-list --count` overstates how far behind it is, because adapted cherry-picks get new hashes.

Last reviewed upstream commit: `fe29aba` (2026-11-05). To see what is new: `git log fe29aba..upstream/main`.

## Reviewed and not applied

| Upstream | Change | Why not |
| --- | --- | --- |
| `8c82d0b` | Enable `compare.sort_text` by default | Changes result order; undecided, see TODO.md |
| `66f0a03`, `8f3c541` | Default `snippet.expand` to `vim.snippet` | Tied to choosing a minimum Neovim version; see TODO.md |
| `2ffe79f` | TextChanged only updates on added text | Drops pastes and multibyte input (open follow-up PR #2228); the fork has `trigger_debounce` instead |
| `1e1900b` | Preserve `buflisted` in text edits | Does not reproduce on 0.13-dev; depends on the minimum version |
| `cd2cf0c`, `2fb2a3c`, `a70bdcf` | README and doc edits | Do not apply cleanly; not reviewed line by line |

## Superseded in the fork

Upstream changes whose effect the fork already has in a different form: keymap regexes (`2c93d5e`, `7d40510`, `40a03dc`, `6fade6d`, `ca4d333`), `vim.uv` without the `vim.loop` fallback (`ed31156`), `vim.bo` over option getters (`5260e5e`, `abacd4c`), reverse lookup (`31a2939`, `2c35020`), and `CmdwinEnter` handling (`5a9ad0d`).

## Reviewing by matching lines

When comparing added lines against the tree, strip comments first. A commented-out line otherwise counts as applied, which hid `8c82d0b` at first.

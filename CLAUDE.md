# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About

Fork of [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp) — a completion engine plugin for Neovim written in Lua. Completion sources are external plugins that implement a source protocol.

## Commands

```bash
make test          # Run all tests (vusted --output=gtest ./lua)
make lint          # Lint with luacheck
make integration   # Lint + test combined
make pre-commit    # Same as integration

# Run a single test file
vusted --output=gtest ./lua/cmp/utils/misc_spec.lua
```

- **Test framework**: [vusted](https://github.com/notomo/vusted) (BDD-style, uses `describe`/`it`/`before_each`/`after_each`/`assert`)
- **Linter**: luacheck (config in `.luacheckrc`, no line length limit)
- Test files live alongside source files as `*_spec.lua`

## Architecture

### Completion Loop

1. **Autocmds** (`autocmds.lua`) fire on InsertEnter, TextChangedI, CursorMovedI, CmdlineEnter, CmdlineChanged
2. **Core** (`core.lua`) receives change events, creates a **Context** snapshot (`context.lua`) of editor state
3. Core invokes all registered **Sources** (`source.lua`) asynchronously — each source transitions WAITING → FETCHING → COMPLETED
4. Core runs throttled **filtering** (30ms throttle, 60ms debounce) which scores entries via **Matcher** (`matcher.lua`)
5. **View** (`view.lua`) renders the completion menu with sorted **Entries** (`entry.lua`)

### Key Modules

| Module | Role |
|--------|------|
| `lua/cmp/init.lua` | Public API entry point (`cmp.setup()`, `cmp.mapping.*`, etc.) |
| `lua/cmp/core.lua` | Central state machine — coordinates sources, context, view, keymaps |
| `lua/cmp/source.lua` | Wraps external source plugins, manages completion lifecycle and caching |
| `lua/cmp/entry.lua` | Completion item wrapper — scoring, matching, LSP text edit handling, lazy resolution |
| `lua/cmp/matcher.lua` | Fuzzy matching with word boundary detection, prefix scoring, case sensitivity bonus |
| `lua/cmp/context.lua` | Immutable snapshot of cursor position, buffer, filetype, line content |
| `lua/cmp/config.lua` | Config resolution with revision tracking |
| `lua/cmp/view/` | Menu implementations: custom (float window), native (vim popup), wildmenu (cmdline), docs, ghost text |

### Async System (`utils/async.lua`)

Custom coroutine scheduler with time budgeting (1us per step). Key primitives:
- `async.throttle(fn, timeout)` — deferred execution, used for filtering
- `async.dedup(fn)` — prevents duplicate/stale callbacks, used for source completion
- `async.wrap(fn)` — converts callback-style to async task
- `Async` class — coroutine wrapper with `:await()` and `:sync(timeout)`

### Configuration Resolution Order

Config is hierarchical (highest priority first): onetime > cmdline-specific > filetype > buffer > global. Cached with revision tracking; `cmp.setup()` bumps revision for immediate effect.

### Source Protocol

External sources implement `complete(params, callback)`. Sources call `callback(items)` when done. Setting `isIncomplete = true` signals more data is coming, which re-triggers the completion loop.

### Sorting Pipeline

Default comparators in order: offset, exact match, score (from matcher), recently used, locality, kind (LSP CompletionItemKind), length, source order.

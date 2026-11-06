#!/bin/sh
set -e

# Point git at the tracked hooks instead of copying them into .git/hooks.
cd "$(dirname "$0")"
git config core.hooksPath .githooks

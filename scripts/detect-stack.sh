#!/usr/bin/env bash
# Stack detector for xforge. Emits a labeled report of language, package manager,
# test/lint/build commands, framework, and partial-migration hints.
# Runs via !` injection from SKILL.md.
# Exit 0 always — missing signals are normal, just print "unknown".

set +e  # never fail the skill because of a missing tool

cwd=${1:-$PWD}
cd "$cwd" 2>/dev/null || { echo "[xforge:stack] cannot cd to $cwd"; exit 0; }

echo "=== xforge stack report for $cwd ==="

# ----- Language detection -----
langs=()
[[ -f package.json ]]         && langs+=("ts/js")
[[ -f pyproject.toml ]]       && langs+=("python")
[[ -f setup.py ]]             && langs+=("python-legacy")
[[ -f requirements.txt ]]     && langs+=("python-reqs")
[[ -f go.mod ]]               && langs+=("go")
[[ -f Cargo.toml ]]           && langs+=("rust")
[[ -f Gemfile ]]              && langs+=("ruby")
[[ -f composer.json ]]        && langs+=("php")
[[ -f pom.xml ]]              && langs+=("java-maven")
[[ -f build.gradle || -f build.gradle.kts ]] && langs+=("jvm-gradle")
[[ -f mix.exs ]]              && langs+=("elixir")
[[ -f Package.swift ]]        && langs+=("swift")
[[ -f pubspec.yaml ]]         && langs+=("dart/flutter")
[[ -f Makefile || -f makefile ]] && langs+=("make")

echo "Languages: ${langs[*]:-unknown}"

# ----- TS/JS package manager + scripts -----
if [[ -f package.json ]]; then
  pm="npm"
  [[ -f pnpm-lock.yaml ]]   && pm="pnpm"
  [[ -f yarn.lock ]]        && pm="yarn"
  [[ -f bun.lockb ]]        && pm="bun"
  echo "JS package manager: $pm"
  if command -v jq >/dev/null 2>&1; then
    echo "Package scripts:"
    jq -r '.scripts // {} | to_entries[] | "  \(.key): \(.value)"' package.json 2>/dev/null | head -20
    deps=$(jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys | join(" ")' package.json 2>/dev/null)
    # Framework hints
    frameworks=()
    echo "$deps" | grep -q '\bnext\b'         && frameworks+=("nextjs")
    echo "$deps" | grep -q '\breact\b'        && frameworks+=("react")
    echo "$deps" | grep -q '\bvue\b'          && frameworks+=("vue")
    echo "$deps" | grep -q '\bnuxt\b'         && frameworks+=("nuxt")
    echo "$deps" | grep -q 'svelte'           && frameworks+=("svelte")
    echo "$deps" | grep -q '\bastro\b'        && frameworks+=("astro")
    echo "$deps" | grep -q 'remix'            && frameworks+=("remix")
    echo "$deps" | grep -q 'solid-js'         && frameworks+=("solid")
    echo "$deps" | grep -q '\bexpress\b'      && frameworks+=("express")
    echo "$deps" | grep -q '\bfastify\b'      && frameworks+=("fastify")
    echo "$deps" | grep -q '\bhono\b'         && frameworks+=("hono")
    echo "$deps" | grep -q '\bvitest\b'       && frameworks+=("vitest")
    echo "$deps" | grep -q '\bjest\b'         && frameworks+=("jest")
    echo "$deps" | grep -q '\bplaywright\b'   && frameworks+=("playwright")
    echo "$deps" | grep -q '@trpc/'           && frameworks+=("trpc")
    echo "$deps" | grep -q '\bprisma\b'       && frameworks+=("prisma")
    echo "$deps" | grep -q 'drizzle-orm'      && frameworks+=("drizzle")
    echo "JS frameworks: ${frameworks[*]:-none detected}"
    # Partial migration signals
    [[ -d src/pages ]] && [[ -d src/app ]] && echo "PARTIAL_MIGRATION: Next.js pages + app router coexist"
    type_field=$(jq -r '.type // "commonjs"' package.json 2>/dev/null)
    echo "JS module type: $type_field"
  fi
fi

# ----- Python tooling -----
if [[ -f pyproject.toml ]]; then
  echo "Python build system:"
  grep -E '^\[tool\.' pyproject.toml | head -10 | sed 's/^/  /'
  if grep -q '\[tool.ruff' pyproject.toml; then echo "  ruff: configured"; fi
  if grep -q '\[tool.mypy' pyproject.toml; then echo "  mypy: configured"; fi
  if grep -q '\[tool.pytest' pyproject.toml; then echo "  pytest: configured"; fi
  if grep -q '\[tool.poetry' pyproject.toml; then echo "  poetry: detected"; fi
  if grep -q '\[tool.hatch'  pyproject.toml; then echo "  hatch: detected";  fi
  # Python version
  pyver=$(grep -E '^requires-python' pyproject.toml | head -1 | sed 's/requires-python = //')
  echo "  requires-python: ${pyver:-unset}"
fi
if [[ -f setup.py && -f pyproject.toml ]]; then
  echo "PARTIAL_MIGRATION: setup.py + pyproject.toml both present"
fi

# ----- Go -----
if [[ -f go.mod ]]; then
  echo "Go module: $(grep '^module ' go.mod | awk '{print $2}')"
  echo "Go version: $(grep '^go ' go.mod | awk '{print $2}')"
  [[ -f .golangci.yml || -f .golangci.yaml ]] && echo "golangci-lint: configured"
  [[ -d vendor ]] && echo "Vendored: yes (check for partial migration from modules)"
fi

# ----- Rust -----
if [[ -f Cargo.toml ]]; then
  rust_edition=$(grep -E '^edition' Cargo.toml | head -1 | sed 's/edition = //')
  echo "Rust edition: ${rust_edition:-unknown}"
  msrv=$(grep -E '^rust-version' Cargo.toml | head -1 | sed 's/rust-version = //')
  echo "MSRV: ${msrv:-unspecified}"
  [[ -f Cargo.lock && -f src/lib.rs ]] && echo "  Cargo.lock present in library crate (unusual — verify intent)"
fi

# ----- Makefile targets -----
if [[ -f Makefile || -f makefile ]]; then
  mf=$(ls Makefile makefile 2>/dev/null | head -1)
  echo "Make targets (top 15):"
  grep -E '^[a-zA-Z_-]+:' "$mf" | head -15 | sed 's/:.*//; s/^/  /'
fi

# ----- CLAUDE.md presence -----
echo ""
echo "CLAUDE.md files detected:"
for f in CLAUDE.md .claude/CLAUDE.md CLAUDE.local.md; do
  if [[ -f $f ]]; then
    lines=$(wc -l < "$f")
    echo "  $f: $lines lines"
  fi
done
if [[ -d .claude/rules ]]; then
  rule_count=$(find .claude/rules -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  echo "  .claude/rules/: $rule_count files"
fi

# ----- Settings detection -----
echo ""
echo "Claude Code config:"
for f in .claude/settings.json .claude/settings.local.json; do
  if [[ -f $f ]]; then
    echo "  $f: present"
  fi
done

# ----- Git signals -----
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  echo ""
  echo "Git: branch=$branch"
  remote=$(git remote get-url origin 2>/dev/null)
  [[ -n $remote ]] && echo "Git: remote=$remote"
fi

echo "=== end stack report ==="

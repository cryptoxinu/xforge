# Template Overlay: Python

Append this to the core template when Phase 1 detects Python (`pyproject.toml`, `setup.py`, `requirements.txt`).

## Verification section — Python-specific commands

Detect the actual tools from `pyproject.toml` `[tool.*]` sections and `pre-commit` config. Generate concrete commands that work in THIS repo. Common stack:

```markdown
## Verification (run after EVERY change)
1. `ruff check src/ tests/` — lint (fix ALL errors)
2. `ruff format --check src/ tests/` — format check
3. `mypy src/` — typecheck (if configured; check `[tool.mypy]` in pyproject.toml)
4. `pytest tests/ -q` — fix ALL failing tests
5. `pytest tests/ --cov=src --cov-report=term-missing` — verify coverage holds (if coverage gate exists)

YOU ARE FORBIDDEN from reporting a task as complete until steps 1-4 pass with zero errors.
```

If the project uses different tools, substitute them. Never suggest tools that aren't installed:
- `black` + `isort` instead of `ruff format` — detect from pyproject.toml
- `pylint` or `flake8` instead of `ruff check`
- `pyright` instead of `mypy`
- `poetry run <cmd>`, `hatch run <cmd>`, `uv run <cmd>` prefixes if detected
- `tox` for multi-env test matrix
- `hypothesis` property-based tests — if detected, add strategies to testing rules

## Version-specific gotchas

Detect Python version from `pyproject.toml` `requires-python` or `.python-version` and add relevant rules:

- **Python 3.12+** — `global` must appear BEFORE the variable is used (SyntaxError, not warning). f-string nesting works. Type-parameter syntax `def f[T](x: T) -> T:`.
- **Python 3.13+** — GIL-free builds experimental. `typing` deprecations.
- **Python 3.14+** — `warnings.deprecated`. PEP 649 lazy annotations.

## Packaging and environment

If `pyproject.toml` uses PEP 621 (`[project]` table), standardize on it. Flag if the project mixes `setup.py` and `pyproject.toml` — partial migration. If there's a `setup.cfg` with duplicated config, flag it.

## Async / sync boundary (if asyncio present)

```markdown
- Never call sync blocking code from an `async` function without `run_in_executor` — it stalls the event loop
- Inside `async`: use `httpx.AsyncClient`, not `requests`. Use `aiofiles`, not `open()`
- `await` every coroutine. A bare coroutine expression is NOT an error but DOES NOT RUN
- `asyncio.gather(*tasks, return_exceptions=True)` if you want partial success semantics; default raises on first failure
```

## Django / FastAPI / Flask additions

If Django detected: add migration rules, ORM query-N+1 warnings, serializer vs model boundary. Point to `.claude/rules/django.md` if the project has 100+ Django-specific rules.

If FastAPI: enforce Pydantic model for every request body, async route handlers, dependency injection patterns.

If Flask: enforce blueprint structure, request-context boundaries.

## Testing

```markdown
- `pytest` fixtures in `conftest.py` — don't redefine per-file
- Parametrize over the happy path + 2 edge cases minimum
- Mock at the I/O boundary (database, HTTP, filesystem), NEVER at the business-logic boundary
- `freezegun` or `time-machine` for time-dependent tests — never rely on real `datetime.now()`
- `pytest-asyncio` mode = `"auto"` if detected
```

## Anti-patterns to flag in generated Python CLAUDE.md

- "Use type hints" — generic. Rewrite: "All public functions MUST have full type annotations. Run `mypy --strict src/` before commit."
- "Follow PEP 8" — redundant with ruff. Remove.
- "Write docstrings" — redundant. Only specify if the project has a custom docstring convention (google / numpy / sphinx) and show the target format.

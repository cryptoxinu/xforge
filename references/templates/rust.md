# Template Overlay: Rust

Append when Phase 1 detects `Cargo.toml`. Read edition, workspace layout, and MSRV.

## Verification

```markdown
## Verification (run after EVERY change)
1. `cargo build --all-targets` — compile everything (bins, libs, tests, examples)
2. `cargo test --all-targets` — fix ALL failing tests
3. `cargo clippy --all-targets -- -D warnings` — fix ALL lint issues (warnings fail)
4. `cargo fmt --check` — must be clean

YOU ARE FORBIDDEN from reporting a task as complete until all 4 pass with zero errors/warnings.
```

If the project has `cargo-deny.toml`: add `cargo deny check`. If `cargo-nextest.toml`: use `cargo nextest run` instead of `cargo test`.

## Ownership / borrowing rules

```markdown
## Ownership
- Prefer `&str` over `String` in function parameters unless you need ownership
- `Clone` is not free — if you see repeated `.clone()` in a hot path, redesign the lifetime flow
- `Rc<RefCell<T>>` / `Arc<Mutex<T>>` are ESCAPE HATCHES. Reach for them only after you've exhausted ownership-based design
- Avoid `.unwrap()` / `.expect()` in library code — propagate with `?` and a typed error
- In binary crates, `.expect("<context>")` is acceptable only at top-level startup where failure IS the right behavior
```

## Error handling

```markdown
- Domain errors: `thiserror` enum per crate
- Application errors (bins): `anyhow::Result` + `.with_context(|| "...")` for each fallible step
- NEVER mix — libraries don't return `anyhow::Error`, binaries don't define `thiserror` per callsite
- Use `?` operator, not `.unwrap()` except in tests
- Tests that use `?`: write `fn () -> Result<(), Box<dyn Error>>` or `anyhow::Result<()>`
```

## Async

```markdown
- Single runtime — Tokio if detected. Don't mix with `async-std` or `smol`
- `#[tokio::main]` on `fn main`, or explicit `Runtime::new()` for advanced control
- `tokio::spawn` returns a `JoinHandle` — you MUST either await it, detach intentionally, or join in cleanup
- `select!` over multiple futures — always include a `tokio::signal::ctrl_c` branch for graceful shutdown in long-running programs
- Blocking code inside async: wrap with `tokio::task::spawn_blocking`
```

## Unsafe

```markdown
- Every `unsafe` block MUST have a SAFETY comment explaining the invariants maintained
- `unsafe` expands the trust boundary — if a reviewer can't verify the invariant in 5 minutes, the comment is insufficient
- `unsafe` in tests: wrap with `#[cfg(test)]` justifications
- `miri` should pass: `cargo +nightly miri test` for crates with unsafe code
```

## Testing

```markdown
- Unit tests in `#[cfg(test)] mod tests {}` at the bottom of the file under test
- Integration tests in `tests/` directory — one file per scenario
- `proptest` or `quickcheck` for property-based testing when the function has algebraic properties
- Benchmarks in `benches/` with Criterion, not the built-in `test::Bencher` (which requires nightly)
- `rstest` for parametrized tests if present
```

## Workspace / crate hygiene

- `Cargo.lock` committed for binaries, not for libraries
- Workspace inheritance: `workspace = true` for version/license/edition fields to avoid drift
- `[workspace.lints]` table for shared clippy settings (Rust 1.74+)
- Partial migrations: flag `2018` edition crates in a `2021` workspace

## Anti-patterns to flag

- "Use `Result`" — meaningless. Specify the error-handling library (thiserror vs anyhow) and the boundary.
- "Avoid unsafe" — too blunt. Replace with: "New `unsafe` blocks require a reviewer with unsafe expertise and a documented SAFETY comment."
- "Use ownership" — vague. Replace with concrete borrowing rules.

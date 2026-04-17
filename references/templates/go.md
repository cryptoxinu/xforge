# Template Overlay: Go

Append when Phase 1 detects `go.mod`. Read the module path, Go version, and detect tooling (`golangci-lint`, `gofumpt`, `sqlc`, `wire`, `buf`, `air`).

## Verification

```markdown
## Verification (run after EVERY change)
1. `go build ./...` — compile all packages
2. `go vet ./...` — fix ALL vet issues
3. `gofmt -l .` should output nothing (or `gofumpt -l .` if configured)
4. `golangci-lint run` — fix ALL lint errors (if `.golangci.yml` present)
5. `go test ./... -race -count=1` — race detector on, no cache, fix ALL failing tests

YOU ARE FORBIDDEN from reporting a task as complete until all steps pass with zero errors.
```

## Idiomatic Go rules (project-aware)

```markdown
## Go Conventions
- Return `error` as the LAST value, `(T, error)`, never swap the order
- Wrap errors with `fmt.Errorf("context: %w", err)` — NEVER bare return errors from 3+ layers deep
- `context.Context` is the FIRST parameter, always named `ctx`. NEVER store in a struct
- No `init()` functions for business logic — they hide dependencies. Reserve for package-level constant init
- Use `errors.Is` / `errors.As` for error comparison, NEVER `==` on sentinel errors
- Prefer early return over nested if. Max nesting depth: 3
- Interface declarations live with the CONSUMER package, not the producer (accept interfaces, return concrete types)
- Pass slices/maps to functions that don't retain them; use `slices.Clone` / `maps.Clone` when retained
```

## Concurrency

```markdown
- `goroutine` started in a function MUST have a defined end condition: ctx cancellation, channel close, or sync.WaitGroup
- NEVER launch goroutines in a loop without `sync.WaitGroup` or an errgroup
- `defer cancel()` on EVERY `context.WithCancel` / `WithTimeout` / `WithDeadline`
- Send on a closed channel panics — close from the SENDER side only
- `sync.Mutex` — copy by value is a bug. Use pointer receivers or `sync.Mutex` as a pointer field
- Run tests with `-race`. A data race caught in dev is a shipped bug caught before prod
```

## Testing

```markdown
- Table-driven tests for any function with 3+ cases
- Subtests via `t.Run(name, func(t *testing.T) { ... })` — enables `-run` targeting
- `t.Helper()` in test helpers so failures point to the caller
- Use `t.Cleanup()` not `defer` in tests — runs even on `t.Fatal`
- `testdata/` directory for fixtures. Don't embed large strings inline
- `go test -run '^TestName$' ./pkg` to target one test exactly
```

## Module hygiene

- `go mod tidy` — part of CI, never a "fix later" step
- Direct vs indirect deps matter — review `go.mod` changes per PR
- Vendor only if the project is already vendored; don't mix
- Replace directives flagged — they're often partial migrations

## Anti-patterns to flag

- "Handle errors properly" — meaningless. Specify the wrap pattern and where sentinel errors live.
- "Use goroutines" — dangerous as-is. Specify the lifecycle + leak-prevention pattern.
- "Follow Go idioms" — vague. Cite specific rules from `golang.org/doc/effective_go` ones that apply to THIS codebase.

## Framework overlays

**Gin / Echo / Chi / stdlib net/http** — detect and add handler conventions: context propagation, middleware order, request/response codec rules.

**gRPC** (detect `google.golang.org/grpc`): protobuf generation workflow, service vs client boundary, deadline propagation.

**sqlc / ent / GORM** — ORM boundary rules. With sqlc: never hand-write queries that should be in `query.sql`. With GORM: no `.Raw()` outside a documented escape hatch.

<!-- Verify-step reference for the git-flow skill. Detect the ecosystem, run the
matching test/lint command, and STOP if it fails. Prefer a command already
defined by the project (scripts, Makefile targets, CI) over a generic guess.
If none of these markers exist, the project has no verifiable setup — say so and
move on; never fabricate a command. -->

# Verify commands by ecosystem

Order of preference within a project:

1. **Project-defined command** — a script/target the repo already declares
   (`package.json` scripts, `Makefile`, `Taskfile`, `justfile`, CI workflow).
   Run that; it encodes the project's intent.
2. **Ecosystem default** — the conventional command below, if the marker file
   exists but no custom script is defined.
3. **Nothing** — no marker → no verification. Report and continue.

Run lint **and** tests when both are cheap and available; tests are the stronger
signal. Honor an explicit user instruction over this table.

| Ecosystem | Marker file(s) | Test | Lint / typecheck |
|---|---|---|---|
| Node / JS / TS | `package.json` | `npm test` / `pnpm test` / `yarn test` (match the lockfile) | `npm run lint`, `npx tsc --noEmit` |
| Python | `pyproject.toml`, `setup.cfg`, `tox.ini` | `pytest` (or `tox`) | `ruff check .`, `flake8`, `mypy .` |
| Go | `go.mod` | `go test ./...` | `go vet ./...`, `golangci-lint run` |
| Rust | `Cargo.toml` | `cargo test` | `cargo clippy -- -D warnings` |
| Ruby | `Gemfile`, `Rakefile` | `bundle exec rspec` / `rake test` | `bundle exec rubocop` |
| Java/Kotlin (Maven) | `pom.xml` | `mvn -q test` | `mvn -q verify` |
| Java/Kotlin (Gradle) | `build.gradle(.kts)` | `./gradlew test` | `./gradlew check` |
| PHP | `composer.json` | `composer test` / `./vendor/bin/phpunit` | `./vendor/bin/phpstan analyse` |
| .NET / C# | `*.csproj`, `*.sln` | `dotnet test` | `dotnet format --verify-no-changes` |
| Elixir | `mix.exs` | `mix test` | `mix format --check-formatted`, `mix credo` |
| C / C++ | `CMakeLists.txt`, `Makefile` | `ctest` / `make test` | — |
| Shell | `*.sh` | — | `shellcheck <files>` |
| Markdown / docs only | `*.md` (no code) | — | `markdownlint`/`mdl` **only if** a config (`.markdownlint*`, `.mdlrc`) exists; else none |
| Generic | `Makefile` | `make test` | `make lint` (only if the target exists) |

Notes:

- **Match the package manager** to the lockfile: `package-lock.json` → npm,
  `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn.
- **Monorepos:** prefer the workspace-aware command (e.g. `pnpm -r test`,
  `nx affected`, `turbo run test`) if the tooling is present.
- **Docs/skill repos** (like this one) usually have no test runner. That's a
  valid "no setup" outcome — don't invent `npm test` where there's no
  `package.json`.
- A command that needs network, secrets, or a long build and clearly can't run
  in this environment: report what you'd run and why it was skipped, rather than
  faking a pass.

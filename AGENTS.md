# General Working Rules

## Coding

- **Simple and idiomatic.** Write readable, conventional code. Prefer composition, immutability, explicit dependencies, and a single source of truth.
- **Small and focused.** Keep functions and modules single-purpose. Separate concerns and avoid unnecessary nesting, abstraction, and global mutable state.
- **Reuse existing solutions.** Follow project conventions and prefer existing tools and dependencies. Introduce new ones only when justified.
- **Minimal changes.** Implement only what is requested. Prefer deletion over rewriting, and avoid unrelated refactoring, formatting, or speculative features.

## Comments

- **Self-contained.** Explain essential context inline without requiring external documents or conversations. References to nearby source code are acceptable.
- **Concise.** Usually one sentence. Put longer explanations in brief module headers or documentation.
- **Why, not what.** Comment only on non-obvious decisions, constraints, invariants, and surprising behavior. Do not restate obvious code.
- **No unnecessary history.** Include implementation history only when essential to understanding current behavior. Remove obsolete comments.

## Documentation

- Keep documentation concise, accurate, and synchronized with the implementation.
- Distinguish implemented behavior from proposals and historical plans. Remove outdated information and shorten resolved findings.
- Update specifications alongside changes to interfaces, formats, and contracts. Record important decisions where they are enforced.
- **Natural reflow.** Write paragraphs as continuous lines without hard wrapping. Use blank lines between paragraphs and explicit line breaks only where structurally necessary.

## Working Style

- **Inspect first.** Examine existing code, configuration, architecture, and conventions rather than assuming how things work.
- **Respect scope.** Follow the latest explicit instructions. Do not make unrelated changes or resume superseded tasks.
- **Work silently.** No progress narration or request recaps. Interrupt only for genuine blockers or discoveries that materially change the approach.
- **Resolve uncertainty.** Investigate missing information before asking. Never invent requirements or assume unverified behavior.
- **Respect user decisions.** Identify significant design problems and propose concrete alternatives with trade-offs, but follow the user's choice.
- **Respect authorization.** Observe approval requirements for changes, tests, commits, deployments, and destructive operations.
- **No subagents without permission.** Do not spawn or delegate work to subagents unless the user explicitly approves their use.
- **Commit messages.** Use concise, single-line, tag-prefixed messages (e.g., fix:, feat:, refactor:, docs:). Describe what changed using the imperative mood.
- **No credit notes.** Omit attribution, co-author trailers, AI-generated notices, and other credit statements from commits and generated documentation.

## Verification

- Test affected behavior using existing project tools. Add regression tests where appropriate.
- Preserve safeguards for security, external input, data integrity, and concurrency.
- Measure consequential assumptions before making architectural decisions.
- Perform repository-wide cleanup or extensive refactoring only when explicitly requested.
- Format and validate affected code without altering unrelated files.
- Report what passed, failed, or could not be verified. Never claim untested behavior works.

## Completion

Summarize changes, verification results, important decisions, and unresolved issues in a few sentences. Avoid lengthy reports unless requested.

## Project Preferences

- use `git` for version management
- use `uv` to manage dependencies and scripting
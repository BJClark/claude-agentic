# Deepening

How to deepen a cluster of shallow modules safely, given its dependencies. Assumes the vocabulary in [LANGUAGE.md](LANGUAGE.md) — **module**, **interface**, **seam**, **adapter**, **depth**, **leverage**, **locality**.

## Dependency categories

When assessing a candidate for deepening, classify its dependencies. The category determines how the deepened module is tested across its seam.

### 1. In-process

Pure computation, in-memory state, no I/O. Always deepenable — merge the modules and test through the new interface directly. No adapter needed.

*Ticket language*: *"In-process deepening — single module with direct tests at the interface, no ports."*

### 2. Local-substitutable

Dependencies that have local test stand-ins (PGLite for Postgres, in-memory S3, an in-memory filesystem). Deepenable if the stand-in exists. The deepened module is tested with the stand-in running in the test suite. The seam is internal; no port at the module's external interface.

*Ticket language*: *"Local-substitutable — tested against `<stand-in>` in the test suite; no port on the external interface."*

### 3. Remote but owned (Ports & Adapters)

Your own services across a network boundary (microservices, internal APIs, queues you publish to). Define a **port** (interface) at the seam. The deep module owns the logic; the transport is injected as an **adapter**. Tests use an in-memory adapter. Production uses an HTTP / gRPC / queue adapter.

*Recommendation shape*: *"Define a port at the seam, implement an HTTP adapter for production and an in-memory adapter for testing, so the logic sits in one deep module even though it's deployed across a network."*

### 4. True external (Mock)

Third-party services (Stripe, Twilio, Segment, SendGrid, etc.) you don't control. The deepened module takes the external dependency as an injected port; tests provide a mock adapter. Contract tests (recorded / replayed) validate the mock against the real service periodically.

*Ticket language*: *"True external — injected port, mock adapter in tests, recorded contract tests against `<vendor>` on CI nightly."*

## Seam discipline

- **One adapter means a hypothetical seam. Two adapters means a real one.** Don't introduce a port unless at least two adapters are justified (typically production + test). A single-adapter seam is just indirection — a refactor that produces leverage-free ceremony.
- **Internal seams vs external seams.** A deep module can have internal seams (private to its implementation, used by its own tests) as well as the external seam at its interface. Don't expose internal seams through the interface just because tests use them.
- **Ports live at the module's edge, not in the middle.** If you find yourself wanting a port between two sub-parts of a deep module, those are internal seams — keep them private.

## Testing strategy: replace, don't layer

- Old unit tests on shallow modules become **waste** once tests at the deepened module's interface exist — delete them.
- Write new tests at the deepened module's interface. The **interface is the test surface**.
- Tests assert on observable outcomes through the interface, not internal state.
- Tests should survive internal refactors — they describe behaviour, not implementation. If a test has to change when the implementation changes, it's testing past the interface.
- For categories 3 & 4, contract tests against the real dependency are a separate tier — don't mix them with logic tests.

## Extraction order (when the deepening is non-trivial)

For L / XL candidates, the extraction is a mini-plan. Grill-me should surface these questions; the answers belong in the ticket body:

1. **Define the target interface first** — type signature + invariants + error modes. Write it as comments or a stub module before moving any code.
2. **Bring callers to the new interface** — one caller at a time, adapting to the new interface without the implementation yet (stub returns).
3. **Merge implementations into the deep module** — move logic in, keeping the interface stable.
4. **Delete the shallow modules** — once no caller references them.
5. **Collapse redundant tests** — delete the shallow-module tests, replace with interface-level tests.

If the grill can't settle the interface signature, the candidate is not ready for a ticket — it's ready for `/tech-spec`.

## Anti-patterns

- **Interface inflation**: deepening that ends up with a 20-method interface. If the interface grew, you discovered sibling modules that should be deepened separately — not merged in.
- **Fake ports**: introducing a port with one adapter, "in case" a second is needed later. Don't — introduce it when the second adapter exists.
- **Premature generics**: parameterizing the deep module "for reuse" before a second use case exists. Hard-code to the one use case; generalize on demand.
- **Re-extracting for testability**: pulling pure helpers back out of a deep module "so tests can target them." The interface is the test surface; if interface tests are hard to write, the interface is wrong, not the extraction.

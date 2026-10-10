# Rules

1. Commit after every change that builds/runs.
2. Commit messages are a single line, with no paragraphs, no newlines, no attribution footers.
3. Do not add verbose comments. Only comment when absolutely necessary to explain a gotcha, SwiftUI bug, or workaround.
4. Do not create large .swift files. Split large types using extensions grouped into their own folder, and give long views their own files.
5. Spell out variable names in full (time instead of t, xPosition instead of x).
6. Mark MainActor or nonisolated code correctly to comply with Swift 6 concurrency checking.
7. All Cloudflare API code lives in the CloudflareKit framework. The app only talks to Cloudflare through CloudflareKit.
8. Never use a real Cloudflare API token for testing without asking the user first.
9. Never use em-dashes anywhere, including code, comments, UI copy, docs, and commit messages.
10. All user-facing text lives in a Localizable.xcstrings catalog under Pascal.Case.Dot.Notated keys (Workers.Delete.Title). Reference strings through the generated symbols (Text(.workersDeleteTitle)), never through literal copy in code.

# Design

- Keep the UI native and mobile friendly. Use tabs to separate features.
- Do not use pills, monospaced text, all caps headers, or fingernail colors (thin colored accent strips).
- Show cached content immediately and refresh in the background.

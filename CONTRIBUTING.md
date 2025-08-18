## Contributing

This project follows a refactor-first plan with no feature changes. Please keep PRs focused and small (≤ 500 LOC changed) and follow the structure below.

### Branch and PR
- Branch: `refactor/*` (e.g., `refactor/structure-init`, `refactor/painters`)
- Conventional Commits: `refactor:`, `test:`, `docs:`, `build:`, `chore:`
- PR checklist:
  - `flutter analyze` passes
  - `flutter test` passes
  - Release build check: `flutter build appbundle --release`

### Architecture
- Feature-first folders with clear separation:
  - presentation (widgets/UI)
  - application (state/controllers)
  - domain (entities/models)
  - shared (widgets, painters)
- Core theme tokens under `lib/core/theme/`.

### Performance
- Keep CustomPainter overdraw minimal; use `RepaintBoundary` where applicable.
- Use continuous phase for animations; dynamic sampling step by width.
- `shouldRepaint` returns true only on input change.

### Lints & Style
- Enforced via `analysis_options.yaml`.
- Always use package imports: `package:flutter_sleepy/...`.

### Rollback
- Tag `pre-refactor` before large reorganizations to allow easy rollback.


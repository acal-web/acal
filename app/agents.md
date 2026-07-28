# acalapp — Project Guidelines

## Overview

Flutter application targeting web, desktop (Linux, macOS, Windows), iOS, and Android.
Flutter SDK `^3.11.5`, Dart null-safe, Material 3.

---

## Tech Stack

| Concern   | Package          |
|-----------|------------------|
| Routing   | `go_router ^17`  |
| UI        | Flutter Material 3 |
| Font      | Inter (variable) |

No state management library yet — use `StatefulWidget` / `InheritedWidget` until one is chosen.

---

## File Structure

```
lib/
  main.dart                        # Entry point — MaterialApp.router only
  config/
    app_config.dart                # App-wide constants (appName, etc.)
    layout_config.dart             # Layout constants (sideMenuWidth, menuBreakpoint)
    router.dart                    # GoRouter definition
  layout/
    app_shell.dart                 # Root scaffold (TopBar + SideMenu + body)
    menu/
      side_menu.dart
    topbar/
      topbar.dart
      topbar_fragments/            # Sub-widgets of the topbar
        topbar_body.dart
        topbar_logo.dart
        topbar_helpers.dart
  pages/
    <section>/
      <section>_page.dart          # One file per page, named after the section
  theme/
    light_theme.dart               # ThemeData — the only theme for now
```

---

## Architecture Rules

- **`main.dart`** only wires `MaterialApp.router` + `lightTheme` + `appRouter`. No logic.
- **`config/`** files hold constants and configuration. No widgets, no business logic.
- **`layout/`** contains the shell and structural chrome. Pages do not import from `layout/`.
- **`pages/`** are leaf widgets. Each page is self-contained; shared logic lives in a future `features/` or `services/` layer.
- **`theme/`** exports a single `ThemeData`. Do not hardcode colors or text styles inline — always use `Theme.of(context)`.

---

## Routing

All routes go through `ShellRoute` → `AppShell`. Every page gets the shell for free.

```dart
GoRoute(
  path: '/section',
  builder: (context, state) => const SectionPage(),
),
```

Use `context.go(route)` for navigation. Never `Navigator.push` inside shell-wrapped pages.

---

## Layout

| Constant                       | Value |
|-------------------------------|-------|
| `LayoutConfig.sideMenuWidth`  | 240   |
| `LayoutConfig.menuBreakpoint` | 768   |

- Below 768 px the side menu is hidden by default and toggled via the hamburger.
- `TopBarLogo` width mirrors `sideMenuWidth - 1` to align with the menu edge.

---

## Design System — "Executive Precision"

### Color Tokens (light theme)

| Role                | Value       |
|---------------------|-------------|
| primary             | `#000666`   |
| onPrimary           | `#FFFFFF`   |
| primaryContainer    | `#1A237E`   |
| onPrimaryContainer  | `#8690EE`   |
| secondary           | `#4355B9`   |
| secondaryContainer  | `#8596FF`   |
| tertiary            | `#181B23`   |
| surface             | `#FCF9F8`   |
| outline             | `#767683`   |
| outlineVariant      | `#C6C5D4`   |

Never reference hex values directly in widget code — always go through `Theme.of(context).colorScheme`.

### Typography (Inter)

| Token         | Size | Weight | Notes                  |
|---------------|------|--------|------------------------|
| displayLarge  | 32   | 600    | headlines              |
| displayMedium | 24   | 600    | section titles         |
| displaySmall  | 20   | 500    | card titles            |
| bodyLarge     | 16   | 400    |                        |
| bodyMedium    | 14   | 400    | default body           |
| bodySmall     | 13   | 400    |                        |
| labelLarge    | 12   | 600    | uppercase labels       |
| labelSmall    | 11   | 500    |                        |

Use `theme.textTheme.bodyMedium` etc. — do not write inline `TextStyle` for common sizes.

### Component Defaults

- **Cards**: white bg, 0 elevation, 1 px `outlineVariant` border, 8 px radius, zero margin.
- **Inputs**: white bg, 4 px radius, `outlineVariant` border, `secondary` when focused.
- **ElevatedButton**: `primaryContainer` bg, 0 elevation, 4 px radius.
- **OutlinedButton**: `primaryContainer` border/text, 4 px radius.
- **TextButton (ghost)**: `secondary` text, no border.
- **AppBar**: white bg, `primaryContainer` foreground, 0 elevation (no scroll-under shadow).
- **Divider**: `outlineVariant`, 1 px, 0 space.

---

## Naming Conventions

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Private widget helpers within a file: prefix with `_` (e.g., `_MenuItem`)
- Sub-widgets of a complex widget go in a `<widget>_fragments/` subdirectory (see `topbar_fragments/`)
- Page files: `<section>_page.dart` inside `pages/<section>/`

---

## Code Style

- No comments unless the *why* is non-obvious.
- `const` constructors wherever possible.
- Prefer `final` locals.
- Extract private `StatelessWidget` sub-classes rather than nested `Builder` closures for anything beyond trivial inline widgets.
- `Theme.of(context)` → cache in a local `final theme = Theme.of(context)` at the top of `build`.
- `MediaQuery.sizeOf(context)` (not `MediaQuery.of(context).size`) to minimize rebuilds.

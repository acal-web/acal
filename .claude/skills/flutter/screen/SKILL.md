---
name: screen
description: Use when creating or reviewing Flutter screens/pages in app/ (Flutter web). Conventions for reusing existing widgets, making screens accessible/semantic, and responsive layout.
---

Conventions for building screens ("telas") in this repo's Flutter app (`app/`). Follow these when adding a new feature screen or reviewing an existing one. `addresses` (`lib/features/addresses/`) is the canonical reference feature — model new screens after it.

## 1. Reuse widgets before creating new ones

Before writing any new widget, search for one that already does the job:

```bash
ls app/lib/shared/widgets app/lib/shared/widgets/**/*.dart
ls app/lib/features/<feature>/widget/*.dart   # widgets local to the feature you're touching
grep -rl "<ThingYouNeed>" app/lib/features/*/widget/     # similar widgets in other features
```

Put a widget in `lib/shared/widgets/` (optionally in a subfolder like `table/` or `toast/`) when it's generic across "Cadastros"-style pages: dialogs, form scaffolding, tables, toasts. Put it in `lib/features/<feature>/widget/` when it's specific to that feature (e.g. the form page for that entity, an `open_x`/`delete_x` helper). If you find yourself duplicating a pattern that already exists in another feature's `widget/` folder, promote it to `shared/widgets/` instead of copy-pasting — but only once it's genuinely reused, not preemptively.

Known shared building blocks worth checking first: `PageHeader`, `AppFormDialog` (+ `FormDialogHeader`, `FormActions`), `LabeledField`, `blurred_dialog` (`showBlurredDialog`), `delete_confirm_dialog` (`showDeleteConfirmDialog`), `AsyncErrorView`, `table/DataTableCard`, `table/PagedListView`, `table/RowActions`, `toast/AppToast`. This list will drift — always re-check `lib/shared/widgets/` directly rather than trusting it blindly.

## 2. Feature structure

A feature screen follows `lib/features/<feature>/`:

- `domain/` — the model (plain Dart class/record for the entity).
- `data/` — `<feature>_service.dart`, the HTTP calls (`HttpService`-based).
- `presentation/` — the routed page (e.g. `addresses_page.dart`): list/table view, wired to `go_router`.
- `widget/` — feature-local pieces: the form dialog (`<feature>_form_page.dart`), and small `open_<feature>`/`delete_<feature>` helper functions that wrap `showBlurredDialog`/`showDeleteConfirmDialog` and return whether the caller should refresh.

To make a new screen reachable:
1. Add a `GoRoute` + `pageBuilder: (context, state) => const NoTransitionPage(child: YourPage())` in `lib/core/config/router.dart`.
2. Add an entry (`icon`, `label`, `route`) to the matching section in `lib/core/layout/menu/side_menu.dart` (or a new `_MenuSection` if it's a new area).

## 3. Accessible and semantic

Flutter derives semantics labels for screen readers from the same text/tooltip a control shows visually. Concretely:

- Every interactive control needs a real, human-readable Portuguese label: `Text`/button `label:`/`hintText`, not an icon alone. Use real semantic widgets (`FilledButton`, `TextButton`, `IconButton`, `TextFormField`) — never a bare `GestureDetector`/`InkWell` around a `Container`, since those don't expose a role+label to the semantics tree.
- Icon-only buttons (e.g. table row actions) must set `tooltip:` — that's what gives screen readers a label. See `RowActions` (`tooltip: 'Editar'` / `'Excluir'`).
- When a control's visible text isn't unique/stable (e.g. a confirm button whose label repeats elsewhere on screen), wrap it in `Semantics(identifier: 'kebab-case-id', child: ...)` so it has a stable identifier in the semantics tree. See `delete_confirm_dialog.dart`'s `confirm-delete-button`.
- Keep visible strings unique per screen where practical — two controls with the same label on one screen make assistive-technology navigation ambiguous.

## 4. Responsive layout

Screens run as Flutter web at a range of viewport widths (the app shell's side menu itself collapses at `LayoutConfig.menuBreakpoint`). Follow the same pattern used throughout:

- Pick a named breakpoint constant for the widget (e.g. `_narrowBreakpoint`), and switch layout with `LayoutBuilder` (when you need the parent's constraints) or `MediaQuery.sizeOf(context).width` (when you need the viewport). See `PageHeader` and `AddressesPage`'s `_AddressFilterBar` for the stack-below/row-above pattern.
- Constrain dialogs with `ConstrainedBox(constraints: BoxConstraints(maxWidth: ...))` (see `AppFormDialog`, default `maxWidth: 480`) so they don't stretch edge-to-edge on wide screens.
- Reserve fixed pixel widths for small, deliberately-fixed controls (action buttons, a table's actions column) — never for primary content columns/containers, which should flex/expand.
- Sanity-check new screens at both a narrow width (e.g. resize the Chrome window below the breakpoint) and a wide one before calling the work done.

## Reference example

`lib/features/addresses/` end-to-end — `presentation/addresses_page.dart` (responsive list + filter bar), `widget/address_form_page.dart` (form dialog), `widget/delete_address.dart` + `shared/widgets/delete_confirm_dialog.dart` (accessible confirm dialog with a stable `Semantics` id) — is the template for new screens.

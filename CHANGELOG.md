## 0.1.1

* README: install from pub.dev with a version constraint (`^0.1.1`), pub.dev
  badge, and GitHub install pinned to a release tag instead of `main`.

## 0.1.0

* Initial release.
* `PaginatedDropdown.offline` – local pagination and search over a list.
* `PaginatedDropdown.online` – API pagination with configurable query keys,
  extra query parameters, first page index and debounced search.
* Loading, empty, error (first page and load-more) states with retry.
* `FormField` integration and custom item builder.
* Full styling: `PaginatedDropdownStyle`, `PaginatedDropdownTexts`,
  app-wide `PaginatedDropdownTheme` extension, and builders for the field,
  selected value, search box, panel, separators and every loading/error state.
* Display modes: `menu`, `dialog`, `bottomSheet`, with an optional header
  (title, close button) and card-style rows (`itemMargin`, `itemBorderRadius`).
* `PaginatedDropdownTheme.displayMode` sets the default display mode app-wide.
* `dropdownIconPadding` positions the field arrow; the arrow no longer sits in
  a forced 48dp box. Default header padding is symmetric so titles center.
* Typography: `fontFamily` for every text, plus `hintTextStyle`,
  `errorTextStyle` and `searchHintStyle`.

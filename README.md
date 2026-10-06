# fi_paginated_dropdown

A searchable, paginated dropdown for Flutter.

- **Offline mode** – give it a `List<T>`; the widget paginates and searches it locally.
- **Online mode** – give it a function that calls your API; the widget handles
  page numbers, page size, debounced search text and query string parameters.
- Infinite scroll with loading / error / empty states and retry.
- Works with any HTTP client (`dio`, `http`, your repository layer) – no extra dependencies.
- `FormField` integration: `validator`, `onSaved`, `autovalidateMode`.
- Fully customisable look: style object, app-wide theme extension, custom texts and builders for every part.
- Shown as an attached menu, a centered dialog or a bottom sheet.
- Clear button, and the menu opens upward when there is no room below.

## Install

```yaml
dependencies:
  fi_paginated_dropdown:
    git:
      url: https://github.com/sasika-fidenz/fi_paginated_dropdown.git
      ref: main   # or a tag, e.g. v0.1.0
```

```dart
import 'package:fi_paginated_dropdown/fi_paginated_dropdown.dart';
```

## Offline

```dart
PaginatedDropdown<String>.offline(
  items: fruits,                  // full list
  itemLabel: (fruit) => fruit,
  pageSize: 25,
  value: selectedFruit,
  hintText: 'Select a fruit',
  onChanged: (value) => setState(() => selectedFruit = value),
)
```

Search matches `itemLabel` (case-insensitive contains). Customise with
`searchMatcher: (item, query) => ...`.

## Online

Your `fetchPage` receives a `PageRequest` and returns a `PageResult<T>`.
Map the API response to your own model inside it.

```dart
PaginatedDropdown<User>.online(
  fetchPage: (request) async {
    // request.queryParameters == {'page': '1', 'limit': '20', 'search': 'jo'}
    final res = await dio.get('/users', queryParameters: request.queryParameters);
    final users = (res.data['data'] as List).map((e) => User.fromJson(e)).toList();
    return PageResult(items: users, totalCount: res.data['total']);
  },
  itemLabel: (user) => user.name,
  itemEquals: (a, b) => a.id == b.id,   // results are new objects each fetch
  value: selectedUser,
  onChanged: (user) => setState(() => selectedUser = user),
)
```

### Query strings

| Option | Default | Purpose |
| --- | --- | --- |
| `queryKeys` | `PaginationQueryKeys(pageKey: 'page', pageSizeKey: 'limit', searchKey: 'search')` | Names of the query keys your API expects. Set `searchKey: null` to never send search. |
| `extraQueryParameters` | `{}` | Static params added to every request (filters, sort...). |
| `firstPageIndex` | `1` | Use `0` for zero-based APIs. |
| `pageSize` | `20` | Items per page. |
| `searchDebounce` | `400ms` | Wait after typing before calling the API. |
| `refreshOnOpen` | `false` | Reload from page 1 each time the dropdown opens. |

`PageRequest` also exposes `page`, `pageSize`, `searchText` and
`offset(firstPageIndex:)` for offset/skip based APIs, or if you need to build
a request body instead of query strings.

### Dependent dropdowns (e.g. City filtered by Country)

Pass the filter through `extraQueryParameters`. When the map changes, the list
reloads from page 1:

```dart
PaginatedDropdown<City>.online(
  extraQueryParameters: {'countryId': '${selectedCountry?.id}'},
  value: selectedCity,          // set to null when the country changes
  fetchPage: fetchCities,
  itemLabel: (c) => c.name,
)
```

If the dependency is only captured inside the `fetchPage` closure, give the
widget `key: ValueKey(countryId)` or call `refresh()` through a
`GlobalKey<PaginatedDropdownState<City>>`.

### End of data

Return whichever your API gives you:

- `PageResult(items: ..., hasMore: true/false)`, or
- `PageResult(items: ..., totalCount: 235)`, or
- just `PageResult(items: ...)` – the list ends when a page has fewer than `pageSize` items.

## Display modes

```dart
PaginatedDropdown<User>.online(
  displayMode: DropdownDisplayMode.dialog,   // menu (default) | dialog | bottomSheet
  title: 'Requester',
  ...
)
```

| Option | Default | Purpose |
| --- | --- | --- |
| `displayMode` | theme's `displayMode`, else `menu` | `menu` attaches a panel to the field, `dialog` opens a centered modal, `bottomSheet` opens a modal bottom sheet |
| `title` | `null` | Header title shown above the search box |
| `showCloseButton` | `true` for dialog and bottom sheet | Close button in the header |
| `autofocusSearch` | `true` for menu only | Opens the keyboard immediately |
| `barrierDismissible` | `true` | Tapping the dimmed background closes it |

To make **every** dropdown in the app open as a dialog, set it once in the theme:

```dart
ThemeData(extensions: [
  PaginatedDropdownTheme(
    displayMode: DropdownDisplayMode.dialog,
    style: myDropdownStyle,
  ),
])
```

A modal with a navy header, centered title, white pill search box and rounded
card rows:

```dart
style: PaginatedDropdownStyle(
  panelColor: Colors.white,
  panelBorderRadius: BorderRadius.circular(24),
  headerColor: Color(0xFF160A50),
  headerPadding: EdgeInsets.fromLTRB(16, 12, 8, 24),
  titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
  closeIconColor: Colors.white,
  searchPadding: EdgeInsets.fromLTRB(0, 12, 8, 0),
  searchDecoration: InputDecoration(
    filled: true,
    fillColor: Colors.white,
    suffixIcon: Icon(Icons.search),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
  ),
  showSearchDivider: false,
  itemMargin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  itemBorderRadius: BorderRadius.circular(18),
  itemBackgroundColor: Color(0xFFF5F4FA),
  itemTextStyle: TextStyle(color: Color(0xFF160A50), fontWeight: FontWeight.w600),
),
```

The full version is `requesterStyle` in `example/lib/main.dart`.

## Styling

Everything visual is customisable at three levels. Later levels win:

1. Built-in defaults (from your app's `ThemeData`)
2. App-wide: the `PaginatedDropdownTheme` extension
3. Per widget: the `style:` and `texts:` parameters

### Per widget

```dart
PaginatedDropdown<String>.offline(
  items: fruits,
  itemLabel: (f) => f,
  style: PaginatedDropdownStyle(
    fieldDecoration: InputDecoration(filled: true, border: OutlineInputBorder()),
    panelColor: Colors.white,
    panelBorderRadius: BorderRadius.circular(16),
    itemTextStyle: TextStyle(fontSize: 15),
    selectedItemBackgroundColor: Colors.teal.shade100,
    selectedItemIcon: Icon(Icons.check_circle, color: Colors.teal),
    showItemSeparators: true,
  ),
  texts: PaginatedDropdownTexts(searchHint: 'Type to filter', noItems: 'Nothing found'),
)
```

### App-wide

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      PaginatedDropdownTheme(
        style: PaginatedDropdownStyle(panelElevation: 4, maxPanelHeight: 300),
        texts: PaginatedDropdownTexts(retry: 'Try again'),
      ),
    ],
  ),
)
```

### Fonts and text sizes

Set the font once with `fontFamily`, then size/weight/color each text with its
own style. Individual styles inherit `fontFamily` unless they set their own.

```dart
style: PaginatedDropdownStyle(
  fontFamily: 'Montserrat',                       // every text in the dropdown
  hintTextStyle: TextStyle(fontSize: 15, color: Colors.black45),
  selectedTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
  searchTextStyle: TextStyle(fontSize: 16),
  searchHintStyle: TextStyle(fontSize: 16, letterSpacing: 1),
  itemTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  selectedItemTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  messageTextStyle: TextStyle(fontSize: 14),
  errorTextStyle: TextStyle(fontSize: 12),
),
```

| Text | Property |
| --- | --- |
| Placeholder in the closed field (`hintText`) | `hintTextStyle` |
| Selected value in the closed field | `selectedTextStyle` |
| Validation error under the field | `errorTextStyle` |
| Dialog / sheet title | `titleTextStyle` |
| Text typed in the search box | `searchTextStyle` |
| Search placeholder | `searchHintStyle` |
| Rows | `itemTextStyle` |
| Selected row | `selectedItemTextStyle` |
| "No items", error and "failed to load more" messages | `messageTextStyle` |
| Retry buttons | `retryButtonStyle` (`ButtonStyle.textStyle`) |

> **google_fonts:** it registers every weight as a separate family
> (`Montserrat_regular`, `Montserrat_700`), so `fontFamily` alone only gives
> the regular weight. Use `GoogleFonts.montserrat(fontWeight: ...)` for bold
> styles, or bundle the font in `pubspec.yaml` and use `fontFamily: 'Montserrat'`.

### `PaginatedDropdownStyle` properties

| Area | Properties |
| --- | --- |
| Typography | `fontFamily`, `hintTextStyle`, `errorTextStyle`, `searchHintStyle` (plus the text styles listed in each area) |
| Field | `fieldDecoration`, `selectedTextStyle`, `dropdownIcon`, `dropdownIconOpen`, `dropdownIconPadding`, `clearIcon`, `iconColor` |
| Panel | `panelColor`, `panelElevation`, `panelShadowColor`, `panelBorderRadius`, `panelBorder`, `panelDecoration` (gradients/custom shadows), `panelPadding`, `panelGap`, `maxPanelHeight`, `panelWidth` |
| Search | `searchDecoration`, `searchTextStyle`, `searchPadding`, `searchCursorColor`, `showSearchDivider`, `dividerColor` |
| Header | `headerColor`, `headerPadding` (keep left = right so the title stays centered), `titleTextStyle`, `closeIcon`, `closeIconColor` |
| Dialog / sheet | `dialogInsetPadding`, `dialogMaxWidth`, `dialogMaxHeight`, `barrierColor` |
| Items | `listPadding`, `itemMargin`, `itemBorderRadius`, `itemPadding`, `itemMinHeight`, `itemTextStyle`, `selectedItemTextStyle`, `itemBackgroundColor`, `selectedItemBackgroundColor`, `itemHoverColor`, `itemSplashColor`, `selectedItemIcon`, `showSelectedItemIcon`, `showItemSeparators`, `separatorColor`, `separatorIndent` |
| States | `loadingIndicatorColor`, `messageTextStyle`, `errorIconColor`, `retryButtonStyle` |

`PaginatedDropdownTexts` covers `searchHint`, `noItems`, `error`,
`loadMoreError` and `retry`, so you can translate every string.

### Builders (replace any part completely)

| Builder | Replaces |
| --- | --- |
| `fieldBuilder: (context, value, isOpen, errorText)` | The whole closed field. Taps still open and close it. |
| `selectedItemBuilder: (context, value)` | The selected value inside the default field |
| `itemBuilder: (context, item, isSelected)` | Each row |
| `separatorBuilder: (context, index)` | The divider between rows |
| `searchBuilder: (context, controller, onChanged)` | The search box |
| `panelBuilder: (context, child)` | Wraps the panel content, e.g. to add a header or footer |
| `loadingBuilder`, `emptyBuilder`, `errorBuilder` | First-page loading, empty and error views |
| `loadingMoreBuilder`, `loadMoreErrorBuilder` | The bottom-of-list loader and the "load more" error |

## Other options

| Option | Purpose |
| --- | --- |
| `decoration` | `InputDecoration` for the closed field (overrides `style.fieldDecoration`) |
| `hintText` | Shown when nothing is selected |
| `showSearch` | Hide the search box |
| `showClearButton` | Show a button that clears the selection |
| `validator`, `onSaved`, `autovalidateMode` | Form integration |

Use a `GlobalKey<PaginatedDropdownState<T>>` to call `refresh()`, `open()` or
`close()` from outside.

## Example

See [`example/lib/main.dart`](example/lib/main.dart).

```bash
cd example && flutter run
```

## License

MIT, see [LICENSE](LICENSE).

---

<p align="center">Made with ❤️ by <a href="https://fidenz.com">Fidenz Technologies</a></p>

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// How the list is presented when the field is tapped.
enum DropdownDisplayMode {
  /// A floating panel attached below (or above) the field.
  menu,

  /// A centered dialog over a dimmed background.
  dialog,

  /// A modal bottom sheet.
  bottomSheet,
}

/// Visual properties of a [PaginatedDropdown].
///
/// Every value is optional. Values are resolved in this order:
/// widget `style` → [PaginatedDropdownTheme] in `ThemeData.extensions` →
/// [PaginatedDropdownStyle.defaults] (derived from the app's [ThemeData]).
@immutable
class PaginatedDropdownStyle {
  const PaginatedDropdownStyle({
    // Typography
    this.fontFamily,
    this.hintTextStyle,
    this.errorTextStyle,
    this.searchHintStyle,
    // Field
    this.fieldDecoration,
    this.selectedTextStyle,
    this.dropdownIcon,
    this.dropdownIconOpen,
    this.dropdownIconPadding,
    this.clearIcon,
    this.iconColor,
    // Panel
    this.panelColor,
    this.panelElevation,
    this.panelShadowColor,
    this.panelBorderRadius,
    this.panelBorder,
    this.panelDecoration,
    this.panelPadding,
    this.panelGap,
    this.maxPanelHeight,
    this.panelWidth,
    // Search
    this.searchDecoration,
    this.searchTextStyle,
    this.searchPadding,
    this.searchCursorColor,
    this.showSearchDivider,
    this.dividerColor,
    // Items
    this.listPadding,
    this.itemPadding,
    this.itemMinHeight,
    this.itemTextStyle,
    this.selectedItemTextStyle,
    this.itemBackgroundColor,
    this.selectedItemBackgroundColor,
    this.itemHoverColor,
    this.itemSplashColor,
    this.selectedItemIcon,
    this.showSelectedItemIcon,
    this.showItemSeparators,
    this.separatorColor,
    this.separatorIndent,
    // States
    this.loadingIndicatorColor,
    this.messageTextStyle,
    this.errorIconColor,
    this.retryButtonStyle,
    // Header & modal
    this.headerColor,
    this.headerPadding,
    this.titleTextStyle,
    this.closeIcon,
    this.closeIconColor,
    this.itemMargin,
    this.itemBorderRadius,
    this.dialogInsetPadding,
    this.dialogMaxWidth,
    this.dialogMaxHeight,
    this.barrierColor,
  });

  /// Fallback values derived from [theme].
  factory PaginatedDropdownStyle.defaults(ThemeData theme) {
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    return PaginatedDropdownStyle(
      fieldDecoration: const InputDecoration(),
      selectedTextStyle: text.bodyLarge,
      dropdownIcon: const Icon(Icons.arrow_drop_down),
      dropdownIconOpen: const Icon(Icons.arrow_drop_up),
      dropdownIconPadding: const EdgeInsetsDirectional.only(end: 8),
      clearIcon: const Icon(Icons.clear, size: 20),
      iconColor: scheme.onSurfaceVariant,
      panelColor: scheme.surfaceContainer,
      panelElevation: 8,
      panelShadowColor: scheme.shadow,
      panelBorderRadius: BorderRadius.circular(8),
      panelBorder: BorderSide.none,
      panelPadding: EdgeInsets.zero,
      panelGap: 4,
      maxPanelHeight: 350,
      searchDecoration: const InputDecoration(
        isDense: true,
        prefixIcon: Icon(Icons.search, size: 20),
        border: OutlineInputBorder(),
      ),
      searchTextStyle: text.bodyMedium,
      searchPadding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      searchCursorColor: scheme.primary,
      showSearchDivider: true,
      dividerColor: theme.dividerColor,
      listPadding: const EdgeInsets.symmetric(vertical: 4),
      itemPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemMinHeight: 40,
      itemTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
      selectedItemTextStyle: text.bodyMedium?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w600,
      ),
      itemBackgroundColor: Colors.transparent,
      selectedItemBackgroundColor: scheme.primary.withValues(alpha: 0.08),
      itemHoverColor: scheme.onSurface.withValues(alpha: 0.06),
      itemSplashColor: scheme.primary.withValues(alpha: 0.12),
      selectedItemIcon: Icon(Icons.check, size: 18, color: scheme.primary),
      showSelectedItemIcon: true,
      showItemSeparators: false,
      separatorColor: theme.dividerColor,
      separatorIndent: 0,
      loadingIndicatorColor: scheme.primary,
      messageTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      errorIconColor: scheme.error,
      headerPadding: const EdgeInsets.all(8),
      titleTextStyle: text.titleLarge,
      closeIcon: const Icon(Icons.close),
      closeIconColor: scheme.onSurfaceVariant,
      itemMargin: EdgeInsets.zero,
      itemBorderRadius: BorderRadius.zero,
      dialogInsetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      dialogMaxWidth: 560,
    );
  }

  // ----------------------------------------------------------- Typography

  /// Font family for every text in the dropdown (field, title, search,
  /// rows, messages, buttons). A family set on an individual text style wins.
  final String? fontFamily;

  /// Style of the placeholder in the closed field (`hintText`).
  final TextStyle? hintTextStyle;

  /// Style of the validation error under the closed field.
  final TextStyle? errorTextStyle;

  /// Style of the search box placeholder.
  final TextStyle? searchHintStyle;

  // ---------------------------------------------------------------- Field

  /// Decoration of the closed field (border, label, fill, ...). The widget's
  /// own `decoration` parameter takes precedence.
  final InputDecoration? fieldDecoration;

  /// Text style of the selected value shown in the closed field.
  final TextStyle? selectedTextStyle;

  /// Arrow shown while closed.
  final Widget? dropdownIcon;

  /// Arrow shown while open. Defaults to an up arrow.
  final Widget? dropdownIconOpen;

  /// Space around the arrow, e.g. `EdgeInsetsDirectional.only(end: 8)`.
  /// Use it to line the arrow up with your other fields.
  final EdgeInsetsGeometry? dropdownIconPadding;

  /// Icon of the clear button (when `showClearButton` is true).
  final Widget? clearIcon;

  /// Color applied to the arrow and clear icons.
  final Color? iconColor;

  // ---------------------------------------------------------------- Panel

  final Color? panelColor;
  final double? panelElevation;
  final Color? panelShadowColor;
  final BorderRadiusGeometry? panelBorderRadius;
  final BorderSide? panelBorder;

  /// Full control over the panel background (gradients, custom shadows...).
  /// When set, [panelColor], [panelBorder], [panelElevation] and
  /// [panelShadowColor] are ignored; [panelBorderRadius] still clips.
  final BoxDecoration? panelDecoration;

  /// Padding inside the panel, around search and list.
  final EdgeInsetsGeometry? panelPadding;

  /// Distance between the field and the panel.
  final double? panelGap;

  /// Maximum panel height. The panel also shrinks to fit the screen.
  final double? maxPanelHeight;

  /// Panel width. `null` matches the field width.
  final double? panelWidth;

  // --------------------------------------------------------------- Search

  /// Decoration of the search box. Its `hintText` is filled from
  /// [PaginatedDropdownTexts.searchHint] when not set.
  final InputDecoration? searchDecoration;
  final TextStyle? searchTextStyle;
  final EdgeInsetsGeometry? searchPadding;
  final Color? searchCursorColor;

  /// Line between the search box and the list.
  final bool? showSearchDivider;
  final Color? dividerColor;

  // ---------------------------------------------------------------- Items

  /// Padding around the whole list.
  final EdgeInsetsGeometry? listPadding;

  /// Padding inside each default item row.
  final EdgeInsetsGeometry? itemPadding;
  final double? itemMinHeight;
  final TextStyle? itemTextStyle;
  final TextStyle? selectedItemTextStyle;
  final Color? itemBackgroundColor;
  final Color? selectedItemBackgroundColor;
  final Color? itemHoverColor;
  final Color? itemSplashColor;

  /// Trailing icon on the selected row.
  final Widget? selectedItemIcon;
  final bool? showSelectedItemIcon;

  /// Draws a divider between rows.
  final bool? showItemSeparators;
  final Color? separatorColor;
  final double? separatorIndent;

  // --------------------------------------------------------------- States

  final Color? loadingIndicatorColor;

  /// Style of the empty / error / "failed to load more" messages.
  final TextStyle? messageTextStyle;
  final Color? errorIconColor;
  final ButtonStyle? retryButtonStyle;

  // ------------------------------------------------------ Header & modal

  /// Background of the header (title, close button and search).
  /// Transparent by default.
  final Color? headerColor;

  /// Padding of the header. Keep left and right equal so a centered title
  /// stays centered in the panel.
  final EdgeInsetsGeometry? headerPadding;

  /// Style of the `title`.
  final TextStyle? titleTextStyle;

  /// Icon of the close button in the header.
  final Widget? closeIcon;

  /// Color of the close button.
  final Color? closeIconColor;

  /// Space around each default row. Combine with [itemBorderRadius] and
  /// [itemBackgroundColor] for card-like rows.
  final EdgeInsetsGeometry? itemMargin;

  /// Corner radius of each default row.
  final BorderRadiusGeometry? itemBorderRadius;

  /// Distance between the dialog and the screen edges (dialog mode).
  final EdgeInsets? dialogInsetPadding;

  /// Maximum dialog width (dialog mode).
  final double? dialogMaxWidth;

  /// Maximum height in dialog / bottom sheet mode. Defaults to 80% of
  /// the screen height.
  final double? dialogMaxHeight;

  /// Color of the scrim behind a dialog / bottom sheet.
  final Color? barrierColor;

  /// [theme] with [fontFamily] applied to its text themes, so defaults,
  /// hints, buttons and messages all use it.
  static ThemeData applyFontFamily(ThemeData theme, String? fontFamily) {
    if (fontFamily == null) return theme;
    return theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: fontFamily),
      primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: fontFamily),
    );
  }

  /// Returns a copy where every non-null value of [other] wins.
  PaginatedDropdownStyle merge(PaginatedDropdownStyle? other) {
    if (other == null) return this;
    return PaginatedDropdownStyle(
      fontFamily: other.fontFamily ?? fontFamily,
      hintTextStyle:
          hintTextStyle?.merge(other.hintTextStyle) ?? other.hintTextStyle,
      errorTextStyle:
          errorTextStyle?.merge(other.errorTextStyle) ?? other.errorTextStyle,
      searchHintStyle: searchHintStyle?.merge(other.searchHintStyle) ??
          other.searchHintStyle,
      fieldDecoration: other.fieldDecoration ?? fieldDecoration,
      selectedTextStyle: selectedTextStyle?.merge(other.selectedTextStyle) ??
          other.selectedTextStyle,
      dropdownIcon: other.dropdownIcon ?? dropdownIcon,
      dropdownIconOpen: other.dropdownIconOpen ??
          (other.dropdownIcon != null ? null : dropdownIconOpen),
      dropdownIconPadding: other.dropdownIconPadding ?? dropdownIconPadding,
      clearIcon: other.clearIcon ?? clearIcon,
      iconColor: other.iconColor ?? iconColor,
      panelColor: other.panelColor ?? panelColor,
      panelElevation: other.panelElevation ?? panelElevation,
      panelShadowColor: other.panelShadowColor ?? panelShadowColor,
      panelBorderRadius: other.panelBorderRadius ?? panelBorderRadius,
      panelBorder: other.panelBorder ?? panelBorder,
      panelDecoration: other.panelDecoration ?? panelDecoration,
      panelPadding: other.panelPadding ?? panelPadding,
      panelGap: other.panelGap ?? panelGap,
      maxPanelHeight: other.maxPanelHeight ?? maxPanelHeight,
      panelWidth: other.panelWidth ?? panelWidth,
      searchDecoration: other.searchDecoration ?? searchDecoration,
      searchTextStyle: searchTextStyle?.merge(other.searchTextStyle) ??
          other.searchTextStyle,
      searchPadding: other.searchPadding ?? searchPadding,
      searchCursorColor: other.searchCursorColor ?? searchCursorColor,
      showSearchDivider: other.showSearchDivider ?? showSearchDivider,
      dividerColor: other.dividerColor ?? dividerColor,
      listPadding: other.listPadding ?? listPadding,
      itemPadding: other.itemPadding ?? itemPadding,
      itemMinHeight: other.itemMinHeight ?? itemMinHeight,
      itemTextStyle:
          itemTextStyle?.merge(other.itemTextStyle) ?? other.itemTextStyle,
      selectedItemTextStyle:
          selectedItemTextStyle?.merge(other.selectedItemTextStyle) ??
              other.selectedItemTextStyle,
      itemBackgroundColor: other.itemBackgroundColor ?? itemBackgroundColor,
      selectedItemBackgroundColor:
          other.selectedItemBackgroundColor ?? selectedItemBackgroundColor,
      itemHoverColor: other.itemHoverColor ?? itemHoverColor,
      itemSplashColor: other.itemSplashColor ?? itemSplashColor,
      selectedItemIcon: other.selectedItemIcon ?? selectedItemIcon,
      showSelectedItemIcon: other.showSelectedItemIcon ?? showSelectedItemIcon,
      showItemSeparators: other.showItemSeparators ?? showItemSeparators,
      separatorColor: other.separatorColor ?? separatorColor,
      separatorIndent: other.separatorIndent ?? separatorIndent,
      loadingIndicatorColor:
          other.loadingIndicatorColor ?? loadingIndicatorColor,
      messageTextStyle: messageTextStyle?.merge(other.messageTextStyle) ??
          other.messageTextStyle,
      errorIconColor: other.errorIconColor ?? errorIconColor,
      retryButtonStyle: other.retryButtonStyle ?? retryButtonStyle,
      headerColor: other.headerColor ?? headerColor,
      headerPadding: other.headerPadding ?? headerPadding,
      titleTextStyle:
          titleTextStyle?.merge(other.titleTextStyle) ?? other.titleTextStyle,
      closeIcon: other.closeIcon ?? closeIcon,
      closeIconColor: other.closeIconColor ?? closeIconColor,
      itemMargin: other.itemMargin ?? itemMargin,
      itemBorderRadius: other.itemBorderRadius ?? itemBorderRadius,
      dialogInsetPadding: other.dialogInsetPadding ?? dialogInsetPadding,
      dialogMaxWidth: other.dialogMaxWidth ?? dialogMaxWidth,
      dialogMaxHeight: other.dialogMaxHeight ?? dialogMaxHeight,
      barrierColor: other.barrierColor ?? barrierColor,
    );
  }

  /// Copy with the given values replaced.
  PaginatedDropdownStyle copyWith({
    String? fontFamily,
    TextStyle? hintTextStyle,
    TextStyle? errorTextStyle,
    TextStyle? searchHintStyle,
    InputDecoration? fieldDecoration,
    TextStyle? selectedTextStyle,
    Widget? dropdownIcon,
    Widget? dropdownIconOpen,
    EdgeInsetsGeometry? dropdownIconPadding,
    Widget? clearIcon,
    Color? iconColor,
    Color? panelColor,
    double? panelElevation,
    Color? panelShadowColor,
    BorderRadiusGeometry? panelBorderRadius,
    BorderSide? panelBorder,
    BoxDecoration? panelDecoration,
    EdgeInsetsGeometry? panelPadding,
    double? panelGap,
    double? maxPanelHeight,
    double? panelWidth,
    InputDecoration? searchDecoration,
    TextStyle? searchTextStyle,
    EdgeInsetsGeometry? searchPadding,
    Color? searchCursorColor,
    bool? showSearchDivider,
    Color? dividerColor,
    EdgeInsetsGeometry? listPadding,
    EdgeInsetsGeometry? itemPadding,
    double? itemMinHeight,
    TextStyle? itemTextStyle,
    TextStyle? selectedItemTextStyle,
    Color? itemBackgroundColor,
    Color? selectedItemBackgroundColor,
    Color? itemHoverColor,
    Color? itemSplashColor,
    Widget? selectedItemIcon,
    bool? showSelectedItemIcon,
    bool? showItemSeparators,
    Color? separatorColor,
    double? separatorIndent,
    Color? loadingIndicatorColor,
    TextStyle? messageTextStyle,
    Color? errorIconColor,
    ButtonStyle? retryButtonStyle,
    Color? headerColor,
    EdgeInsetsGeometry? headerPadding,
    TextStyle? titleTextStyle,
    Widget? closeIcon,
    Color? closeIconColor,
    EdgeInsetsGeometry? itemMargin,
    BorderRadiusGeometry? itemBorderRadius,
    EdgeInsets? dialogInsetPadding,
    double? dialogMaxWidth,
    double? dialogMaxHeight,
    Color? barrierColor,
  }) {
    return PaginatedDropdownStyle(
      fontFamily: fontFamily ?? this.fontFamily,
      hintTextStyle: hintTextStyle ?? this.hintTextStyle,
      errorTextStyle: errorTextStyle ?? this.errorTextStyle,
      searchHintStyle: searchHintStyle ?? this.searchHintStyle,
      fieldDecoration: fieldDecoration ?? this.fieldDecoration,
      selectedTextStyle: selectedTextStyle ?? this.selectedTextStyle,
      dropdownIcon: dropdownIcon ?? this.dropdownIcon,
      dropdownIconOpen: dropdownIconOpen ?? this.dropdownIconOpen,
      dropdownIconPadding: dropdownIconPadding ?? this.dropdownIconPadding,
      clearIcon: clearIcon ?? this.clearIcon,
      iconColor: iconColor ?? this.iconColor,
      panelColor: panelColor ?? this.panelColor,
      panelElevation: panelElevation ?? this.panelElevation,
      panelShadowColor: panelShadowColor ?? this.panelShadowColor,
      panelBorderRadius: panelBorderRadius ?? this.panelBorderRadius,
      panelBorder: panelBorder ?? this.panelBorder,
      panelDecoration: panelDecoration ?? this.panelDecoration,
      panelPadding: panelPadding ?? this.panelPadding,
      panelGap: panelGap ?? this.panelGap,
      maxPanelHeight: maxPanelHeight ?? this.maxPanelHeight,
      panelWidth: panelWidth ?? this.panelWidth,
      searchDecoration: searchDecoration ?? this.searchDecoration,
      searchTextStyle: searchTextStyle ?? this.searchTextStyle,
      searchPadding: searchPadding ?? this.searchPadding,
      searchCursorColor: searchCursorColor ?? this.searchCursorColor,
      showSearchDivider: showSearchDivider ?? this.showSearchDivider,
      dividerColor: dividerColor ?? this.dividerColor,
      listPadding: listPadding ?? this.listPadding,
      itemPadding: itemPadding ?? this.itemPadding,
      itemMinHeight: itemMinHeight ?? this.itemMinHeight,
      itemTextStyle: itemTextStyle ?? this.itemTextStyle,
      selectedItemTextStyle:
          selectedItemTextStyle ?? this.selectedItemTextStyle,
      itemBackgroundColor: itemBackgroundColor ?? this.itemBackgroundColor,
      selectedItemBackgroundColor:
          selectedItemBackgroundColor ?? this.selectedItemBackgroundColor,
      itemHoverColor: itemHoverColor ?? this.itemHoverColor,
      itemSplashColor: itemSplashColor ?? this.itemSplashColor,
      selectedItemIcon: selectedItemIcon ?? this.selectedItemIcon,
      showSelectedItemIcon: showSelectedItemIcon ?? this.showSelectedItemIcon,
      showItemSeparators: showItemSeparators ?? this.showItemSeparators,
      separatorColor: separatorColor ?? this.separatorColor,
      separatorIndent: separatorIndent ?? this.separatorIndent,
      loadingIndicatorColor:
          loadingIndicatorColor ?? this.loadingIndicatorColor,
      messageTextStyle: messageTextStyle ?? this.messageTextStyle,
      errorIconColor: errorIconColor ?? this.errorIconColor,
      retryButtonStyle: retryButtonStyle ?? this.retryButtonStyle,
      headerColor: headerColor ?? this.headerColor,
      headerPadding: headerPadding ?? this.headerPadding,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      closeIcon: closeIcon ?? this.closeIcon,
      closeIconColor: closeIconColor ?? this.closeIconColor,
      itemMargin: itemMargin ?? this.itemMargin,
      itemBorderRadius: itemBorderRadius ?? this.itemBorderRadius,
      dialogInsetPadding: dialogInsetPadding ?? this.dialogInsetPadding,
      dialogMaxWidth: dialogMaxWidth ?? this.dialogMaxWidth,
      dialogMaxHeight: dialogMaxHeight ?? this.dialogMaxHeight,
      barrierColor: barrierColor ?? this.barrierColor,
    );
  }

  /// Interpolates colors, sizes and text styles; other values snap at 0.5.
  static PaginatedDropdownStyle lerp(
    PaginatedDropdownStyle a,
    PaginatedDropdownStyle b,
    double t,
  ) {
    T snap<T>(T x, T y) => t < 0.5 ? x : y;
    return PaginatedDropdownStyle(
      fontFamily: snap(a.fontFamily, b.fontFamily),
      hintTextStyle: TextStyle.lerp(a.hintTextStyle, b.hintTextStyle, t),
      errorTextStyle: TextStyle.lerp(a.errorTextStyle, b.errorTextStyle, t),
      searchHintStyle: TextStyle.lerp(a.searchHintStyle, b.searchHintStyle, t),
      fieldDecoration: snap(a.fieldDecoration, b.fieldDecoration),
      selectedTextStyle: TextStyle.lerp(
        a.selectedTextStyle,
        b.selectedTextStyle,
        t,
      ),
      dropdownIcon: snap(a.dropdownIcon, b.dropdownIcon),
      dropdownIconOpen: snap(a.dropdownIconOpen, b.dropdownIconOpen),
      dropdownIconPadding: EdgeInsetsGeometry.lerp(
        a.dropdownIconPadding,
        b.dropdownIconPadding,
        t,
      ),
      clearIcon: snap(a.clearIcon, b.clearIcon),
      iconColor: Color.lerp(a.iconColor, b.iconColor, t),
      panelColor: Color.lerp(a.panelColor, b.panelColor, t),
      panelElevation: lerpDouble(a.panelElevation, b.panelElevation, t),
      panelShadowColor: Color.lerp(a.panelShadowColor, b.panelShadowColor, t),
      panelBorderRadius: BorderRadiusGeometry.lerp(
        a.panelBorderRadius,
        b.panelBorderRadius,
        t,
      ),
      panelBorder: snap(a.panelBorder, b.panelBorder),
      panelDecoration: BoxDecoration.lerp(
        a.panelDecoration,
        b.panelDecoration,
        t,
      ),
      panelPadding: EdgeInsetsGeometry.lerp(a.panelPadding, b.panelPadding, t),
      panelGap: lerpDouble(a.panelGap, b.panelGap, t),
      maxPanelHeight: lerpDouble(a.maxPanelHeight, b.maxPanelHeight, t),
      panelWidth: lerpDouble(a.panelWidth, b.panelWidth, t),
      searchDecoration: snap(a.searchDecoration, b.searchDecoration),
      searchTextStyle: TextStyle.lerp(a.searchTextStyle, b.searchTextStyle, t),
      searchPadding: EdgeInsetsGeometry.lerp(
        a.searchPadding,
        b.searchPadding,
        t,
      ),
      searchCursorColor: Color.lerp(
        a.searchCursorColor,
        b.searchCursorColor,
        t,
      ),
      showSearchDivider: snap(a.showSearchDivider, b.showSearchDivider),
      dividerColor: Color.lerp(a.dividerColor, b.dividerColor, t),
      listPadding: EdgeInsetsGeometry.lerp(a.listPadding, b.listPadding, t),
      itemPadding: EdgeInsetsGeometry.lerp(a.itemPadding, b.itemPadding, t),
      itemMinHeight: lerpDouble(a.itemMinHeight, b.itemMinHeight, t),
      itemTextStyle: TextStyle.lerp(a.itemTextStyle, b.itemTextStyle, t),
      selectedItemTextStyle: TextStyle.lerp(
        a.selectedItemTextStyle,
        b.selectedItemTextStyle,
        t,
      ),
      itemBackgroundColor: Color.lerp(
        a.itemBackgroundColor,
        b.itemBackgroundColor,
        t,
      ),
      selectedItemBackgroundColor: Color.lerp(
        a.selectedItemBackgroundColor,
        b.selectedItemBackgroundColor,
        t,
      ),
      itemHoverColor: Color.lerp(a.itemHoverColor, b.itemHoverColor, t),
      itemSplashColor: Color.lerp(a.itemSplashColor, b.itemSplashColor, t),
      selectedItemIcon: snap(a.selectedItemIcon, b.selectedItemIcon),
      showSelectedItemIcon:
          snap(a.showSelectedItemIcon, b.showSelectedItemIcon),
      showItemSeparators: snap(a.showItemSeparators, b.showItemSeparators),
      separatorColor: Color.lerp(a.separatorColor, b.separatorColor, t),
      separatorIndent: lerpDouble(a.separatorIndent, b.separatorIndent, t),
      loadingIndicatorColor: Color.lerp(
        a.loadingIndicatorColor,
        b.loadingIndicatorColor,
        t,
      ),
      messageTextStyle: TextStyle.lerp(
        a.messageTextStyle,
        b.messageTextStyle,
        t,
      ),
      errorIconColor: Color.lerp(a.errorIconColor, b.errorIconColor, t),
      retryButtonStyle: ButtonStyle.lerp(
        a.retryButtonStyle,
        b.retryButtonStyle,
        t,
      ),
      headerColor: Color.lerp(a.headerColor, b.headerColor, t),
      headerPadding:
          EdgeInsetsGeometry.lerp(a.headerPadding, b.headerPadding, t),
      titleTextStyle: TextStyle.lerp(a.titleTextStyle, b.titleTextStyle, t),
      closeIcon: snap(a.closeIcon, b.closeIcon),
      closeIconColor: Color.lerp(a.closeIconColor, b.closeIconColor, t),
      itemMargin: EdgeInsetsGeometry.lerp(a.itemMargin, b.itemMargin, t),
      itemBorderRadius:
          BorderRadiusGeometry.lerp(a.itemBorderRadius, b.itemBorderRadius, t),
      dialogInsetPadding: snap(a.dialogInsetPadding, b.dialogInsetPadding),
      dialogMaxWidth: lerpDouble(a.dialogMaxWidth, b.dialogMaxWidth, t),
      dialogMaxHeight: lerpDouble(a.dialogMaxHeight, b.dialogMaxHeight, t),
      barrierColor: Color.lerp(a.barrierColor, b.barrierColor, t),
    );
  }
}

/// All user-facing strings, for localisation.
@immutable
class PaginatedDropdownTexts {
  const PaginatedDropdownTexts({
    this.searchHint,
    this.noItems,
    this.error,
    this.loadMoreError,
    this.retry,
  });

  static const defaults = PaginatedDropdownTexts(
    searchHint: 'Search...',
    noItems: 'No items found',
    error: 'Something went wrong',
    loadMoreError: 'Failed to load more',
    retry: 'Retry',
  );

  final String? searchHint;
  final String? noItems;
  final String? error;
  final String? loadMoreError;
  final String? retry;

  /// Returns a copy where every non-null value of [other] wins.
  PaginatedDropdownTexts merge(PaginatedDropdownTexts? other) {
    if (other == null) return this;
    return PaginatedDropdownTexts(
      searchHint: other.searchHint ?? searchHint,
      noItems: other.noItems ?? noItems,
      error: other.error ?? error,
      loadMoreError: other.loadMoreError ?? loadMoreError,
      retry: other.retry ?? retry,
    );
  }
}

/// App-wide style, texts and display mode for every [PaginatedDropdown]:
///
/// ```dart
/// ThemeData(extensions: [
///   PaginatedDropdownTheme(style: PaginatedDropdownStyle(panelColor: ...)),
/// ])
/// ```
class PaginatedDropdownTheme extends ThemeExtension<PaginatedDropdownTheme> {
  const PaginatedDropdownTheme({
    this.style = const PaginatedDropdownStyle(),
    this.texts = const PaginatedDropdownTexts(),
    this.displayMode,
  });

  final PaginatedDropdownStyle style;
  final PaginatedDropdownTexts texts;

  /// Default display mode for dropdowns that don't set `displayMode`.
  final DropdownDisplayMode? displayMode;

  static PaginatedDropdownTheme? of(BuildContext context) =>
      Theme.of(context).extension<PaginatedDropdownTheme>();

  @override
  PaginatedDropdownTheme copyWith({
    PaginatedDropdownStyle? style,
    PaginatedDropdownTexts? texts,
  }) =>
      PaginatedDropdownTheme(
        style: style ?? this.style,
        texts: texts ?? this.texts,
      );

  @override
  PaginatedDropdownTheme lerp(PaginatedDropdownTheme? other, double t) {
    if (other == null) return this;
    return PaginatedDropdownTheme(
      style: PaginatedDropdownStyle.lerp(style, other.style, t),
      texts: t < 0.5 ? texts : other.texts,
      displayMode: t < 0.5 ? displayMode : other.displayMode,
    );
  }
}

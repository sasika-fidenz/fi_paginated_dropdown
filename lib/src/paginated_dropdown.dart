import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data_source.dart';
import 'dropdown_style.dart';
import 'page_models.dart';
import 'paginated_dropdown_controller.dart';

/// Builds a row in the dropdown list.
typedef DropdownItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  bool isSelected,
);

/// Builds the full-panel error view shown when the first page fails.
typedef DropdownErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  VoidCallback retry,
);

/// Builds the whole closed field. Taps on it open/close the dropdown.
typedef DropdownFieldBuilder<T> = Widget Function(
  BuildContext context,
  T? value,
  bool isOpen,
  String? errorText,
);

/// Builds the selected value inside the default closed field.
typedef DropdownSelectedItemBuilder<T> = Widget Function(
  BuildContext context,
  T value,
);

/// Builds a custom search box. Call [onChanged] whenever the text changes.
typedef DropdownSearchBuilder = Widget Function(
  BuildContext context,
  TextEditingController controller,
  ValueChanged<String> onChanged,
);

/// Wraps the panel content, e.g. to add a header or footer.
typedef DropdownPanelBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

/// A searchable dropdown that loads its items page by page.
///
/// * [PaginatedDropdown.offline] paginates a list you already have.
/// * [PaginatedDropdown.online] asks your [PageFetcher] for each page, passing
///   the page number, page size, search text and ready-made query parameters.
class PaginatedDropdown<T> extends StatefulWidget {
  /// Paginates and searches [items] locally.
  ///
  /// By default an item matches when [itemLabel] contains the search text
  /// (case-insensitive). Override with [searchMatcher].
  const PaginatedDropdown.offline({
    super.key,
    required List<T> items,
    required this.itemLabel,
    SearchMatcher<T>? searchMatcher,
    this.value,
    this.onChanged,
    this.itemBuilder,
    this.itemEquals,
    this.pageSize = 20,
    this.decoration,
    this.hintText,
    this.showSearch = true,
    this.showClearButton = false,
    this.enabled = true,
    this.displayMode,
    this.title,
    this.showCloseButton,
    this.autofocusSearch,
    this.barrierDismissible = true,
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.style,
    this.texts,
    this.fieldBuilder,
    this.selectedItemBuilder,
    this.searchBuilder,
    this.panelBuilder,
    this.separatorBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.loadingMoreBuilder,
    this.loadMoreErrorBuilder,
  })  : _items = items, // ignore: prefer_initializing_formals
        _searchMatcher = searchMatcher, // ignore: prefer_initializing_formals
        _fetcher = null,
        firstPageIndex = 0,
        searchDebounce = Duration.zero,
        queryKeys = const PaginationQueryKeys(),
        extraQueryParameters = const {},
        refreshOnOpen = false;

  /// Loads pages from an API through [fetchPage].
  ///
  /// [fetchPage] receives a [PageRequest]; use
  /// [PageRequest.queryParameters] (built from [queryKeys] and
  /// [extraQueryParameters]) for your HTTP call, map the response to your
  /// model and return a [PageResult].
  const PaginatedDropdown.online({
    super.key,
    required PageFetcher<T> fetchPage,
    required this.itemLabel,
    this.firstPageIndex = 1,
    this.searchDebounce = const Duration(milliseconds: 400),
    this.queryKeys = const PaginationQueryKeys(),
    this.extraQueryParameters = const {},
    this.refreshOnOpen = false,
    this.value,
    this.onChanged,
    this.itemBuilder,
    this.itemEquals,
    this.pageSize = 20,
    this.decoration,
    this.hintText,
    this.showSearch = true,
    this.showClearButton = false,
    this.enabled = true,
    this.displayMode,
    this.title,
    this.showCloseButton,
    this.autofocusSearch,
    this.barrierDismissible = true,
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.style,
    this.texts,
    this.fieldBuilder,
    this.selectedItemBuilder,
    this.searchBuilder,
    this.panelBuilder,
    this.separatorBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.loadingMoreBuilder,
    this.loadMoreErrorBuilder,
  })  : _fetcher = fetchPage,
        _items = null,
        _searchMatcher = null;

  final List<T>? _items;
  final SearchMatcher<T>? _searchMatcher;
  final PageFetcher<T>? _fetcher;

  /// Text shown for an item in the field and (by default) in the list.
  final String Function(T item) itemLabel;

  /// Currently selected item.
  final T? value;

  /// Called when the user selects an item, or clears it (with `null`).
  final ValueChanged<T?>? onChanged;

  /// Custom row builder. Defaults to a [ListTile] showing [itemLabel].
  final DropdownItemBuilder<T>? itemBuilder;

  /// Decides whether two items are the same. Online results are new objects
  /// on every fetch, so pass this (e.g. compare ids) unless [T] implements
  /// `==`. Defaults to `==`.
  final bool Function(T a, T b)? itemEquals;

  /// Items per page.
  final int pageSize;

  /// Index of the first page sent to the API. Online only.
  final int firstPageIndex;

  /// Wait time after the last keystroke before searching. Online only.
  final Duration searchDebounce;

  /// Query string key names used to build [PageRequest.queryParameters].
  final PaginationQueryKeys queryKeys;

  /// Static parameters added to every request (filters, sort, etc.).
  final Map<String, String> extraQueryParameters;

  /// Reload from the first page each time the dropdown opens. Online only.
  final bool refreshOnOpen;

  /// Decoration of the closed field. Overrides
  /// [PaginatedDropdownStyle.fieldDecoration].
  final InputDecoration? decoration;

  /// Hint shown when nothing is selected. Falls back to
  /// [InputDecoration.hintText].
  final String? hintText;

  final bool showSearch;

  /// Shows a clear button that resets the selection to `null`.
  final bool showClearButton;

  final bool enabled;

  /// Show the list as a menu, dialog or bottom sheet. Falls back to
  /// [PaginatedDropdownTheme.displayMode], then [DropdownDisplayMode.menu].
  final DropdownDisplayMode? displayMode;

  /// Header title, shown above the search box (e.g. "Requester").
  final String? title;

  /// Close button in the header. Defaults to `true` for dialog and bottom
  /// sheet, `false` for menu.
  final bool? showCloseButton;

  /// Focus the search box (and open the keyboard) when opened. Defaults to
  /// `true` for menu, `false` for dialog and bottom sheet.
  final bool? autofocusSearch;

  /// Close the dialog / bottom sheet when tapping the dimmed background.
  final bool barrierDismissible;

  final FormFieldValidator<T>? validator;
  final FormFieldSetter<T>? onSaved;
  final AutovalidateMode? autovalidateMode;

  /// Colors, text styles, paddings, shapes and icons. Merged over the
  /// [PaginatedDropdownTheme] extension and the defaults.
  final PaginatedDropdownStyle? style;

  /// User-facing strings. Merged over the [PaginatedDropdownTheme] extension
  /// and [PaginatedDropdownTexts.defaults].
  final PaginatedDropdownTexts? texts;

  /// Replaces the whole closed field.
  final DropdownFieldBuilder<T>? fieldBuilder;

  /// Replaces the selected value text inside the default field.
  final DropdownSelectedItemBuilder<T>? selectedItemBuilder;

  /// Replaces the search box.
  final DropdownSearchBuilder? searchBuilder;

  /// Wraps the panel content (search + list).
  final DropdownPanelBuilder? panelBuilder;

  /// Builds the divider between rows. Overrides
  /// [PaginatedDropdownStyle.showItemSeparators].
  final IndexedWidgetBuilder? separatorBuilder;

  /// Shown when there are no items (for the current search).
  final WidgetBuilder? emptyBuilder;

  /// Shown when the first page fails to load.
  final DropdownErrorBuilder? errorBuilder;

  /// Shown while the first page is loading.
  final WidgetBuilder? loadingBuilder;

  /// Shown at the bottom of the list while the next page loads.
  final WidgetBuilder? loadingMoreBuilder;

  /// Shown at the bottom of the list when the next page fails.
  final DropdownErrorBuilder? loadMoreErrorBuilder;

  bool get isOnline => _fetcher != null;

  @override
  State<PaginatedDropdown<T>> createState() => PaginatedDropdownState<T>();
}

/// State of [PaginatedDropdown]. Reach it with a `GlobalKey` to call
/// [refresh], [open] or [close] programmatically.
class PaginatedDropdownState<T> extends State<PaginatedDropdown<T>> {
  final _fieldKey = GlobalKey<FormFieldState<T>>();
  final _targetKey = GlobalKey();
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  final _tapGroup = Object();
  final _scroll = ScrollController();
  final _searchText = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'PaginatedDropdown search');

  late final PaginatedDropdownController<T> _controller;

  bool _modalOpen = false;
  BuildContext? _modalContext;

  bool get isOpen => _portal.isShowing || _modalOpen;

  DropdownDisplayMode _mode(BuildContext context) =>
      widget.displayMode ??
      PaginatedDropdownTheme.of(context)?.displayMode ??
      DropdownDisplayMode.menu;

  PaginatedDropdownStyle _style(BuildContext context) {
    final themeStyle = PaginatedDropdownTheme.of(context)?.style;
    final fontFamily = widget.style?.fontFamily ?? themeStyle?.fontFamily;
    final theme = PaginatedDropdownStyle.applyFontFamily(
      Theme.of(context),
      fontFamily,
    );
    return PaginatedDropdownStyle.defaults(
      theme,
    ).merge(themeStyle).merge(widget.style);
  }

  /// Applies [PaginatedDropdownStyle.fontFamily] to everything below.
  Widget _withFont(BuildContext context, String? fontFamily, Widget child) {
    if (fontFamily == null) return child;
    return Theme(
      data: PaginatedDropdownStyle.applyFontFamily(
        Theme.of(context),
        fontFamily,
      ),
      child: child,
    );
  }

  PaginatedDropdownTexts _texts(BuildContext context) =>
      PaginatedDropdownTexts.defaults
          .merge(PaginatedDropdownTheme.of(context)?.texts)
          .merge(widget.texts);

  @override
  void initState() {
    super.initState();
    _controller = PaginatedDropdownController<T>(
      dataSource: _buildSource(),
      pageSize: widget.pageSize,
      queryKeys: widget.queryKeys,
      extraQueryParameters: widget.extraQueryParameters,
    );
    _controller.addListener(_onControllerChanged);
    _scroll.addListener(_onScroll);
  }

  PaginatedDataSource<T> _buildSource() {
    final w = widget;
    if (w._fetcher != null) {
      return OnlineDataSource<T>(
        fetcher: w._fetcher,
        firstPageIndex: w.firstPageIndex,
        searchDebounce: w.searchDebounce,
      );
    }
    return OfflineDataSource<T>(
      items: w._items!,
      itemLabel: w.itemLabel,
      searchMatcher: w._searchMatcher,
    );
  }

  @override
  void didUpdateWidget(PaginatedDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget;
    // Offline: reload when a different list is passed. Online: swap the
    // fetcher silently, since inline closures change on every parent build.
    // Changing filters (extraQueryParameters), keys, page size or first page
    // index also reloads, so dependent dropdowns never mix old and new pages.
    final offlineChanged =
        !widget.isOnline && !identical(widget._items, old._items);
    _controller.updateDataSource(
      _buildSource(),
      reload: offlineChanged || widget.firstPageIndex != old.firstPageIndex,
    );
    _controller.updateRequestConfig(
      pageSize: widget.pageSize,
      queryKeys: widget.queryKeys,
      extraQueryParameters: widget.extraQueryParameters,
    );

    if (!_same(widget.value, old.value)) {
      final value = widget.value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fieldKey.currentState?.didChange(value);
      });
    }
    if (!widget.enabled && isOpen) close();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _scroll.dispose();
    _searchText.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool _same(T? a, T? b) {
    if (a == null || b == null) return a == null && b == null;
    return widget.itemEquals?.call(a, b) ?? a == b;
  }

  /// Reloads the list from the first page.
  Future<void> refresh() => _controller.refresh();

  /// Opens the dropdown panel.
  void open() {
    if (!widget.enabled || isOpen) return;
    final mode = _mode(context);
    if (mode == DropdownDisplayMode.menu) {
      setState(_portal.show);
    } else {
      _openModal(mode);
    }
    if (widget.refreshOnOpen && _controller.status != PaginationStatus.idle) {
      _controller.refresh();
    } else {
      _controller.ensureLoaded();
    }
  }

  /// Closes the dropdown panel and resets the search.
  void close() {
    if (!isOpen) return;
    // Release focus (and the keyboard) before removing the search box.
    _searchFocus.unfocus();
    if (_modalOpen) {
      final modalContext = _modalContext;
      if (modalContext != null && modalContext.mounted) {
        Navigator.of(modalContext).pop();
      }
      return; // State is reset when the route's future completes.
    }
    setState(_portal.hide);
    _resetSearch();
  }

  void _resetSearch() {
    if (_searchText.text.isNotEmpty) {
      _searchText.clear();
      _controller.search('');
    }
  }

  Future<void> _openModal(DropdownDisplayMode mode) async {
    setState(() => _modalOpen = true);
    final style = _style(context);
    final texts = _texts(context);

    Widget panel(BuildContext modalContext) {
      _modalContext = modalContext;
      return _DropdownPanel<T>(
        controller: _controller,
        scrollController: _scroll,
        searchController: _searchText,
        searchFocusNode: _searchFocus,
        widget: widget,
        mode: mode,
        style: style,
        texts: texts,
        isSelected: (item) => _same(item, _fieldKey.currentState?.value),
        onSelect: _select,
        onClose: close,
      );
    }

    double maxHeight(BuildContext c) =>
        style.dialogMaxHeight ?? MediaQuery.sizeOf(c).height * 0.8;

    if (mode == DropdownDisplayMode.dialog) {
      await showDialog<void>(
        context: context,
        barrierDismissible: widget.barrierDismissible,
        barrierColor: style.barrierColor,
        builder: (c) => Dialog(
          insetPadding: style.dialogInsetPadding,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: style.dialogMaxWidth!,
              maxHeight: maxHeight(c),
            ),
            child: panel(c),
          ),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: widget.barrierDismissible,
        barrierColor: style.barrierColor,
        backgroundColor: Colors.transparent,
        elevation: 0,
        builder: (c) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight(c)),
            child: panel(c),
          ),
        ),
      );
    }

    _modalContext = null;
    if (!mounted) return;
    setState(() => _modalOpen = false);
    _resetSearch();
  }

  void _toggle() => isOpen ? close() : open();

  void _select(T? item) {
    _fieldKey.currentState?.didChange(item);
    widget.onChanged?.call(item);
    close();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 80) {
      _controller.loadMore();
    }
  }

  void _onControllerChanged() {
    // If a page is too short to fill the panel the list cannot scroll, so the
    // scroll listener would never fire. Keep loading until it scrolls.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !isOpen || !_scroll.hasClients) return;
      if (_controller.status == PaginationStatus.loaded &&
          _controller.hasMore &&
          _scroll.position.maxScrollExtent <= 0) {
        _controller.loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: _fieldKey,
      initialValue: widget.value,
      validator: widget.validator,
      onSaved: widget.onSaved,
      autovalidateMode: widget.autovalidateMode,
      enabled: widget.enabled,
      builder: (field) => TapRegion(
        groupId: _tapGroup,
        child: CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _portal,
            overlayChildBuilder: _buildOverlay,
            child: _buildField(field),
          ),
        ),
      ),
    );
  }

  Widget _buildField(FormFieldState<T> field) {
    final value = field.value;
    final hasValue = value != null;

    if (widget.fieldBuilder != null) {
      return GestureDetector(
        key: _targetKey,
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? _toggle : null,
        child: widget.fieldBuilder!(context, value, isOpen, field.errorText),
      );
    }

    final style = _style(context);
    final decoration = widget.decoration ?? style.fieldDecoration!;
    final arrow = isOpen
        ? (style.dropdownIconOpen ?? style.dropdownIcon!)
        : style.dropdownIcon!;

    final suffix = IconTheme.merge(
      data: IconThemeData(color: style.iconColor),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showClearButton && hasValue && widget.enabled)
            IconButton(
              icon: style.clearIcon!,
              color: style.iconColor,
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              visualDensity: VisualDensity.compact,
              onPressed: () => _select(null),
            ),
          Padding(padding: style.dropdownIconPadding!, child: arrow),
        ],
      ),
    );

    return _withFont(
      context,
      style.fontFamily,
      InkWell(
        key: _targetKey,
        onTap: widget.enabled ? _toggle : null,
        borderRadius: _borderRadiusOf(decoration),
        child: InputDecorator(
          isEmpty: !hasValue,
          isFocused: isOpen,
          decoration: decoration
              .applyDefaults(Theme.of(context).inputDecorationTheme)
              .copyWith(
                hintText: widget.hintText ?? decoration.hintText,
                hintStyle: style.hintTextStyle ?? decoration.hintStyle,
                errorText: field.errorText,
                errorStyle: style.errorTextStyle ?? decoration.errorStyle,
                enabled: widget.enabled,
                suffixIcon: decoration.suffixIcon ?? suffix,
                // Let dropdownIconPadding decide the arrow position instead of
                // the default 48dp minimum suffix box.
                suffixIconConstraints: decoration.suffixIconConstraints ??
                    (decoration.suffixIcon == null
                        ? const BoxConstraints(minWidth: 0, minHeight: 0)
                        : null),
              ),
          child: !hasValue
              ? const SizedBox.shrink()
              : widget.selectedItemBuilder?.call(context, value as T) ??
                  Text(
                    widget.itemLabel(value as T),
                    style: style.selectedTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
        ),
      ),
    );
  }

  BorderRadius? _borderRadiusOf(InputDecoration decoration) {
    final border = decoration.border;
    if (border is OutlineInputBorder) return border.borderRadius;
    return null;
  }

  Widget _buildOverlay(BuildContext context) {
    final box = _targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return const SizedBox.shrink();

    final style = _style(context);
    final gap = style.panelGap!;
    final maxPanelHeight = style.maxPanelHeight!;
    const minUsefulHeight = 160.0;
    final media = MediaQuery.of(context);
    final fieldTop = box.localToGlobal(Offset.zero).dy;
    final fieldBottom = fieldTop + box.size.height;
    final spaceBelow = media.size.height -
        media.viewInsets.bottom -
        media.viewPadding.bottom -
        fieldBottom -
        gap * 2;
    final spaceAbove = fieldTop - media.viewPadding.top - gap * 2;
    final openUp = spaceBelow < math.min(maxPanelHeight, minUsefulHeight) &&
        spaceAbove > spaceBelow;
    final maxHeight = math.max(
      0.0,
      math.min(maxPanelHeight, openUp ? spaceAbove : spaceBelow),
    );

    return Positioned(
      left: 0,
      top: 0,
      width: style.panelWidth ?? box.size.width,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: openUp ? Alignment.topLeft : Alignment.bottomLeft,
        followerAnchor: openUp ? Alignment.bottomLeft : Alignment.topLeft,
        offset: Offset(0, openUp ? -gap : gap),
        child: TapRegion(
          groupId: _tapGroup,
          onTapOutside: (_) => close(),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: _DropdownPanel<T>(
              controller: _controller,
              scrollController: _scroll,
              searchController: _searchText,
              searchFocusNode: _searchFocus,
              widget: widget,
              mode: DropdownDisplayMode.menu,
              style: style,
              texts: _texts(context),
              isSelected: (item) => _same(item, _fieldKey.currentState?.value),
              onSelect: _select,
              onClose: close,
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownPanel<T> extends StatelessWidget {
  const _DropdownPanel({
    required this.controller,
    required this.scrollController,
    required this.searchController,
    required this.searchFocusNode,
    required this.widget,
    required this.mode,
    required this.style,
    required this.texts,
    required this.isSelected,
    required this.onSelect,
    required this.onClose,
  });

  final PaginatedDropdownController<T> controller;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final PaginatedDropdown<T> widget;
  final DropdownDisplayMode mode;
  final PaginatedDropdownStyle style;
  final PaginatedDropdownTexts texts;
  final bool Function(T item) isSelected;
  final ValueChanged<T> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final fontFamily = style.fontFamily;
    if (fontFamily == null) return _buildPanel(context);
    return Theme(
      data: PaginatedDropdownStyle.applyFontFamily(
        Theme.of(context),
        fontFamily,
      ),
      child: Builder(builder: _buildPanel),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final isMenu = mode == DropdownDisplayMode.menu;
    final showClose = widget.showCloseButton ?? !isMenu;
    final hasTitleRow = widget.title != null || showClose;
    final search = widget.showSearch
        ? widget.searchBuilder?.call(
              context,
              searchController,
              controller.search,
            ) ??
            _buildSearch(context)
        : null;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasTitleRow)
          Container(
            color: style.headerColor,
            padding: style.headerPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitleRow(context, showClose),
                if (search != null) search,
              ],
            ),
          )
        else if (search != null)
          search,
        if (search != null && style.showSearchDivider!)
          Divider(height: 1, color: style.dividerColor),
        Flexible(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => _buildBody(context),
          ),
        ),
      ],
    );
    content = Padding(padding: style.panelPadding!, child: content);
    if (widget.panelBuilder != null) {
      content = widget.panelBuilder!(context, content);
    }
    content = CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClose},
      child: content,
    );

    final radius = style.panelBorderRadius!;
    final decoration = style.panelDecoration;
    if (decoration != null) {
      return DecoratedBox(
        decoration: decoration.copyWith(
          borderRadius: decoration.borderRadius ?? radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      );
    }
    return Material(
      elevation: style.panelElevation!,
      color: style.panelColor,
      shadowColor: style.panelShadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: style.panelBorder!,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Widget _buildTitleRow(BuildContext context, bool showClose) {
    final close = IconButton(
      icon: style.closeIcon!,
      color: style.closeIconColor,
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      onPressed: onClose,
    );
    return Row(
      children: [
        // Mirror the close button so the title stays centered.
        if (showClose) const SizedBox(width: kMinInteractiveDimension),
        Expanded(
          child: Text(
            widget.title ?? '',
            style: style.titleTextStyle,
            textAlign: showClose ? TextAlign.center : TextAlign.start,
          ),
        ),
        if (showClose) close,
      ],
    );
  }

  Widget _buildSearch(BuildContext context) {
    final decoration = style.searchDecoration!;
    return Padding(
      padding: style.searchPadding!,
      child: TextField(
        controller: searchController,
        focusNode: searchFocusNode,
        autofocus: widget.autofocusSearch ?? mode == DropdownDisplayMode.menu,
        onChanged: controller.search,
        style: style.searchTextStyle,
        cursorColor: style.searchCursorColor,
        textInputAction: TextInputAction.search,
        decoration: decoration.copyWith(
          hintText: decoration.hintText ?? texts.searchHint,
          hintStyle: style.searchHintStyle ?? decoration.hintStyle,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final items = controller.items;
    switch (controller.status) {
      case PaginationStatus.idle:
      case PaginationStatus.loadingFirstPage:
        return widget.loadingBuilder?.call(context) ??
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: style.loadingIndicatorColor,
                ),
              ),
            );
      case PaginationStatus.firstPageError:
        return widget.errorBuilder?.call(
              context,
              controller.error!,
              controller.retry,
            ) ??
            _ErrorView(style: style, texts: texts, onRetry: controller.retry);
      case PaginationStatus.loaded ||
              PaginationStatus.loadingMore ||
              PaginationStatus.loadMoreError
          when items.isEmpty:
        return widget.emptyBuilder?.call(context) ??
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(texts.noItems!, style: style.messageTextStyle),
              ),
            );
      case PaginationStatus.loaded:
      case PaginationStatus.loadingMore:
      case PaginationStatus.loadMoreError:
        final showFooter = controller.status != PaginationStatus.loaded;
        return ListView.separated(
          controller: scrollController,
          shrinkWrap: true,
          padding: style.listPadding,
          itemCount: items.length + (showFooter ? 1 : 0),
          separatorBuilder: (context, index) {
            if (index >= items.length - 1) return const SizedBox.shrink();
            if (widget.separatorBuilder != null) {
              return widget.separatorBuilder!(context, index);
            }
            if (!style.showItemSeparators!) return const SizedBox.shrink();
            return Divider(
              height: 1,
              color: style.separatorColor,
              indent: style.separatorIndent,
              endIndent: style.separatorIndent,
            );
          },
          itemBuilder: (context, index) {
            if (index == items.length) return _buildFooter(context);
            final item = items[index];
            final selected = isSelected(item);
            final custom = widget.itemBuilder?.call(context, item, selected);
            final row = Material(
              color: custom != null
                  ? Colors.transparent
                  : selected
                      ? style.selectedItemBackgroundColor
                      : style.itemBackgroundColor,
              borderRadius: custom != null ? null : style.itemBorderRadius,
              clipBehavior: custom != null ? Clip.none : Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelect(item),
                hoverColor: style.itemHoverColor,
                splashColor: style.itemSplashColor,
                highlightColor: style.itemSplashColor,
                child: custom ?? _buildDefaultItem(item, selected),
              ),
            );
            return custom != null
                ? row
                : Padding(padding: style.itemMargin!, child: row);
          },
        );
    }
  }

  Widget _buildDefaultItem(T item, bool selected) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: style.itemMinHeight!),
      child: Padding(
        padding: style.itemPadding!,
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.itemLabel(item),
                style: selected
                    ? style.selectedItemTextStyle
                    : style.itemTextStyle,
              ),
            ),
            if (selected && style.showSelectedItemIcon!)
              style.selectedItemIcon!,
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (controller.status == PaginationStatus.loadMoreError) {
      return widget.loadMoreErrorBuilder?.call(
            context,
            controller.error!,
            controller.retry,
          ) ??
          Padding(
            padding: style.itemPadding!,
            child: Row(
              children: [
                Icon(Icons.error_outline, color: style.errorIconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    texts.loadMoreError!,
                    style: style.messageTextStyle,
                  ),
                ),
                TextButton(
                  onPressed: controller.retry,
                  style: style.retryButtonStyle,
                  child: Text(texts.retry!),
                ),
              ],
            ),
          );
    }
    return widget.loadingMoreBuilder?.call(context) ??
        Padding(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: style.loadingIndicatorColor,
              ),
            ),
          ),
        );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.style,
    required this.texts,
    required this.onRetry,
  });

  final PaginatedDropdownStyle style;
  final PaginatedDropdownTexts texts;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: style.errorIconColor),
          const SizedBox(height: 8),
          Text(
            texts.error!,
            style: style.messageTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: onRetry,
            style: style.retryButtonStyle,
            child: Text(texts.retry!),
          ),
        ],
      ),
    );
  }
}

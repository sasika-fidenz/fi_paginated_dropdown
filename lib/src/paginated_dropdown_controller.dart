import 'dart:async';

import 'package:flutter/foundation.dart';

import 'data_source.dart';
import 'page_models.dart';

/// Loading state of a [PaginatedDropdownController].
enum PaginationStatus {
  /// Nothing loaded yet.
  idle,

  /// Loading the first page (of a new search or refresh).
  loadingFirstPage,

  /// Loading a following page; existing items stay visible.
  loadingMore,

  /// Last request succeeded.
  loaded,

  /// The first page failed. No items are available.
  firstPageError,

  /// A following page failed. Already loaded items stay visible.
  loadMoreError,
}

/// Holds the items, search text and paging state for a dropdown.
///
/// Stale responses (e.g. page 1 of an older search arriving after the user
/// typed again) are discarded using a generation counter.
class PaginatedDropdownController<T> extends ChangeNotifier {
  PaginatedDropdownController({
    required PaginatedDataSource<T> dataSource,
    int pageSize = 20,
    PaginationQueryKeys queryKeys = const PaginationQueryKeys(),
    Map<String, String> extraQueryParameters = const {},
  })  : assert(pageSize > 0),
        _pageSize = pageSize,
        _queryKeys = queryKeys,
        _extraQueryParameters = extraQueryParameters,
        _dataSource = dataSource,
        _nextPage = dataSource.firstPageIndex;

  int _pageSize;
  int get pageSize => _pageSize;

  PaginationQueryKeys _queryKeys;
  PaginationQueryKeys get queryKeys => _queryKeys;

  Map<String, String> _extraQueryParameters;
  Map<String, String> get extraQueryParameters => _extraQueryParameters;

  PaginatedDataSource<T> _dataSource;
  PaginatedDataSource<T> get dataSource => _dataSource;

  final List<T> _items = [];
  List<T> get items => List.unmodifiable(_items);

  PaginationStatus _status = PaginationStatus.idle;
  PaginationStatus get status => _status;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  Object? _error;
  Object? get error => _error;

  String _searchText = '';
  String get searchText => _searchText;

  int? _totalCount;

  /// Total items reported by the data source for the current search, if any.
  int? get totalCount => _totalCount;

  int _nextPage;
  int _generation = 0;
  Timer? _debounce;
  bool _disposed = false;

  bool get isLoading =>
      _status == PaginationStatus.loadingFirstPage ||
      _status == PaginationStatus.loadingMore;

  /// Replaces the data source. When [reload] is true and something was
  /// already loaded, the list is reloaded from the first page.
  void updateDataSource(
    PaginatedDataSource<T> dataSource, {
    bool reload = true,
  }) {
    _dataSource = dataSource;
    if (reload && _status != PaginationStatus.idle) refresh();
  }

  /// Changes request settings. If any value differs and something was
  /// already loaded, the list is reloaded from the first page so pages from
  /// different filters are never mixed.
  void updateRequestConfig({
    int? pageSize,
    PaginationQueryKeys? queryKeys,
    Map<String, String>? extraQueryParameters,
  }) {
    var changed = false;
    if (pageSize != null && pageSize != _pageSize) {
      _pageSize = pageSize;
      changed = true;
    }
    if (queryKeys != null && queryKeys != _queryKeys) {
      _queryKeys = queryKeys;
      changed = true;
    }
    if (extraQueryParameters != null &&
        !mapEquals(extraQueryParameters, _extraQueryParameters)) {
      _extraQueryParameters = extraQueryParameters;
      changed = true;
    }
    if (changed && _status != PaginationStatus.idle) refresh();
  }

  /// Loads the first page if nothing has been loaded yet.
  Future<void> ensureLoaded() async {
    if (_status == PaginationStatus.idle) await refresh();
  }

  /// Clears everything and loads the first page for the current search.
  Future<void> refresh() {
    _debounce?.cancel();
    _generation++;
    _items.clear();
    _nextPage = _dataSource.firstPageIndex;
    _hasMore = true;
    _totalCount = null;
    _error = null;
    return _load(firstPage: true);
  }

  /// Loads the next page. Ignored while loading, when no more pages exist,
  /// or after an error (use [retry] to resume).
  Future<void> loadMore() async {
    if (isLoading ||
        !_hasMore ||
        _status == PaginationStatus.firstPageError ||
        _status == PaginationStatus.loadMoreError) {
      return;
    }
    if (_status == PaginationStatus.idle) return refresh();
    await _load(firstPage: false);
  }

  /// Retries whichever request failed last.
  Future<void> retry() async {
    if (_status == PaginationStatus.loadMoreError) {
      await _load(firstPage: false);
    } else {
      await refresh();
    }
  }

  /// Updates the search text. Online sources are debounced.
  void search(String text) {
    final query = text.trim();
    if (query == _searchText) return;
    _searchText = query;
    _debounce?.cancel();
    final delay = _dataSource.searchDebounce;
    if (delay == Duration.zero) {
      refresh();
    } else {
      _debounce = Timer(delay, refresh);
    }
  }

  Future<void> _load({required bool firstPage}) async {
    final generation = _generation;
    _status = firstPage
        ? PaginationStatus.loadingFirstPage
        : PaginationStatus.loadingMore;
    _error = null;
    _notify();

    final request = PageRequest(
      page: _nextPage,
      pageSize: pageSize,
      searchText: _searchText,
      queryKeys: queryKeys,
      extraQueryParameters: extraQueryParameters,
    );

    try {
      final result = await _dataSource.fetchPage(request);
      if (_disposed || generation != _generation) return;
      _items.addAll(result.items);
      _totalCount = result.totalCount ?? _totalCount;
      _hasMore = result.items.isNotEmpty &&
          result.resolveHasMore(
            pageSize: _pageSize,
            loadedCount: _items.length,
          );
      _nextPage++;
      _status = PaginationStatus.loaded;
    } catch (e) {
      if (_disposed || generation != _generation) return;
      _error = e;
      _status = firstPage
          ? PaginationStatus.firstPageError
          : PaginationStatus.loadMoreError;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}

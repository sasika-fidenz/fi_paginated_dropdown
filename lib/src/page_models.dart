/// Names of the query string keys sent to an online API.
///
/// APIs differ (`page`/`limit`/`search` vs `pageNo`/`size`/`q`), so every key
/// is configurable. Set [searchKey] to `null` to never send the search text.
class PaginationQueryKeys {
  const PaginationQueryKeys({
    this.pageKey = 'page',
    this.pageSizeKey = 'limit',
    this.searchKey = 'search',
  });

  final String pageKey;
  final String pageSizeKey;
  final String? searchKey;

  @override
  bool operator ==(Object other) =>
      other is PaginationQueryKeys &&
      other.pageKey == pageKey &&
      other.pageSizeKey == pageSizeKey &&
      other.searchKey == searchKey;

  @override
  int get hashCode => Object.hash(pageKey, pageSizeKey, searchKey);
}

/// Describes the page the dropdown wants to load.
class PageRequest {
  const PageRequest({
    required this.page,
    required this.pageSize,
    this.searchText = '',
    this.queryKeys = const PaginationQueryKeys(),
    this.extraQueryParameters = const {},
  });

  /// Page number, starting at the configured first page index.
  final int page;

  /// Number of items requested per page.
  final int pageSize;

  /// Current (trimmed) search text. Empty when the user has not searched.
  final String searchText;

  final PaginationQueryKeys queryKeys;

  /// Static query parameters merged into [queryParameters] (e.g. filters).
  final Map<String, String> extraQueryParameters;

  /// Zero-based offset of the first item on this page, relative to
  /// [firstPageIndex]. Handy for `offset`/`skip` style APIs.
  int offset({int firstPageIndex = 0}) => (page - firstPageIndex) * pageSize;

  /// Ready-to-use query string parameters for this request, e.g.
  /// `{'page': '1', 'limit': '20', 'search': 'foo', ...extra}`.
  ///
  /// The search key is omitted when [searchText] is empty.
  Map<String, String> get queryParameters => {
        ...extraQueryParameters,
        queryKeys.pageKey: '$page',
        queryKeys.pageSizeKey: '$pageSize',
        if (queryKeys.searchKey != null && searchText.isNotEmpty)
          queryKeys.searchKey!: searchText,
      };

  @override
  String toString() =>
      'PageRequest(page: $page, pageSize: $pageSize, search: "$searchText")';
}

/// One page of results returned by a data source.
class PageResult<T> {
  const PageResult({required this.items, this.hasMore, this.totalCount});

  final List<T> items;

  /// Whether more pages exist. When `null`, it is derived from [totalCount]
  /// if given, otherwise from `items.length < pageSize`.
  final bool? hasMore;

  /// Total number of items across all pages, if the API reports it.
  final int? totalCount;

  /// Resolves [hasMore] using the fallbacks described above.
  bool resolveHasMore({required int pageSize, required int loadedCount}) {
    if (hasMore != null) return hasMore!;
    if (totalCount != null) return loadedCount < totalCount!;
    return items.length >= pageSize;
  }
}

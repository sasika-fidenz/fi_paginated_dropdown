import 'page_models.dart';

/// Loads a single page of items.
///
/// Users of the online mode provide one of these. Call your API with
/// [PageRequest.queryParameters], parse the response into your own model and
/// return a [PageResult].
typedef PageFetcher<T> = Future<PageResult<T>> Function(PageRequest request);

/// Returns true when [item] matches the search [query].
typedef SearchMatcher<T> = bool Function(T item, String query);

/// Source of paginated data for a [PaginatedDropdownController].
abstract class PaginatedDataSource<T> {
  const PaginatedDataSource();

  /// Fetches one page.
  Future<PageResult<T>> fetchPage(PageRequest request);

  /// Index of the first page (0 or 1 for most APIs).
  int get firstPageIndex;

  /// Delay applied before a search is sent. Zero means search immediately.
  Duration get searchDebounce;
}

/// Paginates and searches an in-memory list.
class OfflineDataSource<T> extends PaginatedDataSource<T> {
  OfflineDataSource({
    required List<T> items,
    required String Function(T item) itemLabel,
    SearchMatcher<T>? searchMatcher,
  })  : _items = List.unmodifiable(items),
        _matcher = searchMatcher ??
            ((item, query) =>
                itemLabel(item).toLowerCase().contains(query.toLowerCase()));

  final List<T> _items;
  final SearchMatcher<T> _matcher;

  List<T> get items => _items;

  @override
  int get firstPageIndex => 0;

  @override
  Duration get searchDebounce => Duration.zero;

  @override
  Future<PageResult<T>> fetchPage(PageRequest request) async {
    final query = request.searchText;
    final filtered = query.isEmpty
        ? _items
        : _items.where((i) => _matcher(i, query)).toList();
    final start = request.offset(firstPageIndex: firstPageIndex);
    if (start >= filtered.length) {
      return PageResult(
        items: const [],
        hasMore: false,
        totalCount: filtered.length,
      );
    }
    final end = (start + request.pageSize).clamp(0, filtered.length);
    return PageResult(
      items: filtered.sublist(start, end),
      hasMore: end < filtered.length,
      totalCount: filtered.length,
    );
  }
}

/// Loads pages from a user-supplied [PageFetcher] (usually an API call).
class OnlineDataSource<T> extends PaginatedDataSource<T> {
  const OnlineDataSource({
    required this.fetcher,
    this.firstPageIndex = 1,
    this.searchDebounce = const Duration(milliseconds: 400),
  });

  final PageFetcher<T> fetcher;

  @override
  final int firstPageIndex;

  @override
  final Duration searchDebounce;

  @override
  Future<PageResult<T>> fetchPage(PageRequest request) => fetcher(request);
}

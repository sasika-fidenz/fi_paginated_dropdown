import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fi_paginated_dropdown/fi_paginated_dropdown.dart';

void main() {
  group('PageRequest', () {
    test('builds query parameters with custom keys and extras', () {
      const request = PageRequest(
        page: 2,
        pageSize: 10,
        searchText: 'abc',
        queryKeys: PaginationQueryKeys(
          pageKey: 'pageNo',
          pageSizeKey: 'size',
          searchKey: 'q',
        ),
        extraQueryParameters: {'sort': 'name'},
      );
      expect(request.queryParameters, {
        'sort': 'name',
        'pageNo': '2',
        'size': '10',
        'q': 'abc',
      });
      expect(request.offset(firstPageIndex: 1), 10);
    });

    test('omits search key when search is empty', () {
      const request = PageRequest(page: 1, pageSize: 10);
      expect(request.queryParameters.containsKey('search'), isFalse);
    });
  });

  group('offline', () {
    PaginatedDropdownController<String> build() =>
        PaginatedDropdownController<String>(
          pageSize: 10,
          dataSource: OfflineDataSource(
            items: List.generate(25, (i) => 'Item $i'),
            itemLabel: (s) => s,
          ),
        );

    test('paginates the list', () async {
      final c = build();
      await c.refresh();
      expect(c.items.length, 10);
      expect(c.hasMore, isTrue);
      await c.loadMore();
      await c.loadMore();
      expect(c.items.length, 25);
      expect(c.hasMore, isFalse);
      await c.loadMore();
      expect(c.items.length, 25);
    });

    test('search filters and resets paging', () async {
      final c = build();
      await c.refresh();
      await c.loadMore();
      c.search('item 1');
      await pumpEventQueue();
      // Item 1, Item 10..19
      expect(c.items.length, 10);
      expect(c.items.first, 'Item 1');
      expect(c.hasMore, isTrue);
      await c.loadMore();
      expect(c.items.length, 11);
      expect(c.hasMore, isFalse);
    });
  });

  group('online', () {
    test('sends pages starting at firstPageIndex and infers end', () async {
      final requests = <PageRequest>[];
      final c = PaginatedDropdownController<int>(
        pageSize: 5,
        dataSource: OnlineDataSource(
          fetcher: (r) async {
            requests.add(r);
            final start = r.offset(firstPageIndex: 1);
            final count = (12 - start).clamp(0, r.pageSize);
            return PageResult(items: List.generate(count, (i) => start + i));
          },
        ),
      );
      await c.refresh();
      await c.loadMore();
      await c.loadMore();
      expect(requests.map((r) => r.page), [1, 2, 3]);
      expect(c.items.length, 12);
      expect(c.hasMore, isFalse);
    });

    test('drops stale responses from an older search', () async {
      final pending = <String, Completer<PageResult<String>>>{};
      final c = PaginatedDropdownController<String>(
        dataSource: OnlineDataSource(
          searchDebounce: Duration.zero,
          fetcher: (r) {
            final completer = Completer<PageResult<String>>();
            pending[r.searchText] = completer;
            return completer.future;
          },
        ),
      );

      unawaited(c.refresh());
      c.search('new');
      pending['new']!.complete(
        const PageResult(items: ['new result'], hasMore: false),
      );
      await pumpEventQueue();
      pending['']!.complete(
        const PageResult(items: ['stale result'], hasMore: false),
      );
      await pumpEventQueue();

      expect(c.items, ['new result']);
      expect(c.status, PaginationStatus.loaded);
    });

    test('debounces search', () {
      fakeAsync((async) {
        final searches = <String>[];
        final c = PaginatedDropdownController<String>(
          dataSource: OnlineDataSource(
            searchDebounce: const Duration(milliseconds: 300),
            fetcher: (r) async {
              searches.add(r.searchText);
              return const PageResult(items: []);
            },
          ),
        );
        c.search('a');
        async.elapse(const Duration(milliseconds: 100));
        c.search('ab');
        async.elapse(const Duration(milliseconds: 100));
        c.search('abc');
        async.elapse(const Duration(milliseconds: 400));
        expect(searches, ['abc']);
      });
    });

    test('reports first-page and load-more errors separately', () async {
      var failNext = true;
      final c = PaginatedDropdownController<int>(
        pageSize: 2,
        dataSource: OnlineDataSource(
          fetcher: (r) async {
            if (failNext) throw Exception('boom');
            return PageResult(items: [r.page, r.page]);
          },
        ),
      );
      await c.refresh();
      expect(c.status, PaginationStatus.firstPageError);

      failNext = false;
      await c.retry();
      expect(c.items, [1, 1]);

      failNext = true;
      await c.loadMore();
      expect(c.status, PaginationStatus.loadMoreError);
      expect(c.items, [1, 1]);

      // Scrolling after a failure must not retry on its own.
      failNext = false;
      await c.loadMore();
      expect(c.status, PaginationStatus.loadMoreError);
      expect(c.items, [1, 1]);

      await c.retry();
      expect(c.items, [1, 1, 2, 2]);
    });

    test('ignores loadMore while a request is in flight', () async {
      var calls = 0;
      final gate = Completer<void>();
      final c = PaginatedDropdownController<int>(
        pageSize: 1,
        dataSource: OnlineDataSource(
          fetcher: (r) async {
            calls++;
            if (r.page == 2) await gate.future;
            return PageResult(items: [r.page]);
          },
        ),
      );
      await c.refresh();
      unawaited(c.loadMore());
      unawaited(c.loadMore());
      unawaited(c.loadMore());
      gate.complete();
      await pumpEventQueue();
      expect(calls, 2);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fi_paginated_dropdown/fi_paginated_dropdown.dart';

class User {
  User(this.id, this.name);
  final int id;
  final String name;
}

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );

void main() {
  testWidgets('offline: opens, searches, selects', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<String>.offline(
          items: List.generate(100, (i) => 'Item $i'),
          itemLabel: (s) => s,
          pageSize: 10,
          hintText: 'Pick one',
          onChanged: (v) => selected = v,
        ),
      ),
    );

    expect(find.text('Pick one'), findsOneWidget);
    await tester.tap(find.byType(InputDecorator).first);
    await tester.pumpAndSettle();
    expect(find.text('Item 0'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'item 42');
    await tester.pumpAndSettle();
    expect(find.text('Item 42'), findsOneWidget);
    expect(find.text('Item 0'), findsNothing);

    await tester.tap(find.text('Item 42'));
    await tester.pumpAndSettle();
    expect(selected, 'Item 42');
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Item 42'), findsOneWidget);
  });

  testWidgets('offline: scrolling loads more pages', (tester) async {
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<String>.offline(
          items: List.generate(100, (i) => 'Item $i'),
          itemLabel: (s) => s,
          pageSize: 20,
          hintText: 'Pick one',
        ),
      ),
    );
    await tester.tap(find.byType(InputDecorator).first);
    await tester.pumpAndSettle();
    expect(find.text('Item 25'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Item 25'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Item 25'), findsOneWidget);
  });

  testWidgets('online: short first page auto-loads next page', (tester) async {
    final pages = <int>[];
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<User>.online(
          pageSize: 2,
          itemLabel: (u) => u.name,
          itemEquals: (a, b) => a.id == b.id,
          hintText: 'User',
          fetchPage: (r) async {
            pages.add(r.page);
            await Future<void>.delayed(const Duration(milliseconds: 10));
            final start = r.offset(firstPageIndex: 1);
            return PageResult(
              items: [
                for (var i = start; i < start + 2; i++) User(i, 'User $i'),
              ],
              totalCount: 6,
            );
          },
        ),
      ),
    );
    await tester.tap(find.byType(InputDecorator).first);
    await tester.pumpAndSettle();
    // Two items don't fill the panel, so pages keep loading until done.
    expect(pages, [1, 2, 3]);
    expect(find.text('User 5'), findsOneWidget);
  });

  testWidgets('online: shows error and retries', (tester) async {
    var fail = true;
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<String>.online(
          itemLabel: (s) => s,
          hintText: 'Pick',
          fetchPage: (r) async {
            if (fail) throw Exception('network');
            return const PageResult(items: ['Remote'], hasMore: false);
          },
        ),
      ),
    );
    await tester.tap(find.byType(InputDecorator).first);
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Remote'), findsOneWidget);
  });

  testWidgets('validator and clear button', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      _app(
        Form(
          key: formKey,
          child: PaginatedDropdown<String>.offline(
            items: const ['A', 'B'],
            itemLabel: (s) => s,
            value: 'A',
            showClearButton: true,
            validator: (v) => v == null ? 'Required' : null,
          ),
        ),
      ),
    );
    expect(formKey.currentState!.validate(), isTrue);
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('tapping outside closes the panel', (tester) async {
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            PaginatedDropdown<String>.offline(
              items: const ['A', 'B'],
              itemLabel: (s) => s,
              hintText: 'Pick',
            ),
            const SizedBox(height: 400),
            const Text('outside'),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(InputDecorator).first);
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    await tester.tapAt(const Offset(700, 580));
    await tester.pumpAndSettle();
    expect(find.text('B'), findsNothing);
  });

  testWidgets('dependent dropdown reloads when filters change', (tester) async {
    final requests = <PageRequest>[];
    await tester.pumpWidget(_app(_Cascade(requests: requests)));
    expect(find.text('Old city'), findsOneWidget);

    await tester.tap(find.byType(InputDecorator).first);
    await tester.pumpAndSettle();
    expect(find.text('City 1-a'), findsOneWidget);

    await tester.tap(find.text('Switch country'));
    await tester.pumpAndSettle();
    // Parent cleared the value.
    expect(find.text('Old city'), findsNothing);
    // Old items are gone and the new request carries the new filter.
    expect(find.text('City 1-a'), findsNothing);
    expect(requests.last.queryParameters['country'], '2');

    await tester.tap(find.byType(InputDecorator).first);
    await tester.pumpAndSettle();
    expect(find.text('City 2-a'), findsOneWidget);
    expect(find.text('City 1-a'), findsNothing);
  });
}

class _Cascade extends StatefulWidget {
  const _Cascade({required this.requests});
  final List<PageRequest> requests;
  @override
  State<_Cascade> createState() => _CascadeState();
}

class _CascadeState extends State<_Cascade> {
  String country = '1';
  String? city = 'Old city';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => setState(() {
            country = '2';
            city = null;
          }),
          child: const Text('Switch country'),
        ),
        PaginatedDropdown<String>.online(
          itemLabel: (s) => s,
          value: city,
          hintText: 'City',
          extraQueryParameters: {'country': country},
          fetchPage: (r) async {
            widget.requests.add(r);
            final c = r.queryParameters['country'];
            return PageResult(
              items: ['City $c-a', 'City $c-b'],
              hasMore: false,
            );
          },
        ),
      ],
    );
  }
}

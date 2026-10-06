import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fi_paginated_dropdown/fi_paginated_dropdown.dart';

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );

void main() {
  testWidgets('dialog: title, search, select closes and sets value', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<String>.offline(
          items: List.generate(50, (i) => 'Person $i'),
          itemLabel: (s) => s,
          displayMode: DropdownDisplayMode.dialog,
          title: 'Requester',
          hintText: 'Pick',
          onChanged: (v) => selected = v,
        ),
      ),
    );
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Requester'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    // Dialog mode does not autofocus the search box by default.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofocus, isFalse);

    await tester.enterText(find.byType(TextField), 'person 42');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Person 42'));
    await tester.pumpAndSettle();

    expect(selected, 'Person 42');
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Person 42'), findsOneWidget);

    // Search was reset: reopening shows the full list again.
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    expect(find.text('Person 0'), findsOneWidget);
  });

  testWidgets('dialog: close button and barrier close it', (tester) async {
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<String>.offline(
          items: const ['A', 'B'],
          itemLabel: (s) => s,
          displayMode: DropdownDisplayMode.dialog,
          title: 'Pick one',
        ),
      ),
    );
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    // Still opens again after being dismissed.
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('bottom sheet: online paging and selection', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<String>.online(
          pageSize: 3,
          itemLabel: (s) => s,
          displayMode: DropdownDisplayMode.bottomSheet,
          title: 'Users',
          onChanged: (v) => selected = v,
          fetchPage: (r) async => PageResult(
            items: [for (var i = 0; i < 3; i++) 'User ${r.page}-$i'],
            hasMore: r.page < 2,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
    // Short first page auto-loads the next one.
    expect(find.text('User 2-2'), findsOneWidget);

    await tester.tap(find.text('User 2-1'));
    await tester.pumpAndSettle();
    expect(selected, 'User 2-1');
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('card rows use itemMargin and itemBorderRadius', (tester) async {
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<String>.offline(
          items: const ['A'],
          itemLabel: (s) => s,
          displayMode: DropdownDisplayMode.dialog,
          style: PaginatedDropdownStyle(
            itemMargin: const EdgeInsets.all(12),
            itemBorderRadius: BorderRadius.circular(20),
            itemBackgroundColor: Colors.purple.shade50,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    final card = tester.widget<Material>(
      find.ancestor(of: find.text('A'), matching: find.byType(Material)).first,
    );
    expect(card.borderRadius, BorderRadius.circular(20));
    expect(card.color, Colors.purple.shade50);
    final margin = tester.widget<Padding>(
      find
          .ancestor(of: find.byWidget(card), matching: find.byType(Padding))
          .first,
    );
    expect(margin.padding, const EdgeInsets.all(12));
  });

  testWidgets('theme displayMode applies app-wide; widget overrides it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [
            PaginatedDropdownTheme(displayMode: DropdownDisplayMode.dialog),
          ],
        ),
        home: Scaffold(
          body: Column(
            children: [
              PaginatedDropdown<String>.offline(
                items: const ['A'],
                itemLabel: (s) => s,
                hintText: 'Themed',
              ),
              PaginatedDropdown<String>.offline(
                items: const ['B'],
                itemLabel: (s) => s,
                hintText: 'Menu',
                displayMode: DropdownDisplayMode.menu,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Themed'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });
}

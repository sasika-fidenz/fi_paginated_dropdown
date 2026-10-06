import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fi_paginated_dropdown/fi_paginated_dropdown.dart';

Widget _app(Widget child,
        {List<ThemeExtension<dynamic>> extensions = const []}) =>
    MaterialApp(
      theme: ThemeData(extensions: extensions),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(PaginatedDropdown<String>));
  await tester.pumpAndSettle();
}

Material _panelMaterial(WidgetTester tester) => tester.widget<Material>(
      find
          .ancestor(of: find.byType(ListView), matching: find.byType(Material))
          .first,
    );

void main() {
  test('merge: later non-null values win, nulls keep earlier values', () {
    const base = PaginatedDropdownStyle(panelColor: Colors.red, panelGap: 2);
    final merged = base.merge(const PaginatedDropdownStyle(panelGap: 10));
    expect(merged.panelColor, Colors.red);
    expect(merged.panelGap, 10);
  });

  testWidgets('theme extension styles the panel, widget style wins', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<String>.offline(
          items: const ['A', 'B'],
          itemLabel: (s) => s,
          style: const PaginatedDropdownStyle(panelElevation: 2),
        ),
        extensions: const [
          PaginatedDropdownTheme(
            style: PaginatedDropdownStyle(
              panelColor: Colors.amber,
              panelElevation: 20,
            ),
          ),
        ],
      ),
    );
    await _open(tester);
    final material = _panelMaterial(tester);
    expect(material.color, Colors.amber);
    expect(material.elevation, 2);
  });

  testWidgets('item and selected item text styles', (tester) async {
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<String>.offline(
          items: const ['A', 'B'],
          itemLabel: (s) => s,
          value: 'A',
          style: const PaginatedDropdownStyle(
            itemTextStyle: TextStyle(fontSize: 11),
            selectedItemTextStyle: TextStyle(fontSize: 22),
            selectedItemIcon: Icon(Icons.star),
          ),
        ),
      ),
    );
    await _open(tester);
    expect(tester.widget<Text>(find.text('B')).style!.fontSize, 11);
    expect(tester.widget<Text>(find.text('A').last).style!.fontSize, 22);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('texts are customisable', (tester) async {
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<String>.offline(
          items: const ['A'],
          itemLabel: (s) => s,
          texts: const PaginatedDropdownTexts(
            searchHint: 'Find...',
            noItems: 'Nothing here',
          ),
        ),
      ),
    );
    await _open(tester);
    expect(find.text('Find...'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('fieldBuilder, searchBuilder and panelBuilder', (tester) async {
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<String>.offline(
          items: const ['Apple', 'Banana'],
          itemLabel: (s) => s,
          fieldBuilder: (context, value, isOpen, error) =>
              Text('FIELD ${value ?? '-'} ${isOpen ? 'open' : 'closed'}'),
          searchBuilder: (context, controller, onChanged) => TextField(
            key: const Key('my-search'),
            controller: controller,
            onChanged: onChanged,
          ),
          panelBuilder: (context, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [const Text('HEADER'), Flexible(child: child)],
          ),
        ),
      ),
    );
    expect(find.text('FIELD - closed'), findsOneWidget);
    await _open(tester);
    expect(find.text('FIELD - open'), findsOneWidget);
    expect(find.text('HEADER'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('my-search')), 'ban');
    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsNothing);
    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();
    expect(find.text('FIELD Banana closed'), findsOneWidget);
  });
}

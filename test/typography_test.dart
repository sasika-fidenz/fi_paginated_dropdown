import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fi_paginated_dropdown/fi_paginated_dropdown.dart';

Widget _app(Widget child) => MaterialApp(
      home: Scaffold(
        body: Form(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );

/// Effective style of the RichText that renders [text].
TextStyle _rendered(WidgetTester tester, String text) {
  final rich = tester.widget<RichText>(
    find
        .byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText() == text,
        )
        .first,
  );
  final span = rich.text as TextSpan;
  final style = span.style ?? const TextStyle();
  final child = span.children?.isNotEmpty == true
      ? (span.children!.first as TextSpan).style
      : null;
  return style.merge(child);
}

void main() {
  testWidgets('fontFamily applies to field, title, search hint and rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<String>.offline(
          items: const ['Alpha', 'Beta'],
          itemLabel: (s) => s,
          hintText: 'Pick',
          title: 'Title',
          displayMode: DropdownDisplayMode.dialog,
          style: const PaginatedDropdownStyle(
            fontFamily: 'MyFont',
            itemTextStyle: TextStyle(fontSize: 19),
          ),
        ),
      ),
    );
    expect(_rendered(tester, 'Pick').fontFamily, 'MyFont');

    await tester.tap(find.byType(InputDecorator).first);
    await tester.pumpAndSettle();
    expect(_rendered(tester, 'Title').fontFamily, 'MyFont');
    expect(_rendered(tester, 'Search...').fontFamily, 'MyFont');
    final row = _rendered(tester, 'Alpha');
    expect(row.fontFamily, 'MyFont');
    expect(row.fontSize, 19);

    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(_rendered(tester, 'Beta').fontFamily, 'MyFont');
  });

  testWidgets('a family on an individual style wins over fontFamily', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PaginatedDropdown<String>.offline(
          items: const ['Alpha'],
          itemLabel: (s) => s,
          hintText: 'Pick',
          style: const PaginatedDropdownStyle(
            fontFamily: 'MyFont',
            itemTextStyle: TextStyle(fontFamily: 'Other'),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(InputDecorator).first);
    await tester.pumpAndSettle();
    expect(_rendered(tester, 'Alpha').fontFamily, 'Other');
  });

  testWidgets('hint, search hint and error text styles', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PaginatedDropdown<String>.offline(
              items: const ['A'],
              itemLabel: (s) => s,
              hintText: 'Pick',
              validator: (v) => v == null ? 'Required' : null,
              style: const PaginatedDropdownStyle(
                hintTextStyle: TextStyle(fontSize: 21),
                searchHintStyle: TextStyle(fontSize: 13),
                errorTextStyle: TextStyle(fontSize: 11),
              ),
            ),
          ),
        ),
      ),
    );
    expect(_rendered(tester, 'Pick').fontSize, 21);
    formKey.currentState!.validate();
    await tester.pump();
    expect(_rendered(tester, 'Required').fontSize, 11);

    await tester.tap(find.byType(InputDecorator).first);
    await tester.pumpAndSettle();
    expect(_rendered(tester, 'Search...').fontSize, 13);
  });
}

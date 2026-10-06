import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fi_paginated_dropdown/fi_paginated_dropdown.dart';

void main() => runApp(const ExampleApp());

const _navy = Color(0xFF197B60);
const _cardColor = Color(0xFFF5F4FA);
const _selectedCardColor = Color(0xFFE6E3F4);

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paginated Search Dropdown',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: _navy,
        fontFamily: GoogleFonts.montserrat().fontFamily,
        // Every PaginatedDropdown in the app opens as the "Requester" dialog
        // and uses the same field / dialog styling.
        extensions: [
          PaginatedDropdownTheme(
            displayMode: DropdownDisplayMode.dialog,
            style: requesterStyle,
            texts: const PaginatedDropdownTexts(searchHint: 'Search'),
          ),
        ],
      ),
      home: const WorkOrderPage(),
    );
  }
}

/// Recreates the "Requester" modal: navy header with centered title, close
/// button and a lavender pill search box; white body with rounded card rows.
/// The closed field is a rounded lavender box with a chevron.
/// Measurements are in dp, taken from a 360dp-wide phone design.
final requesterStyle = PaginatedDropdownStyle(
  // Typography: one font for every text; change size/color per text below.
  // google_fonts registers each weight as its own family, so bold texts use
  // GoogleFonts.montserrat(fontWeight: ...). With a font bundled in
  // pubspec.yaml, `fontFamily: 'Montserrat'` + plain TextStyles is enough.
  fontFamily: GoogleFonts.montserrat().fontFamily,
  hintTextStyle: const TextStyle(color: Colors.black45, fontSize: 15),
  errorTextStyle: const TextStyle(fontSize: 12),
  searchHintStyle: const TextStyle(
    color: _navy,
    fontSize: 16,
    letterSpacing: 1,
  ),

  // Closed field
  fieldDecoration: InputDecoration(
    filled: true,
    fillColor: _cardColor,
    // Text 28dp from the left edge (the outline border adds ~4dp itself).
    contentPadding: const EdgeInsets.fromLTRB(21, 18, 20, 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  ),
  selectedTextStyle: GoogleFonts.montserrat(
    color: _navy,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  ),
  dropdownIcon: const Icon(Icons.keyboard_arrow_down, size: 28),
  dropdownIconOpen: const Icon(Icons.keyboard_arrow_down, size: 28),
  // Chevron centered 27dp from the right edge.
  dropdownIconPadding: const EdgeInsetsDirectional.only(end: 13),
  clearIcon: const Icon(Icons.close, size: 20),
  iconColor: _navy,

  // Dialog: 290dp wide on a 360dp screen, 18dp corners, white bottom margin
  // below the scrolling list.
  panelColor: Colors.white,
  panelElevation: 0,
  panelBorderRadius: BorderRadius.circular(18),
  panelPadding: const EdgeInsets.only(bottom: 16),
  dialogInsetPadding: const EdgeInsets.symmetric(horizontal: 35, vertical: 120),
  barrierColor: Colors.black54,

  // Header: title centered 25dp from the top, search 18dp from both sides,
  // 26dp of navy below the search box. Left/right padding must be equal so
  // the title is centered in the dialog.
  headerColor: _navy,
  headerPadding: const EdgeInsets.fromLTRB(10, 1, 10, 26),
  titleTextStyle: GoogleFonts.montserrat(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  ),
  closeIcon: const Icon(Icons.close, size: 30),
  closeIconColor: Colors.white,

  // Search: 45dp tall lavender pill, navy magnifier on the right.
  searchPadding: const EdgeInsets.symmetric(horizontal: 8),
  searchTextStyle: const TextStyle(color: _navy, fontSize: 16),
  searchCursorColor: _navy,
  searchDecoration: InputDecoration(
    filled: true,
    fillColor: _cardColor,
    suffixIcon: const Padding(
      padding: EdgeInsetsDirectional.only(end: 2),
      child: Icon(Icons.search, color: _navy, size: 30),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
  ),
  showSearchDivider: false,

  // Rows: 54dp tall cards, 12dp side margin, 21dp gap, 18dp corners.
  listPadding: const EdgeInsets.symmetric(vertical: 9),
  itemMargin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10.5),
  itemBorderRadius: BorderRadius.circular(18),
  itemPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  itemMinHeight: 54,
  itemBackgroundColor: _cardColor,
  selectedItemBackgroundColor: _selectedCardColor,
  itemHoverColor: _navy.withValues(alpha: 0.04),
  itemSplashColor: _navy.withValues(alpha: 0.08),
  itemTextStyle: GoogleFonts.montserrat(
    color: _navy,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
  selectedItemTextStyle: GoogleFonts.montserrat(
    color: _navy,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  ),
  selectedItemIcon: const Icon(Icons.check_circle, color: _navy),
  loadingIndicatorColor: _navy,
  messageTextStyle: const TextStyle(color: _navy, fontSize: 14),
);

/// Response model the "API" returns.
class Person {
  const Person({required this.id, required this.name});

  factory Person.fromJson(Map<String, dynamic> json) =>
      Person(id: json['id'] as int, name: json['name'] as String);

  final int id;
  final String name;
}

/// Pretends to be a backend: `GET /requesters?page=1&limit=20&search=foo`.
class FakePeopleApi {
  static const _names = [
    'Test PN Req',
    'Alan Lim',
    'Mike Danguilan',
    'asd',
    'asd',
    'Wei Kang',
  ];

  static final _all = [
    for (var i = 0; i < 120; i++)
      {
        'id': i + 1,
        'name': i < _names.length ? _names[i] : 'Requester ${i + 1}',
      },
  ];

  Future<Map<String, dynamic>> get(Map<String, String> query) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final page = int.parse(query['page']!);
    final limit = int.parse(query['limit']!);
    final search = (query['search'] ?? '').toLowerCase();
    final filtered = _all
        .where((p) => (p['name'] as String).toLowerCase().contains(search))
        .toList();
    final start = (page - 1) * limit;
    final data = filtered.sublist(
      min(start, filtered.length),
      min(start + limit, filtered.length),
    );
    return {'data': data, 'total': filtered.length};
  }
}

class WorkOrderPage extends StatefulWidget {
  const WorkOrderPage({super.key});

  @override
  State<WorkOrderPage> createState() => _WorkOrderPageState();
}

class _WorkOrderPageState extends State<WorkOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = FakePeopleApi();
  final _priorities = const ['Low', 'Medium', 'High', 'Critical'];
  final _locations = List.generate(300, (i) => 'Location ${i + 1}');

  Person? _requester;
  String? _priority;
  String? _location;

  /// Online mode: call the API with the ready-made query parameters and map
  /// the JSON into the response model.
  Future<PageResult<Person>> _fetchRequesters(PageRequest request) async {
    // With dio:  dio.get('/requesters', queryParameters: request.queryParameters)
    // With http: http.get(Uri.https(host, '/requesters', request.queryParameters))
    final json = await _api.get(request.queryParameters);
    final items = (json['data'] as List)
        .map((e) => Person.fromJson(e as Map<String, dynamic>))
        .toList();
    return PageResult(items: items, totalCount: json['total'] as int);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Todo List'),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const _Label('DropDown 1'),
              PaginatedDropdown<Person>.online(
                fetchPage: _fetchRequesters,
                itemLabel: (p) => p.name,
                itemEquals: (a, b) => a.id == b.id,
                value: _requester,
                title: 'DropDown 1',
                hintText: '-',
                validator: (v) =>
                    v == null ? 'Please select a requester' : null,
                onChanged: (v) => setState(() => _requester = v),
              ),
              const SizedBox(height: 20),
              const _Label('DropDown 2'),
              PaginatedDropdown<String>.offline(
                items: _priorities,
                itemLabel: (s) => s,
                value: _priority,
                title: 'DropDown 2',
                hintText: '-',
                showSearch: false,
                onChanged: (v) => setState(() => _priority = v),
              ),
              const SizedBox(height: 20),
              const _Label('DropDown 3'),
              PaginatedDropdown<String>.offline(
                items: _locations,
                itemLabel: (s) => s,
                value: _location,
                title: 'DropDown 3',
                hintText: '-',
                pageSize: 25,
                showClearButton: true,
                onChanged: (v) => setState(() => _location = v),
              ),
              const SizedBox(height: 32),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${_requester?.name} / ${_priority ?? '-'} / '
                          '${_location ?? '-'}',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: _navy,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

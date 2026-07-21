import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('renders the grocery page', (WidgetTester tester) async {
    await tester.pumpWidget(const GroceryApp());

    expect(find.text('GROCERY'), findsOneWidget);
    expect(find.text('Search Items'), findsOneWidget);
    expect(find.textContaining('AYAM BERSIH'), findsOneWidget);
    expect(find.text('Favourites'), findsOneWidget);
  });
}

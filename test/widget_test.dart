import 'package:flutter_test/flutter_test.dart';

import 'package:animated_icon_picker/main.dart';

void main() {
  testWidgets('home screen shows the picker entry row', (tester) async {
    await tester.pumpWidget(const AnimatedIconPickerApp());

    expect(find.text('App Icon Picker'), findsOneWidget);
    expect(find.text('Change App Icon'), findsOneWidget);
  });
}

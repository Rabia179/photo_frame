import 'package:flutter_test/flutter_test.dart';
import 'package:photo_frame/main.dart';

void main() {
  testWidgets('PhotoFrame app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PhotoFrameApp());

    expect(find.byType(PhotoFrameApp), findsOneWidget);
  });
}
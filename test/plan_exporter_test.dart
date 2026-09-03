import 'package:flutter_test/flutter_test.dart';
import 'package:iter/features/chat_first_prototype/chat_first_data.dart';
import 'package:iter/features/chat_first_prototype/plan_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlanExporter', () {
    final fixture = ChatFirstDemoData.operationalFixtureFor('porto');
    final snapshot = fixture.snapshot;

    test('toFormattedText generates complete readable itinerary', () {
      final text = PlanExporter.toFormattedText(snapshot);

      expect(text, contains('Viaggio a Porto'));
      expect(text, contains('giorni'));
      expect(text, contains('Livraria Lello'));
      expect(text, contains('Creato con Iter'));
    });

    test('toIcs generates standard RFC 5545 valid content', () {
      final ics = PlanExporter.toIcs(snapshot);

      expect(ics, startsWith('BEGIN:VCALENDAR'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('PRODID:-//Iter Travel//Iter App//IT'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('SUMMARY:Livraria Lello'));
      expect(ics, contains('LOCATION:Porto'));
      expect(ics, endsWith('END:VCALENDAR\n'));
    });
  });
}

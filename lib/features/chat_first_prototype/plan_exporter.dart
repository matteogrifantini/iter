import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'plan_models.dart';

/// Formats and exports a [TripSnapshot] into plain text or iCalendar (.ics) format.
class PlanExporter {
  const PlanExporter._();

  /// Formats the trip snapshot into a human-readable text itinerary suitable
  /// for messaging, notes, or email.
  static String toFormattedText(TripSnapshot snapshot) {
    final buffer = StringBuffer();
    final dest = snapshot.destinationTitle;
    buffer.writeln('📍 Viaggio a $dest');
    if (snapshot.days.isNotEmpty) {
      buffer.writeln('🗓️ ${snapshot.days.length} giorni');
    }
    buffer.writeln();

    for (var d = 0; d < snapshot.days.length; d++) {
      final day = snapshot.days[d];
      buffer.writeln(
        '🗓️ ${day.label}${day.theme.isNotEmpty ? ' · ${day.theme}' : ''}',
      );
      if (day.items.isEmpty) {
        buffer.writeln('  (Nessuna tappa programmata)');
      } else {
        for (final item in day.items) {
          final time = item.startTime.isNotEmpty ? '${item.startTime} — ' : '';
          final category = item.category.isNotEmpty
              ? ' (${item.category})'
              : '';
          final locked = item.locked ? ' 🔒' : '';
          buffer.writeln('  • $time${item.title}$category$locked');
        }
      }
      buffer.writeln();
    }

    if (snapshot.travelSelection case final travel?) {
      final isPurchased =
          travel.option.purchaseState == PurchaseState.purchased;
      final status = isPurchased ? 'Confermato' : 'Selezionato';
      buffer.writeln('✈️ Viaggio: ${travel.option.label} ($status)');
    } else if (snapshot.transport.isNotEmpty &&
        snapshot.transport != 'da definire') {
      buffer.writeln('✈️ Viaggio: ${snapshot.transport}');
    }

    if (snapshot.staySelection case final stay?) {
      final isPurchased = stay.option.purchaseState == PurchaseState.purchased;
      final status = isPurchased ? 'Confermato' : 'Selezionato';
      buffer.writeln('🏨 Soggiorno: ${stay.option.label} ($status)');
    } else if (snapshot.stay.isNotEmpty && snapshot.stay != 'da definire') {
      buffer.writeln('🏨 Soggiorno: ${snapshot.stay}');
    }

    buffer.writeln();
    buffer.writeln('✨ Creato con Iter (itertravel.app)');
    return buffer.toString().trim();
  }

  /// Generates a standard RFC 5545 iCalendar (.ics) representation of the trip.
  static String toIcs(TripSnapshot snapshot, {DateTime? startDate}) {
    final start = startDate ?? DateTime.now().add(const Duration(days: 7));
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Iter Travel//Iter App//IT');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:Viaggio a ${snapshot.destinationTitle}');

    for (var d = 0; d < snapshot.days.length; d++) {
      final day = snapshot.days[d];
      final dayDate = start.add(Duration(days: d));

      for (var i = 0; i < day.items.length; i++) {
        final item = day.items[i];
        final timeParts = _parseTimeParts(
          item.startTime,
          fallbackHour: 9 + (i * 2),
        );
        final eventStart = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          timeParts.hour,
          timeParts.minute,
        );
        final eventEnd = eventStart.add(
          Duration(
            minutes: item.durationMinutes > 0 ? item.durationMinutes : 90,
          ),
        );

        final dtStart = _formatIcsDate(eventStart);
        final dtEnd = _formatIcsDate(eventEnd);
        final uid =
            '${snapshot.destinationTitle}-${day.id}-${item.id}@itertravel.app';

        buffer.writeln('BEGIN:VEVENT');
        buffer.writeln('UID:$uid');
        buffer.writeln('DTSTAMP:${_formatIcsDate(DateTime.now().toUtc())}');
        buffer.writeln('DTSTART:$dtStart');
        buffer.writeln('DTEND:$dtEnd');
        buffer.writeln('SUMMARY:${_escapeIcs(item.title)}');
        buffer.writeln(
          'DESCRIPTION:${_escapeIcs('${day.label} a ${snapshot.destinationTitle} · Categoria: ${item.category}')}',
        );
        buffer.writeln('LOCATION:${_escapeIcs(snapshot.destinationTitle)}');
        buffer.writeln('STATUS:CONFIRMED');
        buffer.writeln('END:VEVENT');
      }
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  /// Copies text to clipboard and displays a feedback SnackBar.
  static void copyToClipboard(
    BuildContext context, {
    required String text,
    required String message,
  }) {
    Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
  }

  static ({int hour, int minute}) _parseTimeParts(
    String time, {
    required int fallbackHour,
  }) {
    if (time.contains(':')) {
      final parts = time.split(':');
      final h = int.tryParse(parts[0].trim());
      final m = int.tryParse(parts.length > 1 ? parts[1].trim() : '0');
      if (h != null && m != null) {
        return (hour: h.clamp(0, 23), minute: m.clamp(0, 59));
      }
    }
    return (hour: fallbackHour.clamp(0, 23), minute: 0);
  }

  static String _formatIcsDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min$s';
  }

  static String _escapeIcs(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\n', '\\n');
  }
}

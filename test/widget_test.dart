import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shipmonitoring/core/utils/date_formatter.dart';
import 'package:shipmonitoring/core/utils/file_validator.dart';
import 'package:shipmonitoring/core/widgets/status_badge.dart';

void main() {
  testWidgets('StatusBadge renders backend status label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBadge(status: 'PENDING')),
      ),
    );

    expect(find.text('Menunggu Verifikasi'), findsOneWidget);
  });

  group('FileValidator', () {
    test('accepts valid PDF under max size', () {
      final result = FileValidator.validatePdf(
        fileName: 'surat.pdf',
        sizeBytes: 128 * 1024,
        mimeType: 'application/pdf',
      );

      expect(result, isNull);
    });

    test('rejects non PDF mime type', () {
      final result = FileValidator.validatePdf(
        fileName: 'surat.pdf',
        sizeBytes: 128 * 1024,
        mimeType: 'image/png',
      );

      expect(result, 'Tipe dokumen harus PDF.');
    });

    test('rejects file above max size', () {
      final result = FileValidator.validatePdf(
        fileName: 'surat.pdf',
        sizeBytes: FileValidator.maxPdfSizeBytes + 1,
      );

      expect(result, 'Ukuran dokumen maksimal 4 MB.');
    });
  });

  test('DateFormatter keeps UI stable for ISO date values', () {
    final result = DateFormatter.formatDateTime('2026-07-03T09:30:00Z');

    expect(result, isNot('-'));
  });
}

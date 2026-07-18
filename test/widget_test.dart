import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shipmonitoring/core/utils/date_formatter.dart';
import 'package:shipmonitoring/core/utils/file_validator.dart';
import 'package:shipmonitoring/core/utils/public_file_url.dart';
import 'package:shipmonitoring/core/widgets/status_badge.dart';
import 'package:shipmonitoring/features/auth/domain/user_session.dart';
import 'package:shipmonitoring/features/dashboard/presentation/dashboard_widgets.dart';

void main() {
  testWidgets('StatusBadge renders backend status label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBadge(status: 'PENDING')),
      ),
    );

    expect(find.text('Menunggu Verifikasi'), findsOneWidget);
  });

  testWidgets('RoleScaffold header stays within a narrow mobile viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(180, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RoleScaffold(
            visual: RoleVisual.nahkoda,
            session: UserSession(
              id: 'captain-1',
              name: 'Nama Nakhoda Sangat Panjang',
              role: UserRole.nahkoda,
              token: 'test-token',
            ),
            currentIndex: 0,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                label: 'Riwayat',
              ),
            ],
            children: [SizedBox.shrink()],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Logout'), findsOneWidget);
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

  group('PublicFileUrl', () {
    const apiBaseUrl = 'http://43.133.134.10/api/';

    test('rewrites backend localhost document URL to the VPS origin', () {
      final result = PublicFileUrl.resolve(
        'http://localhost:3131/uploads/document.pdf',
        apiBaseUrl: apiBaseUrl,
      );

      expect(result, 'http://43.133.134.10/uploads/document.pdf');
    });

    test('resolves a relative upload path against the VPS origin', () {
      final result = PublicFileUrl.resolve(
        '/uploads/document.pdf',
        apiBaseUrl: apiBaseUrl,
      );

      expect(result, 'http://43.133.134.10/uploads/document.pdf');
    });

    test('keeps an external document URL unchanged', () {
      final result = PublicFileUrl.resolve(
        'https://cdn.example.test/document.pdf',
        apiBaseUrl: apiBaseUrl,
      );

      expect(result, 'https://cdn.example.test/document.pdf');
    });
  });
}

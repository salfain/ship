class FileValidator {
  static const maxPdfSizeBytes = 4 * 1024 * 1024;
  static const _allowedPdfMimeTypes = {'application/pdf', 'application/x-pdf'};

  static String? validatePdf({
    required String fileName,
    required int sizeBytes,
    String? mimeType,
  }) {
    final normalizedName = fileName.trim().toLowerCase();
    final normalizedMime = mimeType?.split(';').first.trim().toLowerCase();

    if (normalizedName.isEmpty || !normalizedName.endsWith('.pdf')) {
      return 'Dokumen harus berupa file PDF.';
    }
    if (normalizedMime != null &&
        normalizedMime.isNotEmpty &&
        !_allowedPdfMimeTypes.contains(normalizedMime)) {
      return 'Tipe dokumen harus PDF.';
    }
    if (sizeBytes <= 0) {
      return 'Dokumen kosong atau tidak bisa dibaca.';
    }
    if (sizeBytes > maxPdfSizeBytes) {
      return 'Ukuran dokumen maksimal 4 MB.';
    }
    return null;
  }

  static String formatSize(int sizeBytes) {
    if (sizeBytes <= 0) return '0 KB';
    final kiloBytes = sizeBytes / 1024;
    if (kiloBytes < 1024) {
      return '${kiloBytes.ceil()} KB';
    }
    final megaBytes = kiloBytes / 1024;
    return '${megaBytes.toStringAsFixed(1)} MB';
  }
}

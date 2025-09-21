// lib/services/ocr_service.dart
import 'dart:io';
import 'package:intl/intl.dart';

/// Example OCR wrapper. You may use either:
///  - google_mlkit_text_recognition (recommended)
///  - tesseract_ocr package
///
/// Below is a minimal interface and a simple expiry-date parser.
/// Implement actual OCR call in the TODO section depending on the package you choose.

class OCRService {
  /// Extract text from imagePath and parse expiry date + medicine name heuristically.
  static Future<Map<String, dynamic>> extractExpiryFromImage(String imagePath) async {
    // 1) Run OCR (platform-specific)
    final rawText = await _runOCR(imagePath);

    // 2) Heuristic parsing for expiry date (common formats: MM/YYYY, MM-YYYY, DD/MM/YYYY, YYYY-MM-DD)
    DateTime? expiry;
    final lower = rawText.toLowerCase();

    // common patterns
    final regexes = [
      RegExp(r'(\d{1,2}[/\-]\d{4})'), // MM/YYYY or M/YYYY or MM-YYYY
      RegExp(r'(\d{2}[/\-]\d{2}[/\-]\d{4})'), // DD/MM/YYYY
      RegExp(r'(\d{4}[/\-]\d{2}[/\-]\d{2})'), // YYYY-MM-DD
      RegExp(r'exp(?:iry|):?\s*(\d{1,2}[/\-]\d{4})'),
      RegExp(r'best before[: ]+(\d{1,2}[/\-]\d{4})'),
    ];

    for (final r in regexes) {
      final m = r.firstMatch(lower);
      if (m != null) {
        final s = m.group(1)!.replaceAll('-', '/');
        expiry = _parseDateFlexible(s);
        if (expiry != null) break;
      }
    }

    // 3) Try to guess medicine name: look for capitalized words in original rawText
    final medName = _extractLikelyMedicineName(rawText);

    return {
      'rawText': rawText,
      'medicineName': medName ?? '',
      'expiryDate': expiry?.toIso8601String(),
      'expiryParsed': expiry != null,
    };
  }

  static Future<String> _runOCR(String imagePath) async {
    // TODO: Replace this stub with real OCR using google_mlkit_text_recognition or tesseract_ocr
    // Example for google_mlkit_text_recognition:
    // final inputImage = InputImage.fromFilePath(imagePath);
    // final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    // final result = await recognizer.processImage(inputImage);
    // return result.text;

    // Fallback: read debug text file next to image if available; otherwise return empty
    try {
      final file = File(imagePath);
      if (await file.exists() && file.path.endsWith('.txt')) {
        return await file.readAsString();
      }
    } catch (_) {}
    // For now return a placeholder to allow parsing flows to continue
    return 'Paracetamol\nEXP 11/2025\nBatch: ABC123';
  }

  static DateTime? _parseDateFlexible(String s) {
    try {
      // handle MM/YYYY or M/YYYY
      final parts = s.split('/');
      if (parts.length == 2 && parts[1].length == 4) {
        final mm = int.parse(parts[0]);
        final yyyy = int.parse(parts[1]);
        return DateTime(yyyy, mm, 1);
      }
      // handle DD/MM/YYYY
      if (parts.length == 3) {
        final dd = int.parse(parts[0]);
        final mm = int.parse(parts[1]);
        final yyyy = int.parse(parts[2]);
        return DateTime(yyyy, mm, dd);
      }
      // handle YYYY-MM-DD
      if (s.contains('-')) {
        final p = s.split('-');
        if (p.length == 3) return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      }
    } catch (_) {}
    return null;
  }

  static String? _extractLikelyMedicineName(String rawText) {
    // naive heuristic: find first line with letters and capitalized start
    final lines = rawText.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (lines.isEmpty) return null;
    // prefer a line with alphabets and length between 3 and 30
    for (final l in lines) {
      if (RegExp(r'^[A-Za-z0-9 \-()]{3,40}$').hasMatch(l) && !l.toLowerCase().contains('exp')) {
        return l;
      }
    }
    return lines.first;
  }
}

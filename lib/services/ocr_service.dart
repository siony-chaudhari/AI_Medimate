import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  // Existing basic OCR method (returns full text)
  Future<String> extractTextFromImage(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final RecognizedText recognizedText =
      await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print('OCR Error: $e');
      return 'Error: $e';
    }
  }

  Future<List<String>> extractMedicinesFromImage(File image) async {
    final rawText = await extractTextFromImage(image);
    final lines = rawText.split('\n');
    final medicines = <String>[];

    // 1️⃣ Ignore all common non-medicine fields
    final ignorePattern = RegExp(
      r'(dr\.|doctor|hospital|clinic|address|date|age|name|prescription|diagnosis|rx|ref|signature|before food|after food|morning|evening|night|tablet count|qty|quantity|phone|mobile|take|tablets|capsules|use|directions|dose|1-0-1|0-1-0|ml|days|times)',
      caseSensitive: false,
    );

    // 2️⃣ Identify likely medicine-like lines (short, alphanumeric, optional mg/ml)
    final medicinePattern = RegExp(
      r'^[A-Za-z][A-Za-z0-9\- ]*(\s?\d{1,3}(mg|ml|mcg|g|iu|units)?)?$',
      caseSensitive: false,
    );

    // 3️⃣ Optional medicine hint words to catch brand types (e.g., syrup, tab, cap)
    const whitelistHints = [
      'tab', 'cap', 'syrup', 'ointment', 'drops', 'injection',
      'gel', 'cream', 'suspension', 'solution', 'tablet', 'capsule', 'inhaler'
    ];

    for (var line in lines) {
      var clean = line.trim();

      // Skip short, empty, or irrelevant lines early
      if (clean.isEmpty || clean.length < 3 || ignorePattern.hasMatch(clean)) continue;

      // Remove punctuation & extra symbols
      clean = clean.replaceAll(RegExp(r'[:;,]'), '').trim();

      // Skip long descriptive/instruction lines
      if (clean.split(' ').length > 5) continue;

      // Match medicine-like lines or those with medical hints
      if (medicinePattern.hasMatch(clean) ||
          whitelistHints.any((hint) => clean.toLowerCase().contains(hint))) {
        medicines.add(clean);
      }
    }

    // Final cleanup: remove duplicates, trim, and filter noise
    final unique = medicines
        .map((e) => e.replaceAll(RegExp(r'[^A-Za-z0-9\s\-]'), '').trim())
        .where((e) => e.length > 3)
        .toSet()
        .toList();

    return unique;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

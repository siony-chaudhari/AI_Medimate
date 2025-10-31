import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<Map<String, dynamic>> extractMedicinesFromImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    String text = recognizedText.text;
    print("🔍 Raw OCR Text:\n$text\n");

    // Clean up text
    text = text
        .replaceAll(RegExp(r'[\t\r]+'), ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    // Extract doctor, hospital, and date
    final doctorRegex = RegExp(r'(Dr\.?\s*[A-Z][a-zA-Z\s]*)');
    final hospitalRegex = RegExp(r'([A-Z][A-Za-z\s]*(Hospital|Clinic|Medical|Nursing|Health)[A-Za-z\s]*)');
    final dateRegex = RegExp(r'(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})');

    final doctor = doctorRegex.firstMatch(text)?.group(0) ?? "Not found";
    final hospital = hospitalRegex.firstMatch(text)?.group(0) ?? "Not found";
    final date = dateRegex.firstMatch(text)?.group(0) ?? "Not found";

    // Keep only medicine-related lines
    final medicineSection = text
        .split('\n')
        .where((line) =>
    line.trim().isNotEmpty &&
        !RegExp(r'(name|age|sex|rx|dr\.|doctor|hospital|address|signature)',
            caseSensitive: false)
            .hasMatch(line))
        .toList()
        .join('\n');

    // Improved medicine regex
    final medicineRegex = RegExp(
      r'([A-Z][A-Z0-9\-]+)\s+(\d+\s?(mg|ml|g|tab|caps)?)\s*([A-Z0-9]+)?\s*(\d+[dD])?',
      caseSensitive: false,
    );

    final medicines = <Map<String, String>>[];
    final seen = <String>{};

    for (final match in medicineRegex.allMatches(medicineSection)) {
      final name = match.group(1)?.trim() ?? '';
      final dosage = match.group(2)?.trim() ?? '';
      final frequency = match.group(4)?.trim() ?? '';
      final duration = match.group(5)?.trim() ?? 'Not specified';

      if (name.isEmpty || seen.contains(name.toLowerCase())) continue;
      seen.add(name.toLowerCase());

      medicines.add({
        "Medicine": name,
        "Dosage": [dosage, frequency].where((e) => e.isNotEmpty).join(' '),
        "Duration": duration,
      });
    }

    if (medicines.isEmpty) {
      print("⚠️ No structured medicines found — check OCR quality.");
    }

    return {
      "Doctor": doctor,
      "Hospital": hospital,
      "Date": date,
      "Medicines": medicines,
    };
  }

  void dispose() {
    _textRecognizer.close();
  }
}
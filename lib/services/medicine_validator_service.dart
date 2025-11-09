// import 'dart:convert';
// import 'package:flutter/services.dart';
//
// class MedicineValidatorService {
//   static final MedicineValidatorService _instance =
//   MedicineValidatorService._internal();
//   factory MedicineValidatorService() => _instance;
//   MedicineValidatorService._internal();
//
//   Set<String> _medicineNames = {};
//   Set<String> _medicineKeywords = {};
//   bool _isInitialized = false;
//
//   /// Initialize the service by loading the medicine dataset
//   Future<void> initialize() async {
//     if (_isInitialized) return;
//
//     try {
//       print("🔄 Loading medicine dataset...");
//       final csvData = await rootBundle
//           .loadString('assets/dataset/A_Z_medicines_dataset_of_India.csv');
//       await _parseMedicineDataset(csvData);
//       _isInitialized = true;
//       print("✅ Medicine dataset loaded: ${_medicineNames.length} medicines");
//     } catch (e) {
//       print("❌ Error loading medicine dataset: $e");
//     }
//   }
//
//   /// Parse the CSV dataset and extract medicine names and keywords
//   Future<void> _parseMedicineDataset(String csvData) async {
//     final lines = csvData.split('\n');
//     print("📊 Processing ${lines.length} lines from CSV");
//
//     // Skip header row
//     for (int i = 1; i < lines.length; i++) {
//       final line = lines[i].trim();
//       if (line.isEmpty) continue;
//
//       try {
//         final columns = _parseCSVLine(line);
//         if (columns.length >= 2) {
//           final medicineName = columns[1].trim(); // name column
//
//           if (medicineName.isNotEmpty && medicineName != 'name') {
//             _medicineNames.add(medicineName.toLowerCase());
//             _extractMedicineKeywords(medicineName);
//
//             // Debug: Print first few medicines
//             if (_medicineNames.length <= 5) {
//               print("📋 Added medicine: $medicineName");
//             }
//           }
//         }
//       } catch (e) {
//         continue; // skip malformed lines
//       }
//     }
//
//     print("📊 Total medicines loaded: ${_medicineNames.length}");
//     print("📊 Total keywords extracted: ${_medicineKeywords.length}");
//
//     // Check if common medicines are in the dataset
//     final testMedicines = ['paracetamol', 'cimetidine', 'aspirin', 'amoxicillin'];
//     for (final test in testMedicines) {
//       final found = _medicineNames.any((med) => med.contains(test));
//       print("🧪 Test medicine '$test': ${found ? 'FOUND' : 'NOT FOUND'}");
//     }
//   }
//
//   /// Parse CSV line handling quoted fields safely
//   List<String> _parseCSVLine(String line) {
//     try {
//       final List<String> result = [];
//       bool inQuotes = false;
//       String currentField = '';
//
//       for (int i = 0; i < line.length; i++) {
//         final char = line[i];
//         if (char == '"') {
//           inQuotes = !inQuotes;
//         } else if (char == ',' && !inQuotes) {
//           result.add(currentField.trim());
//           currentField = '';
//         } else {
//           currentField += char;
//         }
//       }
//
//       // Add the last field
//       result.add(currentField.trim());
//
//       // Ensure we have at least 2 columns (id, name)
//       while (result.length < 2) {
//         result.add('');
//       }
//
//       return result;
//     } catch (e) {
//       print("❌ Error parsing CSV line: $e");
//       return ['', '']; // Return empty fields to avoid index errors
//     }
//   }
//
//   /// Extract keywords from medicine names for better matching
//   void _extractMedicineKeywords(String medicineName) {
//     final parts = medicineName
//         .replaceAll(
//         RegExp(
//             r'[0-9]+\s?(mg|ml|g|mcg|tab|tablet|syrup|cream|injection)',
//             caseSensitive: false),
//         '')
//         .split(RegExp(r'[\s\-\+]+'))
//         .where((part) => part.length >= 3)
//         .toList();
//
//     for (final part in parts) {
//       _medicineKeywords.add(part.toLowerCase());
//     }
//   }
//
//   /// ✅ Check if text is likely to be a medicine name
//   bool isMedicineName(String text) {
//     if (!_isInitialized || text.trim().isEmpty) {
//       print("🔍 Validation failed: not initialized or empty text");
//       return false;
//     }
//
//     final cleanText = text.toLowerCase().trim();
//     print("🔍 Checking medicine: '$cleanText'");
//
//     // Direct match in medicine names
//     if (_medicineNames.contains(cleanText)) {
//       print("✅ Direct match found for: $cleanText");
//       return true;
//     }
//
//     // Check for partial matches with known medicines
//     for (final medicine in _medicineNames) {
//       if (medicine.contains(cleanText) || cleanText.contains(medicine)) {
//         if (medicine.length >= 4 && cleanText.length >= 4) {
//           print("✅ Partial match found: '$cleanText' matches '$medicine'");
//           return true;
//         }
//       }
//     }
//
//     // Check keywords
//     final textWords = cleanText.split(RegExp(r'[\s\-\+]+'));
//     int matchCount = 0;
//
//     for (final word in textWords) {
//       if (word.length >= 3 && _medicineKeywords.contains(word)) {
//         matchCount++;
//         print("🔍 Keyword match: '$word'");
//       }
//     }
//
//     final isValid = matchCount > 0 && (matchCount / textWords.length) >= 0.3; // Lowered threshold
//     print("🔍 Keyword validation for '$cleanText': $matchCount/${textWords.length} matches = $isValid");
//
//     return isValid;
//   }
//
//   /// ✅ Filter only valid medicine names
//   List<String> filterMedicineNames(List<String> extractedTexts) {
//     if (!_isInitialized) return extractedTexts;
//
//     return extractedTexts.where((text) {
//       if (_isCommonNonMedicine(text)) return false;
//       return isMedicineName(text);
//     }).toList();
//   }
//
//   /// Common non-medicine patterns
//   bool _isCommonNonMedicine(String text) {
//     final lowerText = text.toLowerCase().trim();
//
//     // Specific non-medicine words from the OCR
//     final nonMedicineWords = {
//       'jola', 'smitl', 'address_', 'exsmple', 'tebs', 'riverside', 'medical',
//       'center', 'centre', 'street', 'york', 'usa', 'olabel', 'refill', 'prn',
//       'signature', 'sign', 'name', 'age', 'date', 'doctor', 'hospital', 'clinic',
//       'address', 'phone', 'email', 'prescription', 'morning', 'evening', 'night',
//       'daily', 'weekly', 'monthly', 'steve', 'josson'
//     };
//
//     // Check if it's a known non-medicine word
//     if (nonMedicineWords.contains(lowerText)) {
//       print("❌ Blocked non-medicine word: $lowerText");
//       return true;
//     }
//
//     try {
//       final nonMedicinePatterns = [
//         RegExp(r'^(dr|doctor|mr|mrs|ms)\.?\s', caseSensitive: false),
//         RegExp(r'\b(age|years?|yrs?)\b', caseSensitive: false),
//         RegExp(r'\b(male|female|m|f)\b', caseSensitive: false),
//         RegExp(r'\b(hospital|clinic|medical|center|centre)\b', caseSensitive: false),
//         RegExp(r'\b(address|phone|tel|email)\b', caseSensitive: false),
//         RegExp(r'\b(prescription|rx|date|time)\b', caseSensitive: false),
//         RegExp(r'^\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}'),
//         RegExp(r'^\d+'),
//         RegExp(r'\b(signature|sign|stamp|seal)\b', caseSensitive: false),
//         RegExp(r'\b(morning|evening|night|daily|weekly)\b', caseSensitive: false),
//       ];
//
//       final isNonMedicine = nonMedicinePatterns.any((pattern) => pattern.hasMatch(lowerText));
//       if (isNonMedicine) {
//         print("❌ Blocked by pattern: $lowerText");
//       }
//       return isNonMedicine;
//     } catch (e) {
//       print("❌ Error in _isCommonNonMedicine: $e");
//       return false; // If regex fails, don't filter out
//     }
//   }
//
//   /// ✅ Get medicine suggestions by prefix
//   List<String> getMedicineSuggestions(String query, {int limit = 10}) {
//     if (!_isInitialized || query.trim().isEmpty) return [];
//
//     final lowerQuery = query.toLowerCase().trim();
//     final suggestions = <String>[];
//
//     for (final medicine in _medicineNames) {
//       if (medicine.startsWith(lowerQuery)) {
//         suggestions.add(_formatMedicineName(medicine));
//         if (suggestions.length >= limit) break;
//       }
//     }
//
//     if (suggestions.length < limit) {
//       for (final medicine in _medicineNames) {
//         if (medicine.contains(lowerQuery) &&
//             !suggestions.contains(_formatMedicineName(medicine))) {
//           suggestions.add(_formatMedicineName(medicine));
//           if (suggestions.length >= limit) break;
//         }
//       }
//     }
//
//     return suggestions;
//   }
//
//   /// Capitalize each word for display
//   String _formatMedicineName(String medicine) {
//     return medicine
//         .split(' ')
//         .map((word) =>
//     word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
//         .join(' ');
//   }
//
//   /// ✅ Dataset statistics
//   Map<String, int> getDatasetStats() {
//     return {
//       'total_medicines': _medicineNames.length,
//       'total_keywords': _medicineKeywords.length,
//       'is_initialized': _isInitialized ? 1 : 0,
//     };
//   }
// }

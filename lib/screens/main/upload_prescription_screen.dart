import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ocr_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../providers/medicine_provider.dart';
import '../../models/medicine_model.dart';
import '/providers/reminder_provider.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  File? _pickedImage;
  List<Map<String, String>> medicines = [];
  String doctorName = '';
  String hospitalName = '';
  String date = '';
  final OCRService _ocrService = OCRService();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        medicines = [];
      });
      await _performOCR(_pickedImage!);
    }
  }

  Future<void> _performOCR(File image) async {
    final extracted = await _ocrService.extractMedicinesFromImage(image);
    setState(() {
      medicines = List<Map<String, String>>.from(extracted['Medicines']);
      doctorName = extracted['Doctor'] ?? 'Not found';
      hospitalName = extracted['Hospital'] ?? 'Not found';
      date = extracted['Date'] ?? 'Not found';
    });
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFC8E6C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Upload Prescription",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Upload your prescription or take a photo to order medicines easily.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGlassButton(
                      label: "Upload",
                      icon: Icons.cloud_upload_rounded,
                      color: Colors.blueAccent,
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                    const SizedBox(width: 20),
                    _buildGlassButton(
                      label: "Take Photo",
                      icon: Icons.camera_alt_rounded,
                      color: Colors.green.shade700,
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                _buildGlassCard(
                  title: "Preview",
                  child: Center(
                    child: _pickedImage == null
                        ? const Text(
                      "No image selected",
                      style: TextStyle(color: Colors.black54),
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        _pickedImage!,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                _buildGlassCard(
                  title: "Prescription Information",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🏥 Hospital: $hospitalName",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text("👨‍⚕️ Doctor: $doctorName",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text("📅 Date: $date",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),

                if (medicines.isNotEmpty)
                  _buildGlassCard(
                    title: "Extracted Medicines",
                    child: Column(
                      children: medicines.map((medicine) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "💊 Medicine: ${medicine['Medicine'] ?? 'Not found'}",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "🕒 Dosage: ${medicine['Dosage'] ?? 'Not found'}",
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "📆 Duration: ${medicine['Duration'] ?? 'Not found'}",
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.black87),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 40),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 140,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 38),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: () async {
        if (medicines.isEmpty) {
          Fluttertoast.showToast(
            msg: "No medicines found in the prescription!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.redAccent,
            textColor: Colors.white,
          );
          return;
        }

        final medicineProvider =
        Provider.of<MedicineProvider>(context, listen: false);
        final reminderProvider =
        Provider.of<ReminderProvider>(context, listen: false);

        for (var med in medicines) {
          final name = med['Medicine'] ?? '';
          final dosage = med['Dosage'] ?? '';
          final duration = med['Duration'] ?? '';

          // ✅ Add to Firestore (Medicines)
          await medicineProvider.addMedicine(
            name: name,
            dosage: dosage,
            expiryDate: DateTime.now().add(const Duration(days: 365)),
            description: 'Duration: $duration',
          );

          // ✅ Also create reminders
          await reminderProvider.addReminderFromOCR(med);
        }

        Fluttertoast.showToast(
          msg: "Prescription saved and reminders created ✅",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        await medicineProvider.refreshMedicines();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/reminders');
        }
      },
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF42A5F5), Color(0xFF26A69A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.tealAccent.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Submit",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ocr_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UploadMedicineExpiryScreen extends StatefulWidget {
  final String medicineName;
  const UploadMedicineExpiryScreen({super.key, required this.medicineName});

  @override
  State<UploadMedicineExpiryScreen> createState() => _UploadMedicineExpiryScreenState();
}

class _UploadMedicineExpiryScreenState extends State<UploadMedicineExpiryScreen> {
  final OCRService _ocrService = OCRService();
  File? _pickedImage;
  String expiryDate = 'Not found';
  final TextEditingController _manualController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        expiryDate = 'Detecting...';
      });
      await _performOCR(_pickedImage!);
    }
  }

  Future<void> _performOCR(File image) async {
    final detectedDate = await _ocrService.extractExpiryDate(image);
    setState(() {
      expiryDate = detectedDate;
    });

    if (detectedDate == "Not found") {
      Fluttertoast.showToast(msg: "Expiry not detected. Enter manually.");
    } else {
      Fluttertoast.showToast(msg: "Detected expiry: $detectedDate");
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Expiry - ${widget.medicineName}",
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton("Upload", Icons.cloud_upload, Colors.blueAccent,
                        () => _pickImage(ImageSource.gallery)),
                const SizedBox(width: 20),
                _buildButton("Camera", Icons.camera_alt, Colors.green.shade700,
                        () => _pickImage(ImageSource.camera)),
              ],
            ),
            const SizedBox(height: 25),
            if (_pickedImage != null)
              ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(_pickedImage!, height: 200, fit: BoxFit.contain)),
            const SizedBox(height: 20),
            Text("Detected: $expiryDate",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (expiryDate == "Not found") _manualInput(),
            const SizedBox(height: 40),
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _manualInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: _manualController,
        decoration: const InputDecoration(
          hintText: "Enter manually (MM/YYYY)",
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final date = expiryDate != "Not found"
            ? expiryDate
            : _manualController.text.trim();
        if (date.isEmpty) {
          Fluttertoast.showToast(msg: "Please provide expiry date.");
          return;
        }
        Navigator.pop(context, date);
        Fluttertoast.showToast(
            msg: "Expiry saved for ${widget.medicineName}",
            backgroundColor: Colors.green);
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.teal,
      ),
      child: const Text("Save", style: TextStyle(fontSize: 18, color: Colors.white)),
    );
  }
}

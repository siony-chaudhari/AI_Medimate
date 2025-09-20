import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FinishProfileScreen extends StatefulWidget {
  const FinishProfileScreen({super.key});

  @override
  State<FinishProfileScreen> createState() => _FinishProfileScreenState();
}

class _FinishProfileScreenState extends State<FinishProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _gender = "Male";
  String? _profileImageUrl;
  File? _selectedImage;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data["name"] ?? "";
        _phoneController.text = data["phone"] ?? "";
        _ageController.text = data["age"]?.toString() ?? "";
        _gender = data["gender"] ?? "Male";
        _bloodGroupController.text = data["bloodGroup"] ?? "";
        _heightController.text = data["height"]?.toString() ?? "";
        _weightController.text = data["weight"]?.toString() ?? "";
        _profileImageUrl = data["profileImageUrl"];
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      if (!file.existsSync()) {
        debugPrint("File does not exist: ${pickedFile.path}");
        return;
      }
      setState(() {
        _selectedImage = file;
      });
    }
  }


  Future<String?> uploadImage(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("profileimages/${user.uid}.jpg");

      debugPrint("Uploading to path: ${storageRef.fullPath}");

      // Upload file
      await storageRef.putFile(imageFile);

      // Get download URL
      final url = await storageRef.getDownloadURL();
      debugPrint("Upload successful: $url");

      return url;
    } catch (e) {
      debugPrint("Image upload error: $e");
      return null;
    }
  }


  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? imageUrl = _profileImageUrl;
    if (_selectedImage != null) {
      imageUrl = await uploadImage(_selectedImage!);
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': _nameController.text,
      'phone': _phoneController.text,
      'age': int.tryParse(_ageController.text) ?? 0,
      'gender': _gender,
      'bloodGroup': _bloodGroupController.text,
      'height': int.tryParse(_heightController.text) ?? 0,
      'weight': int.tryParse(_weightController.text) ?? 0,
      'profileImageUrl': imageUrl ?? '',
    }, SetOptions(merge: true));

    setState(() {
      isLoading = false;
      _profileImageUrl = imageUrl;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')));
      Navigator.pop(context, true);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Your Profile")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!) // Local file picked
                          : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!) // Image from server
                          : const AssetImage("assets/Profile_avatar_placeholder.png")), // Local placeholder
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (val) => val!.isEmpty ? "Enter name" : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "Enter phone number";
                  } else if (val.length != 10) {
                    return "Phone number must be 10 digits";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: "Age"),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                items: ["Male", "Female", "Other"].map((g) {
                  return DropdownMenuItem(value: g, child: Text(g));
                }).toList(),
                onChanged: (val) => setState(() => _gender = val!),
                decoration: const InputDecoration(labelText: "Gender"),
              ),
              TextFormField(
                controller: _bloodGroupController,
                decoration: const InputDecoration(labelText: "Blood Group (e.g. A+)"),
              ),

              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: "Height (cm)"),
                keyboardType: TextInputType.number,
              ),

              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: "Weight (kg)"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveProfile,
                child: const Text("Save Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

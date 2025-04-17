import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  File? _profileImage;
  String? _existingProfileImage;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final String? userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final userResponse =
          await supabase.from('tbl_user').select().eq('id', userId).single();
      setState(() {
        _nameController.text = userResponse['user_name'] ?? '';
        _emailController.text = userResponse['user_email'] ?? '';
        _addressController.text = userResponse['user_address'] ?? '';
        _phoneController.text = userResponse['user_phone'] ?? '';
        _existingProfileImage = userResponse['profile_image'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadProfileImage() async {
    if (_profileImage == null) return _existingProfileImage;

    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.png';
      await supabase.storage.from('profiles').uploadBinary(
            fileName,
            await _profileImage!.readAsBytes(),
            fileOptions: const FileOptions(contentType: 'image/png'),
          );
      // Delete old image if it exists
      if (_existingProfileImage != null) {
        final oldFileName = _existingProfileImage!.split('/').last;
        await supabase.storage.from('profiles').remove([oldFileName]);
      }
      return supabase.storage.from('profiles').getPublicUrl(fileName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload profile image')),
      );
      return null;
    }
  }

  Future<void> updateUserData() async {
    final String? userId = supabase.auth.currentUser?.id;
    if (userId == null) return; // Corrected syntax

    try {
      Map<String, dynamic> updates = {
        'user_name': _nameController.text,
        'user_email': _emailController.text,
        'user_address': _addressController.text,
        'user_phone': _phoneController.text,
      };

      final imageUrl = await uploadProfileImage();
      if (imageUrl != null) updates['profile_image'] = imageUrl;

      await supabase.from('tbl_user').update(updates).eq('id', userId);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (_existingProfileImage != null
                          ? NetworkImage(_existingProfileImage!)
                          : null),
                  child: _profileImage == null && _existingProfileImage == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: updateUserData,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

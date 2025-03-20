import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:main_draft1/screens/generatecv.dart';
import 'package:main_draft1/screens/homescreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadCV extends StatefulWidget {
  final int jobId;
  const UploadCV({super.key, required this.jobId});

  @override
  State<UploadCV> createState() => _UploadCVState();
}

class _UploadCVState extends State<UploadCV> {
  bool _isLoading = false;
  String? _statusMessage;
  bool _isUploading = false;
  bool _isUploaded = false;
  Future<PlatformFile?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false, // Only single file upload
    );
    if (result != null) {
      return result.files.first;
    }
    return null;
  }

  Future<String?> uploadFileToSupabase(PlatformFile file) async {
    final supabase = Supabase.instance.client;

    try {
      final bucketName = 'cvs'; // Replace with your bucket name
      final filePath = "userid_${file.name}";

      Uint8List fileBytes;

      if (file.bytes != null) {
        // For Flutter Web, file.bytes will be available
        fileBytes = file.bytes!;
      } else {
        // For Mobile (Android/iOS), read file bytes manually
        fileBytes = await File(file.path!).readAsBytes();
      }

      // Upload file to Supabase Storage
      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            fileBytes,
          );

      // Get the public URL for the file
      final publicUrl =
          supabase.storage.from(bucketName).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

// Store File URL in Database
  Future<void> storeFileUrlInDatabase(String fileUrl) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase
          .from('tbl_application')
          .insert({'application_file': fileUrl, 'job_id': widget.jobId});
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    } catch (e) {
      setState(() {
        _statusMessage = 'Error storing file URL in database: $e';
      });
    }
  }

  // Handle File Upload Process
  Future<void> handleFileUpload() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final file = await pickFile();

    if (file != null) {
      final fileUrl = await uploadFileToSupabase(file);

      if (fileUrl != null) {
        await storeFileUrlInDatabase(fileUrl);
        setState(() {
          _statusMessage =
              'File uploaded and URL stored successfully: $fileUrl';
        });
      } else {
        setState(() {
          _statusMessage = 'Failed to upload file.';
        });
      }
    } else {
      setState(() {
        _statusMessage = 'No file selected.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CV Manager'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Manage Your CV',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : handleFileUpload,
                icon: _isUploaded
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.upload_file),
                label: Text(_isUploading
                    ? 'Uploading...'
                    : _isUploaded
                        ? 'CV Uploaded'
                        : 'Upload CV'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GenerateCVPage(
                        jobId: widget.jobId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.create),
                label: const Text('Generate CV'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              if (_statusMessage != null)
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _statusMessage!.contains('Error')
                        ? Colors.red
                        : Colors.green,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

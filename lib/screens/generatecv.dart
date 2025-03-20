import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GenerateCVPage extends StatefulWidget {
  final int jobId; // Job ID passed when applying for a job
  const GenerateCVPage({Key? key, required this.jobId}) : super(key: key);

  @override
  State<GenerateCVPage> createState() => _GenerateCVPageState();
}

class _GenerateCVPageState extends State<GenerateCVPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _isPdfGenerated = false;
  String? _pdfPath;
  Map<String, dynamic> userData = {};
  List<Map<String, dynamic>> education = [];
  List<Map<String, dynamic>> experience = [];
  List<Map<String, dynamic>> technical = [];
  List<Map<String, dynamic>> softs = [];
  List<Map<String, dynamic>> languages = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final userRes =
          await supabase.from('tbl_user').select().eq('id', userId).single();
      final eduRes = await supabase
          .from('tbl_educational_qualification')
          .select()
          .eq('user_id', userId);
      final expRes = await supabase
          .from('tbl_workexperience')
          .select()
          .eq('user_id', userId);
      final techSkillsRes = await supabase
          .from('tbl_usertechnicalskill')
          .select("*,tbl_technicalskills(*)")
          .eq('user_id', userId);
      final softSkillsRes = await supabase
          .from('tbl_usersoftskill')
          .select("*,tbl_softskill(*)")
          .eq('user_id', userId);
      final languagesRes = await supabase
          .from('tbl_userlanguage')
          .select("*,tbl_language(*)")
          .eq('user_id', userId);

      List<Map<String, dynamic>> techSkills = [];
      List<Map<String, dynamic>> softSkills = [];
      List<Map<String, dynamic>> langs = [];

      for (var tech in techSkillsRes) {
        if (tech['tbl_technicalskills'] != null) {
          techSkills.add(tech['tbl_technicalskills']);
        }
      }

      for (var soft in softSkillsRes) {
        if (soft['tbl_softskill'] != null) {
          softSkills.add(soft['tbl_softskill']);
        }
      }

      for (var lang in languagesRes) {
        if (lang['tbl_language'] != null) {
          langs.add(lang['tbl_language']);
        }
      }

      setState(() {
        userData = userRes;
        education = List<Map<String, dynamic>>.from(eduRes);
        experience = List<Map<String, dynamic>>.from(expRes);
        technical = techSkills;
        softs = softSkills;
        languages = langs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $e')),
      );
    }
  }

  Future<void> _generateAndUploadPDF() async {
    if (userData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not found!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pdf = pw.Document();

      final headerStyle =
          pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold);
      final normalTextStyle = pw.TextStyle(fontSize: 11);
      final boldTextStyle =
          pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(userData['user_name'] ?? 'Unknown',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                        '${userData['user_phone'] ?? ''} | ${userData['user_email'] ?? ''}',
                        style: normalTextStyle),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Education', style: headerStyle),
                  pw.Divider(),
                  ...education.map((edu) => pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(edu['edq_institution'] ?? '',
                              style: boldTextStyle),
                          pw.Text(
                              '${edu['edq_name'] ?? ''} (${edu['edq_todate']?.substring(0, 4) ?? ''})',
                              style: normalTextStyle),
                          pw.SizedBox(height: 4),
                        ],
                      )),
                ],
              ),
            ];
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/resume.pdf');
      await file.writeAsBytes(await pdf.save());

      // Upload to Supabase Storage
      final userId = supabase.auth.currentUser!.id;
      final storagePath = '$userId-${widget.jobId}.pdf';
      final fileBytes = await file.readAsBytes();

      final response = await supabase.storage.from('resumes').uploadBinary(
            storagePath,
            fileBytes,
          );

      if (response != null) {
        throw Exception('Failed to upload PDF: ${response}');
      }

      // Get the public URL of the uploaded file
      final publicUrl =
          supabase.storage.from('resumes').getPublicUrl(storagePath);

      // Insert application into tbl_application
      await supabase.from('tbl_application').insert({
        'user_id': userId,
        'job_id': widget.jobId,
        'application_file': publicUrl,
      });

      setState(() {
        _pdfPath = file.path;
        _isPdfGenerated = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Resume uploaded and application submitted!')),
      );

      OpenFile.open(_pdfPath);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate CV')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _generateAndUploadPDF,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate & Upload Resume'),
                  ),
                  if (_isPdfGenerated) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => OpenFile.open(_pdfPath),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View PDF'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

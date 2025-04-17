import 'dart:io';
import 'package:flutter/material.dart';
import 'package:main_draft1/screens/homescreen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class GenerateCVPage extends StatefulWidget {
  final String jobId;
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
  bool _applicationExists = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _checkExistingApplication();
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
          .select("*, tbl_technicalskills(*)")
          .eq('user_id', userId);
      final softSkillsRes = await supabase
          .from('tbl_usersoftskill')
          .select("*, tbl_softskill(*)")
          .eq('user_id', userId);
      final languagesRes = await supabase
          .from('tbl_userlanguage')
          .select("*, tbl_language(*)")
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
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $e')),
      );
    }
  }

  Future<void> _checkExistingApplication() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('tbl_application')
          .select()
          .eq('user_id', userId)
          .eq('job_id', widget.jobId)
          .maybeSingle();

      setState(() {
        _applicationExists = response != null;
        if (_applicationExists) {
          _isPdfGenerated = true;
          _pdfPath = null;
        }
      });
    } catch (e) {
      print('Error checking existing application: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking application status: $e')),
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

    if (_applicationExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Application already submitted for this job!')),
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
              // Header: Personal Information
              pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(userData['user_name'] ?? 'Unknown',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                        '${userData['user_phone'] ?? 'Not Provided'} | ${userData['user_email'] ?? 'Not Provided'}',
                        style: normalTextStyle),
                    if (userData['user_address'] != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(userData['user_address'] ?? '',
                          style: normalTextStyle),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Education Section
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Education', style: headerStyle),
                  pw.Divider(),
                  if (education.isEmpty)
                    pw.Text('No education details provided.',
                        style: normalTextStyle)
                  else
                    ...education.map((edu) => pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                                edu['edq_institution'] ?? 'Unknown Institution',
                                style: boldTextStyle),
                            pw.Text(
                                '${edu['edq_name'] ?? 'Unknown Qualification'} (${edu['edq_fromdate']?.substring(0, 4) ?? 'N/A'} - ${edu['edq_todate']?.substring(0, 4) ?? 'Present'})',
                                style: normalTextStyle),
                            if (edu['edq_details'] != null)
                              pw.Text(edu['edq_details'],
                                  style: normalTextStyle),
                            pw.SizedBox(height: 8),
                          ],
                        )),
                ],
              ),
              pw.SizedBox(height: 16),

              // Work Experience Section
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Work Experience', style: headerStyle),
                  pw.Divider(),
                  if (experience.isEmpty)
                    pw.Text('No work experience provided.',
                        style: normalTextStyle)
                  else
                    ...experience.map((exp) => pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(exp['work_designation'] ?? 'Unknown Role',
                                style: boldTextStyle),
                            pw.Text(exp['work_company'] ?? 'Unknown Company',
                                style: normalTextStyle),
                            pw.Text(
                                '${exp['work_fromdate']?.substring(0, 4) ?? 'N/A'} - ${exp['work_todate']?.substring(0, 4) ?? 'Present'}',
                                style: normalTextStyle),
                            if (exp['work_details'] != null)
                              pw.Text(exp['work_details'],
                                  style: normalTextStyle),
                            pw.SizedBox(height: 8),
                          ],
                        )),
                ],
              ),
              pw.SizedBox(height: 16),

              // Technical Skills Section
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Technical Skills', style: headerStyle),
                  pw.Divider(),
                  if (technical.isEmpty)
                    pw.Text('No technical skills provided.',
                        style: normalTextStyle)
                  else
                    pw.Wrap(
                      spacing: 10,
                      children: technical
                          .map((tech) => pw.Text(
                              tech['technicalskill_name'] ?? 'Unknown',
                              style: normalTextStyle))
                          .toList(),
                    ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Soft Skills Section
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Soft Skills', style: headerStyle),
                  pw.Divider(),
                  if (softs.isEmpty)
                    pw.Text('No soft skills provided.', style: normalTextStyle)
                  else
                    pw.Wrap(
                      spacing: 10,
                      children: softs
                          .map((soft) => pw.Text(
                              soft['softskill_name'] ?? 'Unknown',
                              style: normalTextStyle))
                          .toList(),
                    ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Languages Section
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Languages', style: headerStyle),
                  pw.Divider(),
                  if (languages.isEmpty)
                    pw.Text('No languages provided.', style: normalTextStyle)
                  else
                    pw.Wrap(
                      spacing: 10,
                      children: languages
                          .map((lang) => pw.Text(
                              lang['language_name'] ?? 'Unknown',
                              style: normalTextStyle))
                          .toList(),
                    ),
                ],
              ),
            ];
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/resume.pdf');
      await file.writeAsBytes(await pdf.save());

      // Upload to Supabase Storage with a unique filename
      final userId = supabase.auth.currentUser!.id;
      final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      final storagePath = '${userId}_${widget.jobId}_$timestamp.pdf';
      final fileBytes = await file.readAsBytes();

      await supabase.storage.from('resumes').uploadBinary(
            storagePath,
            fileBytes,
          );

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
        _applicationExists = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Resume uploaded and application submitted!')),
      );

      OpenFile.open(_pdfPath);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating or uploading PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate CV'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _applicationExists ? null : _generateAndUploadPDF,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate & Upload Resume'),
                  ),
                  if (_isPdfGenerated) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pdfPath != null
                          ? () => OpenFile.open(_pdfPath)
                          : null,
                      icon: const Icon(Icons.visibility),
                      label: const Text('View PDF'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Application already submitted for this job.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

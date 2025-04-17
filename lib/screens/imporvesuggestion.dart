import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:main_draft1/main.dart';

class SkillSuggestionPage extends StatefulWidget {
  final String jobId;
  final int matchScore;

  const SkillSuggestionPage(
      {super.key, required this.jobId, required this.matchScore});

  @override
  _SkillSuggestionPageState createState() => _SkillSuggestionPageState();
}

class _SkillSuggestionPageState extends State<SkillSuggestionPage> {
  String _suggestion = "Loading...";
  bool _isLoading = true;
  final String apiKey = "AIzaSyA3Dz0w6QeP6qtmLH9yj1ukdToL--VNVaw";

  @override
  void initState() {
    super.initState();
    fetchSuggestion();
  }

  Future<void> fetchSuggestion() async {
    try {
      final userId = supabase.auth.currentUser!.id;

      // Fetch job details
      final jobResponse = await supabase
          .from('tbl_job')
          .select('*, tbl_company(*)')
          .eq('id', widget.jobId)
          .single();
      final jobTechSkillsResponse = await supabase
          .from('tbl_jobtechnicalskill')
          .select('*, tbl_technicalskills(technicalskill_name)')
          .eq('job_id', widget.jobId);
      final jobSoftSkillsResponse = await supabase
          .from('tbl_jobsoftskill')
          .select('*, tbl_softskill(softskill_name)')
          .eq('job_id', widget.jobId);

      final jobTechSkills = jobTechSkillsResponse
          .map((s) => s['tbl_technicalskills']['technicalskill_name']
              .toString()
              .toLowerCase())
          .toList();
      final jobSoftSkills = jobSoftSkillsResponse
          .map((s) =>
              s['tbl_softskill']['softskill_name'].toString().toLowerCase())
          .toList();
      final jobDescription = jobResponse['job_description'] ?? '';
      final jobTitle = jobResponse['job_title'] ?? 'Unknown Job';

      // Fetch user skills
      final userTechSkills = await supabase
          .from('tbl_usertechnicalskill')
          .select('*, tbl_technicalskills(technicalskill_name)')
          .eq('user_id', userId);
      final userSoftSkills = await supabase
          .from('tbl_usersoftskill')
          .select('*, tbl_softskill(softskill_name)')
          .eq('user_id', userId);

      final userTechSkillsList = userTechSkills
          .map((s) => s['tbl_technicalskills']['technicalskill_name']
              .toString()
              .toLowerCase())
          .toList();
      final userSoftSkillsList = userSoftSkills
          .map((s) =>
              s['tbl_softskill']['softskill_name'].toString().toLowerCase())
          .toList();

      // Generate suggestion using Gemini API
      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
      final prompt =
          "Based on the job '$jobTitle' with description: '$jobDescription', required technical skills: $jobTechSkills, "
          "and soft skills: $jobSoftSkills, and the user's current technical skills: $userTechSkillsList "
          "and soft skills: $userSoftSkillsList, provide a detailed suggestion (up to 200 words) to improve "
          "the user's skills to better match the job requirements.";
      final response = await model.generateContent([Content.text(prompt)]);

      setState(() {
        _suggestion = response.text ?? "No suggestions available.";
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching suggestion: $e');
      setState(() {
        _suggestion = "Failed to load suggestion.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Improvement Suggestion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Match Score: ${widget.matchScore}%',
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.green,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Suggestion to Improve Your Skills:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Text(
                      _suggestion,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

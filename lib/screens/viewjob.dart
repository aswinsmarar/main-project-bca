import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:main_draft1/main.dart';
import 'package:main_draft1/screens/uploadcv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class JobViewPage extends StatefulWidget {
  final String jobId;

  const JobViewPage({super.key, required this.jobId});

  @override
  State<JobViewPage> createState() => _JobViewPageState();
}

class _JobViewPageState extends State<JobViewPage> {
  bool isSaved = false;
  bool isLoading = true;
  bool hasApplied = false;
  bool _isSubscribed = false;
  Map<String, dynamic> jobData = {};
  int? matchScore;
  final String apiKey =
      "AIzaSyA3Dz0w6QeP6qtmLH9yj1ukdToL--VNVaw"; // Replace with your Gemini API key

  @override
  void initState() {
    super.initState();
    fetchJob();
    checkSubscription();
  }

  Future<void> checkSubscription() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      final response = await supabase
          .from('tbl_user')
          .select('subscription_status')
          .eq('id', userId)
          .single();
      setState(() {
        _isSubscribed = response['subscription_status'] ==
            true; // Adjust based on your schema
      });
    }
  }

  Future<void> fetchJob() async {
    try {
      Map<String, dynamic> data = {};
      final response = await supabase
          .from('tbl_job')
          .select(
              '"*", tbl_jobsoftskill(*,tbl_softskill(*)), tbl_jobtechnicalskill(*,tbl_technicalskills(*)),tbl_company(*)')
          .eq('id', widget.jobId)
          .single();
      data['company_name'] = response['tbl_company']['company_name'];
      data['job_title'] = response['job_title'];
      data['job_type'] = response['job_type'];
      data['job_salary'] = response['job_salary'];
      data['job_location'] = response['job_location'];
      data['job_experience'] = response['job_experience'];
      data['job_date'] = response['job_date'];
      data['job_lastdate'] = response['job_lastdate'];
      data['description'] = response['job_description'];

      final technicalskills = await supabase
          .from('tbl_jobtechnicalskill')
          .select("*,tbl_technicalskills(*)")
          .eq('job_id', widget.jobId);
      final softskills = await supabase
          .from('tbl_jobsoftskill')
          .select("*,tbl_softskill(*)")
          .eq('job_id', widget.jobId);

      List<String> softskillsData = [];
      List<String> techskillsData = [];
      for (var skill in softskills) {
        softskillsData.add(skill['tbl_softskill']['softskill_name']);
      }
      for (var skill in technicalskills) {
        techskillsData.add(skill['tbl_technicalskills']['technicalskill_name']);
      }
      data['softskills'] = softskillsData;
      data['techskills'] = techskillsData;

      // Check if the user has already applied
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final applicationResponse = await supabase
            .from('tbl_application')
            .select()
            .eq('user_id', userId)
            .eq('job_id', widget.jobId)
            .maybeSingle();
        hasApplied = applicationResponse != null;

        // Fetch user skills and calculate match score
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

        int score = 0;
        for (var skill in techskillsData) {
          if (userTechSkillsList.contains(skill.toLowerCase())) score += 20;
        }
        for (var skill in softskillsData) {
          if (userSoftSkillsList.contains(skill.toLowerCase())) score += 15;
        }
        matchScore = score;
      }

      setState(() {
        jobData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching job or application status: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> getSkillSuggestion(
      List<String> jobTechSkills, List<String> jobSoftSkills) async {
    final userId = supabase.auth.currentUser!.id;
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

    final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
    final prompt =
        "Based on the job's required technical skills: $jobTechSkills and soft skills: $jobSoftSkills, "
        "and the user's current technical skills: $userTechSkillsList and soft skills: $userSoftSkillsList, "
        "provide a concise suggestion to improve the user's skills to better match the job requirements.";
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? "No suggestions available.";
  }

  void _applyForJob() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your application has been submitted successfully!'),
        backgroundColor: Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleSaveJob() {
    setState(() {
      isSaved = !isSaved;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            isSaved ? 'Job saved to bookmarks' : 'Job removed from bookmarks'),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Job Details'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        // actions: [
        //   IconButton(
        //     icon: Icon(
        //       isSaved ? Icons.bookmark : Icons.bookmark_border,
        //       color: isSaved ? const Color(0xFF2563EB) : Colors.black87,
        //     ),
        //     onPressed: _toggleSaveJob,
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.share_outlined),
        //     onPressed: () {
        //       // Share functionality
        //     },
        //   ),
        // ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            )
          : jobData.isEmpty
              ? const Center(
                  child: Text(
                    'Job not found',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildJobInfo(),
                      _buildDivider(),
                      _buildSkillsSection(
                        'Technical Skills',
                        jobData['techskills'],
                      ),
                      _buildSkillsSection('Soft Skills', jobData['softskills']),
                      _buildDivider(),
                      _buildJobDescription(),
                      _buildDivider(),
                      _buildSection('Description',
                          jobData['description'] ?? 'No description available'),
                      _buildDivider(),
                    ],
                  ),
                ),
      bottomSheet: isLoading || jobData.isEmpty || hasApplied
          ? null
          : _buildApplyButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: jobData['company_logo'] != null
                  ? Image.network(
                      jobData['company_logo'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.business,
                        size: 40,
                        color: Color(0xFF2563EB),
                      ),
                    )
                  : const Icon(
                      Icons.business,
                      size: 40,
                      color: Color(0xFF2563EB),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            jobData['job_title'] ?? 'Job Title',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            jobData['company_name'] ?? 'Company Name',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 4),
              Text(
                jobData['job_location'] ?? 'Location',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTag(jobData['job_type'] ?? 'Full-time',
                  const Color(0xFFEFF6FF), const Color(0xFF2563EB)),
              const SizedBox(width: 12),
              _buildTag(jobData['job_experience'] ?? '0-1 years',
                  const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildJobInfo() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final postedDate = jobData['job_date'] != null
        ? DateTime.parse(jobData['job_date'])
        : DateTime.now();
    final lastDateToApply = jobData['job_lastdate'] != null
        ? DateTime.parse(jobData['job_lastdate'])
        : DateTime.now().add(const Duration(days: 30));

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Posted on',
            dateFormat.format(postedDate),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.event_outlined,
            'Apply before',
            dateFormat.format(lastDateToApply),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.attach_money_outlined,
            'Salary',
            jobData['job_salary'] ?? 'Not specified',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.score_outlined,
            'Match Score',
            matchScore != null ? '$matchScore%' : 'N/A',
          ),
          if (matchScore != null && matchScore! < 50 && _isSubscribed)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: () async {
                  final suggestion = await getSkillSuggestion(
                    jobData['techskills'],
                    jobData['softskills'],
                  );
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Skill Improvement Suggestion'),
                      content: Text(suggestion),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Improve Your Skills'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 8,
      color: const Color(0xFFF3F4F6),
    );
  }

  Widget _buildSkillsSection(String title, List<String> skills) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          skills.isEmpty
              ? const Text(
                  'No skills specified',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 16,
                  ),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      skills.map((skill) => _buildSkillChip(skill)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildJobDescription() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            jobData['description'] ?? 'No description available',
            style: const TextStyle(
              color: Color(0xFF4B5563),
              height: 1.6,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              height: 1.6,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UploadCV(
                  jobId: widget.jobId,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Apply for this position',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

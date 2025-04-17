import 'package:flutter/material.dart';
import 'package:main_draft1/main.dart';
import 'package:main_draft1/screens/viewjob.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  List<Map<String, dynamic>> recommendedJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecommendations();
  }

  Future<void> fetchRecommendations() async {
    setState(() => _isLoading = true);
    final userId = supabase.auth.currentUser!.id;

    try {
      // Fetch user data
      final userTechSkills = await supabase
          .from('tbl_usertechnicalskill')
          .select('tbl_technicalskills(technicalskill_name)')
          .eq('user_id', userId);
      final userSoftSkills = await supabase
          .from('tbl_usersoftskill')
          .select('tbl_softskill(softskill_name)')
          .eq('user_id', userId);
      final userLanguages = await supabase
          .from('tbl_userlanguage')
          .select('tbl_language(language_name)')
          .eq('user_id', userId);
      final userWork = await supabase
          .from('tbl_workexperience')
          .select('work_designation')
          .eq('user_id', userId);
      final userEducation = await supabase
          .from('tbl_educational_qualification')
          .select('edq_name')
          .eq('user_id', userId);

      // Fetch all jobs with their required skills
      final allJobs =
          await supabase.from('tbl_job').select('*, tbl_company(*)');
      final jobTechSkills = await supabase
          .from('tbl_jobtechnicalskill')
          .select('job_id, tbl_technicalskills(technicalskill_name)');
      final jobSoftSkills = await supabase
          .from('tbl_jobsoftskill')
          .select('job_id, tbl_softskill(softskill_name)');

      // Convert user data to lists
      final userTechSkillList = userTechSkills
          .map((s) => s['tbl_technicalskills']['technicalskill_name']
              .toString()
              .toLowerCase())
          .toList();
      final userSoftSkillList = userSoftSkills
          .map((s) =>
              s['tbl_softskill']['softskill_name'].toString().toLowerCase())
          .toList();
      final userLanguagesList = userLanguages
          .map((l) =>
              l['tbl_language']['language_name'].toString().toLowerCase())
          .toList();
      final userWorkList = userWork
          .map((w) => w['work_designation'].toString().toLowerCase())
          .toList();
      final userQualificationsList = userEducation
          .map((e) => e['edq_name'].toString().toLowerCase())
          .toList();

      // Process job-specific skills into a map for quick lookup
      final Map<int, List<String>> jobTechSkillMap = {};
      final Map<int, List<String>> jobSoftSkillMap = {};
      for (var skill in jobTechSkills) {
        final jobId = skill['job_id'];
        final skillName = skill['tbl_technicalskills']['technicalskill_name']
            .toString()
            .toLowerCase();
        jobTechSkillMap.putIfAbsent(jobId, () => []).add(skillName);
      }
      for (var skill in jobSoftSkills) {
        final jobId = skill['job_id'];
        final skillName =
            skill['tbl_softskill']['softskill_name'].toString().toLowerCase();
        jobSoftSkillMap.putIfAbsent(jobId, () => []).add(skillName);
      }

      // Matching algorithm
      List<Map<String, dynamic>> matchedJobs = [];
      for (var job in allJobs) {
        final jobId = job['id'];
        final jobTechSkills = jobTechSkillMap[jobId] ?? [];
        final jobSoftSkills = jobSoftSkillMap[jobId] ?? [];
        final jobDescription =
            (job['job_description'] ?? '').toString().toLowerCase();
        final jobExperience =
            (job['job_experience'] ?? '').toString().toLowerCase();
        final jobQualification =
            (job['job_qualification'] ?? '').toString().toLowerCase();

        int score = _calculateMatchScore(
          jobTechSkills: jobTechSkills,
          jobSoftSkills: jobSoftSkills,
          jobDescription: jobDescription,
          jobExperience: jobExperience,
          jobQualification: jobQualification,
          userTechSkills: userTechSkillList,
          userSoftSkills: userSoftSkillList,
          userLanguages: userLanguagesList,
          userWorkExperience: userWorkList,
          userQualifications: userQualificationsList,
        );

        if (score > 0) {
          job['match_score'] = score;
          matchedJobs.add(job);
        }
      }

      // Sort and limit
      matchedJobs.sort((a, b) => b['match_score'].compareTo(a['match_score']));
      setState(() {
        recommendedJobs = matchedJobs.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching recommendations: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load recommendations')),
      );
    }
  }

  int _calculateMatchScore({
    required List<String> jobTechSkills,
    required List<String> jobSoftSkills,
    required String jobDescription,
    required String jobExperience,
    required String jobQualification,
    required List<String> userTechSkills,
    required List<String> userSoftSkills,
    required List<String> userLanguages,
    required List<String> userWorkExperience,
    required List<String> userQualifications,
  }) {
    int score = 0;
    const int maxScore = 100; // Define a maximum score for normalization

    // Technical Skills (weight: 30%)
    int techMatches = 0;
    for (var skill in userTechSkills) {
      if (jobTechSkills.contains(skill) || jobDescription.contains(skill)) {
        techMatches++;
      }
    }
    score += (techMatches * 30) ~/
        (userTechSkills.length + 1); // Avoid division by zero

    // Soft Skills (weight: 20%)
    int softMatches = 0;
    for (var skill in userSoftSkills) {
      if (jobSoftSkills.contains(skill) || jobDescription.contains(skill)) {
        softMatches++;
      }
    }
    score += (softMatches * 20) ~/ (userSoftSkills.length + 1);

    // Languages (weight: 15%)
    int langMatches = 0;
    for (var lang in userLanguages) {
      if (jobDescription.contains(lang)) {
        langMatches++;
      }
    }
    score += (langMatches * 15) ~/ (userLanguages.length + 1);

    // Work Experience (weight: 20%)
    int expMatches = 0;
    for (var exp in userWorkExperience) {
      if (jobExperience.contains(exp) || jobDescription.contains(exp)) {
        expMatches++;
      }
    }
    score += (expMatches * 20) ~/ (userWorkExperience.length + 1);

    // Qualifications (weight: 15%)
    int qualMatches = 0;
    for (var qual in userQualifications) {
      if (jobQualification.contains(qual) || jobDescription.contains(qual)) {
        qualMatches++;
      }
    }
    score += (qualMatches * 15) ~/ (userQualifications.length + 1);

    // Normalize to percentage
    return score > maxScore ? maxScore : score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Jobs'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : recommendedJobs.isEmpty
              ? const Center(child: Text('No recommendations found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: recommendedJobs.length,
                  itemBuilder: (context, index) {
                    final job = recommendedJobs[index];
                    String company =
                        job['tbl_company']['company_name'] ?? "Unknown";
                    String jobTitle = job['job_title'];
                    String salary = job['job_salary'] ?? "";
                    String jobType = job['job_type'] ?? "UnKnown";
                    String jobExperience = job['job_experience'] ?? "";
                    int matchScore = job['match_score'];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  JobViewPage(jobId: job['id'].toString())),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[200],
                                child: Text(
                                  company.substring(0, 1),
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(jobTitle,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        Text('Match: $matchScore%',
                                            style: const TextStyle(
                                                color: Colors.green)),
                                      ],
                                    ),
                                    Text(company,
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          child: Text(jobType ?? "Unknown",
                                              style: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontSize: 12)),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          child: Text(jobExperience,
                                              style: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(salary,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

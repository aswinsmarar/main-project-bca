import 'package:flutter/material.dart';
import 'package:main_draft1/screens/imporvesuggestion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:main_draft1/screens/viewjob.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> applications = [];
  bool isLoading = true;
  bool _isSubscribed = false;
  final String apiKey = "AIzaSyA3Dz0w6QeP6qtmLH9yj1ukdToL--VNVaw";

  @override
  void initState() {
    super.initState();
    fetchApplications();
    checkSubscription();
  }

  Future<void> checkSubscription() async {
    final userId = supabase.auth.currentUser!.id;
    if (userId != null) {
      try {
        final response = await supabase
            .from('tbl_subscription')
            .select("*")
            .eq('user_id', userId)
            .single();
        setState(() {
          _isSubscribed = response['sub_status'] == 1; // Adjust based on schema
        });
      } catch (e) {
        print('Error checking subscription: $e');
        setState(() {
          _isSubscribed = false;
        });
      }
    }
  }

  Future<void> fetchApplications() async {
    try {
      final currentUser = supabase.auth.currentUser?.id;
      if (currentUser == null) {
        setState(() {
          isLoading = false;
        });
        print('User is not logged in.');
        return;
      }

      // Fetch user data for scoring
      final userTechSkills = await supabase
          .from('tbl_usertechnicalskill')
          .select('*, tbl_technicalskills(technicalskill_name)')
          .eq('user_id', currentUser);
      final userSoftSkills = await supabase
          .from('tbl_usersoftskill')
          .select('*, tbl_softskill(softskill_name)')
          .eq('user_id', currentUser);
      final userLanguages = await supabase
          .from('tbl_userlanguage')
          .select('*, tbl_language(language_name)')
          .eq('user_id', currentUser);
      final userWork = await supabase
          .from('tbl_workexperience')
          .select()
          .eq('user_id', currentUser);
      final userEducation = await supabase
          .from('tbl_educational_qualification')
          .select()
          .eq('user_id', currentUser);

      final techSkills = userTechSkills
          .map((s) => s['tbl_technicalskills']['technicalskill_name']
              .toString()
              .toLowerCase())
          .toList();
      final softSkills = userSoftSkills
          .map((s) =>
              s['tbl_softskill']['softskill_name'].toString().toLowerCase())
          .toList();
      final languages = userLanguages
          .map((l) =>
              l['tbl_language']['language_name'].toString().toLowerCase())
          .toList();
      final workExperience = userWork
          .map((w) => w['work_designation'].toString().toLowerCase())
          .toList();
      final qualifications = userEducation
          .map((e) => e['edq_name'].toString().toLowerCase())
          .toList();

      // Fetch applications with status 1 (accepted) or 2 (rejected) only
      final response = await supabase
          .from('tbl_application')
          .select("*, tbl_job(*, tbl_company(*))")
          .eq('user_id', currentUser)
          .gt('application_status', 0);

      // Calculate match score for each application
      List<dynamic> applicationsWithScores = [];
      for (var app in response) {
        final job = app['tbl_job'];
        String jobDescription =
            (job['job_description'] ?? '').toString().toLowerCase();
        String jobExperience =
            (job['job_experience'] ?? '').toString().toLowerCase();
        String jobQualification =
            (job['job_qualification'] ?? '').toString().toLowerCase();

        int score = 0;
        for (var skill in techSkills) {
          if (jobDescription.contains(skill)) score += 20;
        }
        for (var skill in softSkills) {
          if (jobDescription.contains(skill)) score += 15;
        }
        for (var lang in languages) {
          if (jobDescription.contains(lang)) score += 10;
        }
        for (var exp in workExperience) {
          if (jobExperience.contains(exp) || jobDescription.contains(exp))
            score += 25;
        }
        for (var qual in qualifications) {
          if (jobQualification.contains(qual) || jobDescription.contains(qual))
            score += 30;
        }

        app['match_score'] = score;
        applicationsWithScores.add(app);
      }

      setState(() {
        applications = applicationsWithScores;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching applications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await supabase
          .from('tbl_application')
          .update({'is_read': true}).eq('id', id);
      setState(() {
        applications = applications.map((app) {
          if (app['id'] == id) {
            app['is_read'] = true;
          }
          return app;
        }).toList();
      });
    } catch (e) {
      print('Error updating application: $e');
    }
  }

  void _showResponseDialog(
      BuildContext context, Map<String, dynamic> application) {
    final job = application['tbl_job'];
    final replyMessage =
        application['application_reply'] ?? 'No reply provided';
    final status =
        application['application_status'] == 1 ? 'Accepted' : 'Rejected';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(job['job_title'] ?? 'No Job Title'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Company: ${job['tbl_company']['company_name'] ?? 'No Company Name'}'),
                const SizedBox(height: 8),
                Text('Status: $status',
                    style: TextStyle(
                      color: application['application_status'] == 1
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 8),
                Text('Match Score: ${application['match_score']}%'),
                const SizedBox(height: 8),
                Text('Reply:'),
                Text(
                  replyMessage,
                  style: TextStyle(
                    color: replyMessage == 'No reply provided'
                        ? Colors.grey
                        : Colors.black,
                    fontStyle: replyMessage == 'No reply provided'
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        JobViewPage(jobId: job['id'].toString()),
                  ),
                );
              },
              child: const Text('View Job Details'),
            ),
          ],
        );
      },
    );

    if (!(application['is_read'] ?? false)) {
      markAsRead(application['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : applications.isEmpty
              ? const Center(child: Text('No actioned applications found.'))
              : ListView.builder(
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final application = applications[index];
                    final job = application['tbl_job'];
                    final company = job['tbl_company'];
                    final isRead = application['is_read'] ?? false;
                    final replyMessage =
                        application['application_reply'] ?? 'No reply provided';
                    final status = application['application_status'] == 1
                        ? 'Accepted'
                        : 'Rejected';
                    final matchScore = application['match_score'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      elevation: isRead ? 1 : 3,
                      child: ListTile(
                        title: Text(
                          job['job_title'] ?? 'No Job Title',
                          style: TextStyle(
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(company['company_name'] ?? 'No Company Name'),
                            const SizedBox(height: 4),
                            Text(
                                'Location: ${job['job_location'] ?? 'Not specified'}'),
                            const SizedBox(height: 4),
                            Text('Status: $status',
                                style: TextStyle(
                                  color: application['application_status'] == 1
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                )),
                            const SizedBox(height: 4),
                            Text('Match Score: $matchScore%',
                                style: const TextStyle(color: Colors.green)),
                            const SizedBox(height: 4),
                            Text(
                              'Reply: $replyMessage',
                              style: TextStyle(
                                color: replyMessage == 'No reply provided'
                                    ? Colors.grey
                                    : Colors.black87,
                                fontStyle: replyMessage == 'No reply provided'
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (matchScore < 50 && _isSubscribed)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SkillSuggestionPage(
                                          jobId: job['id'].toString(),
                                          matchScore: matchScore,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Improve Your Skills'),
                                ),
                              ),
                          ],
                        ),
                        trailing: Icon(
                          isRead ? Icons.check_circle_outline : Icons.circle,
                          color: isRead ? Colors.grey : Colors.blue,
                        ),
                        onTap: () {
                          _showResponseDialog(context, application);
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

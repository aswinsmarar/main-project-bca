import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> applications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApplications();
  }

  Future<void> fetchApplications() async {
    try {
      // Ensure the user is logged in
      final currentUser = supabase.auth.currentUser!.id;
      if (currentUser == null) {
        setState(() {
          isLoading = false;
        });
        print('User is not logged in.');
        return;
      }

      // Fetch applications with related job and company data
      final response = await supabase.from('tbl_application').select(
          "*,tbl_job(*,tbl_company(*))"); // Correct syntax for nested relationships

      setState(() {
        applications = response as List<dynamic>;
        print(applications);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching applications: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> markasread(int id) async {
    try {
      await supabase
          .from('tbl_application')
          .update({'is_read': true}).eq('id', id);
    } catch (e) {
      print('Error updating application: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Applications'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : applications.isEmpty
              ? Center(child: Text('No applications found.'))
              : ListView.builder(
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final application = applications[index];
                    final job = application['tbl_job'];
                    final company = job['tbl_company'];

                    return ListTile(
                      title: Text(job['job_title'] ?? 'No Job Title'),
                      subtitle:
                          Text(company['company_name'] ?? 'No Company Name'),
                      onTap: () {
                        markasread(application['id']);
                      },
                    );
                  },
                ),
    );
  }
}

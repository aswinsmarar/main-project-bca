import 'package:flutter/material.dart';
import 'package:main_draft1/main.dart';
import 'package:main_draft1/screens/homescreen.dart';
import 'package:main_draft1/screens/objective.dart';
import 'package:main_draft1/screens/uploadcv.dart';
import 'package:main_draft1/screens/workexperience-form.dart';

class WorkExperienceListScreen extends StatefulWidget {
  @override
  _WorkExperienceListScreenState createState() =>
      _WorkExperienceListScreenState();
}

class _WorkExperienceListScreenState extends State<WorkExperienceListScreen> {
  List<Map<String, dynamic>> workExperienceData = [];
  bool _isLoading = false;
  final primaryColor = Color.fromARGB(255, 51, 31, 199);
  final accentColor =
      Color.fromARGB(255, 51, 31, 199); // A vibrant accent color

  @override
  void initState() {
    super.initState();
    fetchWorkExperience();
  }

  Future<void> fetchWorkExperience() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from(
              'tbl_workexperience') // Replace with your work experience table name
          .select()
          .eq('user_id', supabase.auth.currentUser!.id);

      setState(() {
        workExperienceData = response;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching work experience: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch work experience data')),
      );
    }
  }

  Future<void> deleteWorkExperience(int id) async {
    try {
      await supabase
          .from(
              'tbl_workexperience') // Replace with your work experience table name
          .delete()
          .eq('id', id);

      // Refresh the list after deletion
      fetchWorkExperience();
    } catch (e) {
      print("Error deleting work experience: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete work experience data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background for contrast
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 65),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Add your \nWork Experience\nDetails !!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[900],
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.all(16),
                    itemCount: workExperienceData.length + 1,
                    itemBuilder: (context, index) {
                      if (index == workExperienceData.length) {
                        return Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        WorkExperienceFormScreen()),
                              );

                              if (result == true) {
                                fetchWorkExperience(); // Refresh work experience list after returning
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(12),
                            ),
                            child:
                                Icon(Icons.add, size: 30, color: Colors.white),
                          ),
                        );
                      }

                      final workExp = workExperienceData[index];

                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkExperienceFormScreen(
                                  workExperienceData:
                                      workExp, // Pass the selected work experience data
                                ),
                              ),
                            ).then((result) {
                              if (result == true) {
                                fetchWorkExperience(); // Refresh the list after editing
                              }
                            });
                          },
                          contentPadding: EdgeInsets.all(16),
                          leading: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.work, color: accentColor),
                          ),
                          title: Text(
                            workExp['work_designation'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[900],
                            ),
                          ),
                          subtitle: Text(
                            "${workExp['work_company']} (${workExp['work_fromdate']} - ${workExp['work_todate']})",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey[600],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  bool confirmDelete = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text("Delete Work Experience"),
                                      content: Text(
                                          "Are you sure you want to delete this work experience entry?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text("Delete",
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmDelete == true) {
                                    deleteWorkExperience(workExp['id']);
                                  }
                                },
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  color: Colors.blueGrey[300]),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResumeObjectiveGenerator(),
                ));
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            "NEXT 3/5",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

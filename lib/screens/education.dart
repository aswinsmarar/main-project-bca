import 'package:flutter/material.dart';
import 'package:main_draft1/main.dart';
import 'package:main_draft1/screens/educationform.dart';
import 'package:main_draft1/screens/workexperience.dart';

class EducationListScreen extends StatefulWidget {
  const EducationListScreen({super.key});

  @override
  _EducationListScreenState createState() => _EducationListScreenState();
}

class _EducationListScreenState extends State<EducationListScreen> {
  List<Map<String, dynamic>> educationData = [];
  bool _isLoading = false;
  final primaryColor = const Color.fromARGB(255, 51, 31, 199);
  final accentColor =
      const Color.fromARGB(255, 51, 31, 199); // A vibrant accent color

  @override
  void initState() {
    super.initState();
    fetchEducation();
  }

  Future<void> fetchEducation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase
          .from('tbl_educational_qualification')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id);

      setState(() {
        educationData = response;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching education: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch education data')),
      );
    }
  }

  Future<void> deleteEducation(int id) async {
    try {
      await supabase
          .from('tbl_educational_qualification')
          .delete()
          .eq('id', id);

      // Refresh the list after deletion
      fetchEducation();
    } catch (e) {
      print("Error deleting education: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete education data')),
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
              "Add your \nEducational\nDetails !!",
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
                    padding: const EdgeInsets.all(16),
                    itemCount: educationData.length + 1,
                    itemBuilder: (context, index) {
                      if (index == educationData.length) {
                        return Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const EducationFormScreen()),
                              );

                              if (result == true) {
                                fetchEducation(); // Refresh education list after returning
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(12),
                            ),
                            child: const Icon(Icons.add,
                                size: 30, color: Colors.white),
                          ),
                        );
                      }

                      final edu = educationData[index];

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EducationFormScreen(
                                  educationData:
                                      edu, // Pass the selected education data
                                ),
                              ),
                            ).then((result) {
                              if (result == true) {
                                fetchEducation(); // Refresh the list after editing
                              }
                            });
                          },
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.school, color: accentColor),
                          ),
                          title: Text(
                            edu['edq_name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[900],
                            ),
                          ),
                          subtitle: Text(
                            "${edu['edq_institution']} - ${edu['edq_percentage']}%",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey[600],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  bool confirmDelete = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Delete Education"),
                                      content: const Text(
                                          "Are you sure you want to delete this education entry?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Delete",
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmDelete == true) {
                                    deleteEducation(edu['id']);
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
                  builder: (context) => WorkExperienceListScreen(),
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
            "NEXT 4/6",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

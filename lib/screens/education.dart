import 'package:flutter/material.dart';
import 'package:main_draft1/screens/educationform.dart';

class EducationListScreen extends StatefulWidget {
  @override
  _EducationListScreenState createState() => _EducationListScreenState();
}

class _EducationListScreenState extends State<EducationListScreen> {
  List<Map<String, String>> educationList = [];

  void _addOrEditEducation(Map<String, String> education, {int? index}) {
    setState(() {
      if (index != null) {
        // Update existing entry
        educationList[index] = education;
      } else {
        // Add new entry
        educationList.add(education);
      }
    });
  }

  void _navigateToEducationForm(
      {Map<String, String>? education, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EducationFormScreen(
          existingEducation: education,
        ),
      ),
    );

    if (result != null) {
      _addOrEditEducation(result, index: index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Education Qualifications"),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _navigateToEducationForm(),
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: educationList.length + 1,
          itemBuilder: (context, index) {
            // Ensure that index is within the bounds of the educationList
            if (index == educationList.length) {
              return Center(
                child: ElevatedButton(
                  onPressed: () => _navigateToEducationForm() ,
                  child: Icon(Icons.add),
                ),
              );
            }

            final edu = educationList[index];
            print("Length: ${educationList.length}");
            print("Index: $index");

            return ListTile(
              title: Text(edu['degree'] ?? ''),
              subtitle: Text("${edu['institution']} - ${edu['percentage']}%"),
              leading: Icon(Icons.school),
              onTap: () =>
                  _navigateToEducationForm(education: edu, index: index),
            );
          },
        ));
  }
}

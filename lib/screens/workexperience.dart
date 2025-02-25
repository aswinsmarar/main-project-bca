import 'package:flutter/material.dart';
import 'package:main_draft1/screens/educationform.dart';

class WorkListScreen extends StatefulWidget {
  @override
  _WorkListScreenState createState() => _WorkListScreenState();
}

class _WorkListScreenState extends State<WorkListScreen> {
  List<Map<String, String>> workList = [];

  void _addOrEditWork(Map<String, String> work, {int? index}) {
    setState(() {
      if (index != null) {
        // Update existing entry
        workList[index] = work;
      } else {
        // Add new entry
        workList.add(work);
      }
    });
  }

  void _navigateToWorkForm(
      {Map<String, String>? work, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EducationFormScreen(
          existingEducation: work,
        ),
      ),
    );

    if (result != null) {
      _addOrEditWork(result, index: index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        
        body: ListView.builder(
          itemCount: workList.length + 1,
          itemBuilder: (context, index) {
            // Ensure that index is within the bounds of the educationList
            if (index == workList.length) {
              return Center(
                child: ElevatedButton(
                  onPressed: () => _navigateToWorkForm() ,
                  child: Icon(Icons.add),
                ),
              );
            }

            final edu = workList[index];
            print("Length: ${workList.length}");
            print("Index: $index");

            return ListTile(
              title: Text(edu['degree'] ?? ''),
              subtitle: Text("${edu['institution']} - ${edu['percentage']}%"),
              leading: Icon(Icons.school),
              onTap: () =>
                  _navigateToWorkForm(work: edu, index: index),
            );
          },
        ));
  }
}

import 'package:flutter/material.dart';
import 'package:main_draft1/screens/languages.dart';

class TechnicalSkills extends StatefulWidget {
  const TechnicalSkills({super.key});

  @override
  State<TechnicalSkills> createState() => _TechnicalSkillsState();
}

class _TechnicalSkillsState extends State<TechnicalSkills> {
  List<Map<String, String>> mockTechnicalSkills = [
    { 'technicalskill_name': 'Flutter'},
    { 'technicalskill_name': 'Dart'},
    { 'technicalskill_name': 'JavaScript'},
    { 'technicalskill_name': 'TypeScript'},
    { 'technicalskill_name': 'Python'},
    { 'technicalskill_name': 'Java'},
    { 'technicalskill_name': 'C++'},
    { 'technicalskill_name': 'C#'},
    { 'technicalskill_name': 'Swift'},
    { 'technicalskill_name': 'Kotlin'},
    { 'technicalskill_name': 'Go'},
    { 'technicalskill_name': 'Rust'},
    { 'technicalskill_name': 'SQL'},
    { 'technicalskill_name': 'NoSQL'},
    { 'technicalskill_name': 'MongoDB'},
    { 'technicalskill_name': 'PostgreSQL'},
    { 'technicalskill_name': 'Firebase'},
    { 'technicalskill_name': 'Supabase'},
    { 'technicalskill_name': 'GraphQL'},
    { 'technicalskill_name': 'REST API'},
    { 'technicalskill_name': 'Docker'},
    { 'technicalskill_name': 'Kubernetes'},
    { 'technicalskill_name': 'CI/CD'},
    { 'technicalskill_name': 'Git'},
    { 'technicalskill_name': 'GitHub'},
    { 'technicalskill_name': 'AWS'},
    { 'technicalskill_name': 'Google Cloud'},
    { 'technicalskill_name': 'Azure'},
    { 'technicalskill_name': 'Machine Learning'},
    { 'technicalskill_name': 'Deep Learning'},
    { 'technicalskill_name': 'TensorFlow'},
    { 'technicalskill_name': 'PyTorch'},
    { 'technicalskill_name': 'Computer Vision'},
    { 'technicalskill_name': 'NLP'},
    { 'technicalskill_name': 'Cybersecurity'},
    { 'technicalskill_name': 'Penetration Testing'},
    { 'technicalskill_name': 'Blockchain'},
    { 'technicalskill_name': 'Smart Contracts'},
    { 'technicalskill_name': 'React'},
    { 'technicalskill_name': 'Angular'},
    { 'technicalskill_name': 'Vue.js'},
    { 'technicalskill_name': 'Node.js'},
    { 'technicalskill_name': 'Express.js'},
    { 'technicalskill_name': 'Spring Boot'},
    { 'technicalskill_name': 'Django'},
    { 'technicalskill_name': 'Flask'},
    { 'technicalskill_name': 'ASP.NET'},
    { 'technicalskill_name': 'Data Structures'},
    { 'technicalskill_name': 'Algorithms'},
    { 'technicalskill_name': 'Software Architecture'},
  ];

    List<String> selectedSkills = [];
  String searchQuery = '';  // Add this variable to store the search query

  // Function to toggle skill selection
  void toggleSkill(String id) {
    setState(() {
      if (selectedSkills.contains(id)) {
        selectedSkills.remove(id);
      } else {
        selectedSkills.add(id);
      }
    });
  }

  // Function to filter skills based on search query
  List<Map<String, String>> getFilteredSkills() {
    if (searchQuery.isEmpty) {
      return mockTechnicalSkills; // Return all skills if the search query is empty
    }
    return mockTechnicalSkills
        .where((skill) =>
            skill['technicalskill_name']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList(); // Filter skills based on search query
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SizedBox(
              height: 65,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 137 ),
              child: Text("Let us Know Your \nTechnical Skills.",style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
            ),
            SizedBox(height: 25,),
            TextFormField(
              onChanged: (query) {
                setState(() {
                  searchQuery = query;  // Update search query
                });
              },
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
            ),
            const SizedBox(height: 20),
        
            // Skills Selection
            Container(
              height: 580,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10, // Horizontal spacing
                  runSpacing: 10, // Vertical spacing
                  children: getFilteredSkills().map((skill) {
                    final isSelected = selectedSkills.contains(skill['id']);
                    return ChoiceChip(
                      label: Text(skill['technicalskill_name']!),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color.fromARGB(255, 3, 3, 3) : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      selected: isSelected,
                      selectedColor: const Color.fromARGB(255, 250, 248, 248), // Background color when selected
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Default background color
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isSelected ? Color.fromARGB(255, 51, 31, 199) : Colors.grey.shade400,
                        ),
                      ),
                      onSelected: (_) => toggleSkill(skill['id']!),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Languages(),));
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color.fromARGB(255, 51, 31, 199),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("NEXT 2/5", style: TextStyle(fontSize: 18)),
                ),
      ),
    );
  }
}
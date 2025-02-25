import 'package:flutter/material.dart';
import 'package:main_draft1/screens/technicalskills.dart';

class SoftSkill extends StatefulWidget {
  const SoftSkill({super.key});

  @override
  State<SoftSkill> createState() => _SoftSkillState();
}

class _SoftSkillState extends State<SoftSkill> {
  List<Map<String, String>> mockSoftSkills = [
    { 'softskill_name': 'Communication'},
    { 'softskill_name': 'Teamwork'},
    { 'softskill_name': 'Problem-Solving'},
    { 'softskill_name': 'Adaptability'},
    { 'softskill_name': 'Leadership'},
    { 'softskill_name': 'Time Management'},
    { 'softskill_name': 'Creativity'},
    { 'softskill_name': 'Conflict Resolution'},
    { 'softskill_name': 'Critical Thinking'},
    { 'softskill_name': 'Work Ethic'},
    { 'softskill_name': 'Empathy'},
    { 'softskill_name': 'Patience'},
    { 'softskill_name': 'Collaboration'},
    { 'softskill_name': 'Decision-Making'},
    { 'softskill_name': 'Conflict Management'},
    { 'softskill_name': 'Resilience'},
    { 'softskill_name': 'Open-Mindedness'},
    { 'softskill_name': 'Interpersonal Skills'},
    { 'softskill_name': 'Negotiation'},
    { 'softskill_name': 'Time Efficiency'},
    { 'softskill_name': 'Self-Discipline'},
    { 'softskill_name': 'Stress Management'},
    { 'softskill_name': 'Accountability'},
    { 'softskill_name': 'Confidence'},
    { 'softskill_name': 'Motivation'},
    { 'softskill_name': 'Active Listening'},
    { 'softskill_name': 'Delegation'},
    { 'softskill_name': 'Public Speaking'},
    { 'softskill_name': 'Creativity'},
    { 'softskill_name': 'Innovation'},
    { 'softskill_name': 'Goal-Oriented'},
    { 'softskill_name': 'Mentoring'},
    { 'softskill_name': 'Time Awareness'},
    { 'softskill_name': 'Conflict Avoidance'},
    { 'softskill_name': 'Self-Motivation'},
    { 'softskill_name': 'Work-Life Balance'},
    { 'softskill_name': 'Project Management'},
    { 'softskill_name': 'Organizational Skills'},
    { 'softskill_name': 'Attention to Detail'},
    { 'softskill_name': 'Strategic Thinking'},
    { 'softskill_name': 'Adaptability to Change'},
    { 'softskill_name': 'Crisis Management'},
    { 'softskill_name': 'Public Relations'},
    { 'softskill_name': 'Visionary Thinking'},
    { 'softskill_name': 'Customer Focus'},
    { 'softskill_name': 'Mindfulness'},
    { 'softskill_name': 'Continuous Learning'},
    { 'softskill_name': 'Workplace Etiquette'},
    { 'softskill_name': 'Team Building'},
    { 'softskill_name': 'Stress Resilience'},
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
      return mockSoftSkills; // Return all skills if the search query is empty
    }
    return mockSoftSkills
        .where((skill) =>
            skill['name']!.toLowerCase().contains(searchQuery.toLowerCase()))
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
              padding: const EdgeInsets.only(right: 85 ),
              child: Text("Welcome!! \nSelect Your Soft Skills.",style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
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
                      label: Text(skill['name']!),
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => TechnicalSkills(),));
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color.fromARGB(255, 51, 31, 199),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("NEXT 1/5", style: TextStyle(fontSize: 18)),
                ),
      ),
    );
  }
}

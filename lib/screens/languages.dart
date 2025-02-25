import 'package:flutter/material.dart';
import 'package:main_draft1/screens/languages.dart';
import 'package:main_draft1/screens/login.dart';
import 'package:main_draft1/screens/workexperience-form.dart';

class Languages extends StatefulWidget {
  const Languages({super.key});

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
  List<Map<String, String>> mockLanguages = [
    {'id': '1', 'name': 'English'},
    {'id': '2', 'name': 'Spanish'},
    {'id': '3', 'name': 'French'},
    {'id': '4', 'name': 'German'},
    {'id': '5', 'name': 'Mandarin Chinese'},
    {'id': '6', 'name': 'Hindi'},
    {'id': '7', 'name': 'Arabic'},
    {'id': '8', 'name': 'Portuguese'},
    {'id': '9', 'name': 'Bengali'},
    {'id': '10', 'name': 'Russian'},
    {'id': '11', 'name': 'Japanese'},
    {'id': '12', 'name': 'Korean'},
    {'id': '13', 'name': 'Italian'},
    {'id': '14', 'name': 'Dutch'},
    {'id': '15', 'name': 'Swedish'},
    {'id': '16', 'name': 'Turkish'},
    {'id': '17', 'name': 'Polish'},
    {'id': '18', 'name': 'Ukrainian'},
    {'id': '19', 'name': 'Greek'},
    {'id': '20', 'name': 'Hebrew'},
    {'id': '21', 'name': 'Thai'},
    {'id': '22', 'name': 'Vietnamese'},
    {'id': '23', 'name': 'Malay'},
    {'id': '24', 'name': 'Tagalog'},
    {'id': '25', 'name': 'Persian (Farsi)'},
    {'id': '26', 'name': 'Urdu'},
    {'id': '27', 'name': 'Tamil'},
    {'id': '28', 'name': 'Telugu'},
    {'id': '29', 'name': 'Marathi'},
    {'id': '30', 'name': 'Gujarati'},
    {'id': '31', 'name': 'Punjabi'},
    {'id': '32', 'name': 'Kannada'},
    {'id': '33', 'name': 'Malayalam'},
    {'id': '34', 'name': 'Sinhala'},
    {'id': '35', 'name': 'Burmese'},
    {'id': '36', 'name': 'Czech'},
    {'id': '37', 'name': 'Hungarian'},
    {'id': '38', 'name': 'Romanian'},
    {'id': '39', 'name': 'Finnish'},
    {'id': '40', 'name': 'Danish'},
    {'id': '41', 'name': 'Norwegian'},
    {'id': '42', 'name': 'Slovak'},
    {'id': '43', 'name': 'Serbian'},
    {'id': '44', 'name': 'Croatian'},
    {'id': '45', 'name': 'Bulgarian'},
    {'id': '46', 'name': 'Lithuanian'},
    {'id': '47', 'name': 'Latvian'},
    {'id': '48', 'name': 'Estonian'},
    {'id': '49', 'name': 'Filipino'},
    {'id': '50', 'name': 'Hawaiian'},
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
      return mockLanguages; // Return all skills if the search query is empty
    }
    return mockLanguages
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
              padding: const EdgeInsets.only(right: 135 ),
              child: Text("What Languages \nDo You Know.",style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => WorkExperienceForm(),));
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
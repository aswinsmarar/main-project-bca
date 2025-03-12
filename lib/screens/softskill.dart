import 'package:flutter/material.dart';
import 'package:main_draft1/main.dart';
import 'package:main_draft1/screens/technicalskills.dart';

class SoftSkill extends StatefulWidget {
  const SoftSkill({super.key});

  @override
  State<SoftSkill> createState() => _SoftSkillState();
}

class _SoftSkillState extends State<SoftSkill> {
  List<Map<String, dynamic>> mockSoftSkills = [];
  List<int> selectedSkills = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchSkill();
  }

  Future<void> insert() async {
    try {
      for (var i = 0; i < selectedSkills.length; i++) {
        await supabase.from('tbl_usersoftskill').insert([
          {
            'softskill_id': selectedSkills[i],
          }
        ]);
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TechnicalSkills()),
      );
    } catch (e) {
      print("Error Inserting Skills: $e");
    }
  }

  Future<void> fetchSkill() async {
    try {
      final response = await supabase.from('tbl_softskill').select();
      setState(() {
        mockSoftSkills = response;
      });
      print(response);
    } catch (e) {
      print("Error Fetching Skills: $e");
    }
  }

  void toggleSkill(int id) {
    setState(() {
      if (selectedSkills.contains(id)) {
        selectedSkills.remove(id);
      } else {
        selectedSkills.add(id);
      }
    });
  }

  List<Map<String, dynamic>> getFilteredSkills() {
    if (searchQuery.isEmpty) {
      return mockSoftSkills;
    }
    return mockSoftSkills
        .where((skill) => skill['softskills_name']!
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background for a clean look
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 65),
            Padding(
              padding: const EdgeInsets.only(right: 85),
              child: Text(
                "Welcome!! \nSelect Your Soft Skills.",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color:
                      Colors.blueGrey[800], // Darker text for better contrast
                ),
              ),
            ),
            const SizedBox(height: 25),
            TextFormField(
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                });
              },
              decoration: InputDecoration(
                hintText: "Search",
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.blueGrey[800]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(35),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
            ),
            const SizedBox(height: 20),

            // Skills Selection
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: getFilteredSkills().map((skill) {
                    final isSelected = selectedSkills.contains(skill['id']);
                    return ChoiceChip(
                      label: Text(
                        skill['softskill_name']!,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.blueGrey[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor:
                          Color.fromARGB(255, 51, 31, 199), // Selected color
                      backgroundColor: Colors.white, // Default color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? Color.fromARGB(255, 51, 31, 199)
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      elevation:
                          isSelected ? 3 : 0, // Add elevation when selected
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            insert();
            print(selectedSkills);
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color.fromARGB(255, 51, 31, 199),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            "NEXT 1/5",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

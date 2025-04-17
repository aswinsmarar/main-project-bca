import 'package:flutter/material.dart';
import 'package:main_draft1/main.dart';
import 'package:main_draft1/screens/education.dart';

class Languages extends StatefulWidget {
  const Languages({super.key});

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
  List<Map<String, dynamic>> mockLanguages = [];
  List<int> selectedSkills = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchSkill();
  }

  Future<void> fetchSkill() async {
    try {
      final response = await supabase.from('tbl_language').select();
      setState(() {
        mockLanguages = response;
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

  Future<void> insert() async {
    try {
      for (var i = 0; i < selectedSkills.length; i++) {
        await supabase.from('tbl_userlanguage').insert([
          {
            'language_id': selectedSkills[i],
          }
        ]);
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EducationListScreen()),
      );
    } catch (e) {
      print("Error Inserting Skills: $e");
    }
  }

  List<Map<String, dynamic>> getFilteredSkills() {
    if (searchQuery.isEmpty) {
      return mockLanguages;
    }
    return mockLanguages
        .where((skill) => skill['language_name']!
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color.fromARGB(255, 51, 31, 199); // Primary color
    final backgroundColor = Colors.grey[50]; // Light background
    final textColor = Colors.blueGrey[800]; // Dark text color

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 65),
            Padding(
              padding: const EdgeInsets.only(right: 85),
              child: Text(
                "What Languages \nDo You Know.",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: textColor,
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
                prefixIcon: Icon(Icons.search, color: primaryColor),
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
                        skill['language_name']!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: primaryColor, // Selected color
                      backgroundColor: Colors.white, // Default color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              isSelected ? primaryColor : Colors.grey.shade300,
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
            "NEXT 3/6",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:main_draft1/main.dart';
import 'package:main_draft1/screens/homescreen.dart';

class ResumeObjectiveGenerator extends StatefulWidget {
  const ResumeObjectiveGenerator({super.key});

  @override
  _ResumeObjectiveGeneratorState createState() =>
      _ResumeObjectiveGeneratorState();
}

class _ResumeObjectiveGeneratorState extends State<ResumeObjectiveGenerator> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _objcontroller = TextEditingController();
  String _generatedObjective = "";
  final String apiKey =
      "AIzaSyA3Dz0w6QeP6qtmLH9yj1ukdToL--VNVaw"; // Replace with your Gemini API key

  Future<void> generateObjective() async {
    final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
    final prompt =
        "Generate a professional resume objective using these keywords: ${_controller.text} and only give the response only one objective and no other text in the response";
    final response = await model.generateContent([Content.text(prompt)]);
    setState(() {
      _generatedObjective = response.text ?? "Failed to generate objective";
      _objcontroller.text = _generatedObjective;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    listModels();
  }

  Future<void> listModels() async {
    try {
      final models =
          await GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
      print("Models: $models");
    } catch (e) {
      print("Error listing models: $e");
    }
  }

  Future<void> insert() async {
    try {
      await supabase.from('tbl_objective').insert([
        {
          'objective': _objcontroller.text,
        }
      ]);
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ));
    } catch (e) {
      print("Error $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Resume Objective Generator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Enter keywords',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: generateObjective,
                child: Text('Generate Objective'),
              ),
              SizedBox(height: 16),
              // Text(
              //   _generatedObjective,
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              // ),

              TextField(
                controller: _objcontroller,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Objective',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: insert,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color.fromARGB(255, 51, 31, 199),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            "NEXT 5/5",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

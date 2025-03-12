import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ResumeObjectiveGenerator extends StatefulWidget {
  const ResumeObjectiveGenerator({super.key});

  @override
  _ResumeObjectiveGeneratorState createState() =>
      _ResumeObjectiveGeneratorState();
}

class _ResumeObjectiveGeneratorState extends State<ResumeObjectiveGenerator> {
  final TextEditingController _controller = TextEditingController();
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
              Text(
                _generatedObjective,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class EducationFormScreen extends StatefulWidget {
  final Map<String, String>? existingEducation;

  EducationFormScreen({this.existingEducation});

  @override
  _EducationFormScreenState createState() => _EducationFormScreenState();
}

class _EducationFormScreenState extends State<EducationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String degree;
  late String institution;
  late String percentage;

  @override
  void initState() {
    super.initState();
    degree = widget.existingEducation?['degree'] ?? '';
    institution = widget.existingEducation?['institution'] ?? '';
    percentage = widget.existingEducation?['percentage'] ?? '';
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      Navigator.pop(context, {
        'degree': degree,
        'institution': institution,
        'percentage': percentage,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          
              SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Text("From Date"),
            ),
              TextFormField(
                initialValue: degree,
                decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                
                
              ),
                onSaved: (value) => degree = value!,
                validator: (value) => value!.isEmpty ? "Enter degree" : null,
              ),
              SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Text("From Date"),
            ),
            
              TextFormField(
                initialValue: institution,
                decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                
                
              ),
                onSaved: (value) => institution = value!,
                validator: (value) => value!.isEmpty ? "Enter institution name" : null,
              ),
              TextFormField(
                initialValue: percentage,
                decoration: InputDecoration(labelText: "Percentage"),
                keyboardType: TextInputType.number,
                onSaved: (value) => percentage = value!,
                validator: (value) => value!.isEmpty ? "Enter percentage" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

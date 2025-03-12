import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:main_draft1/main.dart';

class EducationFormScreen extends StatefulWidget {
  final Map<String, dynamic>? educationData;

  const EducationFormScreen({super.key, this.educationData});

  @override
  _EducationFormScreenState createState() => _EducationFormScreenState();
}

class _EducationFormScreenState extends State<EducationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> degreeOptions = [];
  String? selectedDegree;
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _educationNameController =
      TextEditingController();
  final TextEditingController _percentageFieldController =
      TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  String? startDate;
  String? endDate;

  @override
  void initState() {
    super.initState();
    fetchDegrees();

    // Populate form fields if editing an existing education
    if (widget.educationData != null) {
      selectedDegree = widget.educationData!['educationtype_id'].toString();
      _institutionController.text = widget.educationData!['edq_institution'];
      _educationNameController.text = widget.educationData!['edq_name'];
      _percentageFieldController.text = widget.educationData!['edq_percentage'];
      startDate = widget.educationData!['edq_fromdate'];
      _startDateController.text = startDate ?? '';
      endDate = widget.educationData!['edq_todate'];
      _endDateController.text = endDate ?? '';
    }
  }

  Future<void> fetchDegrees() async {
    try {
      final response = await supabase.from('tbl_educationtype').select("*");
      setState(() {
        degreeOptions = response;
      });
    } catch (e) {
      print("Error fetching degrees: $e");
    }
  }

  Future<void> insert() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newEducation = {
          'educationtype_id': selectedDegree,
          'edq_institution': _institutionController.text,
          'edq_name': _educationNameController.text,
          'edq_percentage': _percentageFieldController.text,
          'edq_fromdate': startDate,
          'edq_todate': endDate,
          'user_id': supabase.auth.currentUser!.id,
        };

        if (widget.educationData != null) {
          // Update existing education
          await supabase
              .from('tbl_educational_qualification')
              .update(newEducation)
              .eq('id', widget.educationData!['id']);
        } else {
          // Insert new education
          await supabase
              .from('tbl_educational_qualification')
              .insert([newEducation]);
        }

        Navigator.pop(
            context, true); // Return true to indicate a refresh is needed
      } catch (e) {
        print("Error saving education: $e");
      }
    }
  }

  Future<void> deleteEducation() async {
    try {
      await supabase
          .from('tbl_educational_qualification')
          .delete()
          .eq('id', widget.educationData!['id']);

      Navigator.pop(
          context, true); // Return true to indicate a refresh is needed
    } catch (e) {
      print("Error deleting education: $e");
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
        if (isStartDate) {
          startDate = formattedDate;
          _startDateController.text = formattedDate;
        } else {
          endDate = formattedDate;
          _endDateController.text = formattedDate;
        }
      });
    }
  }

  InputDecoration customInputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.blueAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.redAccent, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.educationData != null ? "Edit Education" : "Add Education"),
        actions: [
          if (widget.educationData != null)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                bool confirmDelete = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Delete Education"),
                    content: Text(
                        "Are you sure you want to delete this education entry?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child:
                            Text("Delete", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmDelete == true) {
                  deleteEducation();
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text("Degree"),
                DropdownButtonFormField<String>(
                  value: selectedDegree,
                  hint: Text("Select Degree"),
                  items: degreeOptions.map((degree) {
                    return DropdownMenuItem<String>(
                      value: degree['id'].toString(),
                      child: Text(degree['educationtype_name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDegree = value;
                    });
                  },
                  decoration: customInputDecoration("Select Degree"),
                ),
                SizedBox(height: 20),
                Text("Institution"),
                TextFormField(
                  controller: _institutionController,
                  decoration: customInputDecoration("Enter institution name"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter institution name" : null,
                ),
                SizedBox(height: 20),
                Text("Education Name"),
                TextFormField(
                  controller: _educationNameController,
                  decoration: customInputDecoration("Enter education name"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter education name" : null,
                ),
                SizedBox(height: 20),
                Text("Percentage"),
                TextFormField(
                  controller: _percentageFieldController,
                  decoration: customInputDecoration("Enter percentage"),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? "Enter percentage" : null,
                ),
                SizedBox(height: 20),
                Text("Start Date"),
                TextFormField(
                  readOnly: true,
                  controller: _startDateController,
                  decoration:
                      customInputDecoration("Select start date").copyWith(
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _selectDate(context, true),
                  validator: (value) =>
                      startDate == null ? "Select start date" : null,
                ),
                SizedBox(height: 20),
                Text("End Date"),
                TextFormField(
                  readOnly: true,
                  controller: _endDateController,
                  decoration: customInputDecoration("Select end date").copyWith(
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _selectDate(context, false),
                  validator: (value) =>
                      endDate == null ? "Select end date" : null,
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: insert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text("Save",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

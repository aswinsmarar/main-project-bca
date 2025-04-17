import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:main_draft1/main.dart';

class WorkExperienceFormScreen extends StatefulWidget {
  final Map<String, dynamic>? workExperienceData;

  const WorkExperienceFormScreen({super.key, this.workExperienceData});

  @override
  _WorkExperienceFormScreenState createState() =>
      _WorkExperienceFormScreenState();
}

class _WorkExperienceFormScreenState extends State<WorkExperienceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  String? startDate;
  String? endDate;
  bool isCurrentlyWorking = false; // New state for checkbox

  @override
  void initState() {
    super.initState();

    // Populate form fields if editing an existing work experience
    if (widget.workExperienceData != null) {
      _companyController.text = widget.workExperienceData!['work_company'];
      _positionController.text = widget.workExperienceData!['work_designation'];
      _descriptionController.text =
          widget.workExperienceData!['work_description'];
      startDate = widget.workExperienceData!['work_fromdate'];
      _startDateController.text = startDate ?? '';
      endDate = widget.workExperienceData!['work_todate'];
      _endDateController.text = endDate ?? '';
      isCurrentlyWorking = widget.workExperienceData!['work_todate'] ==
          null; // If no end date, assume currently working
    }
  }

  Future<void> insert() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newWorkExperience = {
          'work_company': _companyController.text,
          'work_designation': _positionController.text,
          'work_description': _descriptionController.text,
          'work_fromdate': startDate,
          'work_todate': isCurrentlyWorking
              ? null
              : endDate, // Set null if currently working
          'user_id': supabase.auth.currentUser!.id,
        };

        if (widget.workExperienceData != null) {
          // Update existing work experience
          await supabase
              .from('tbl_workexperience')
              .update(newWorkExperience)
              .eq('id', widget.workExperienceData!['id']);
        } else {
          // Insert new work experience
          await supabase.from('tbl_workexperience').insert([newWorkExperience]);
        }

        Navigator.pop(
            context, true); // Return true to indicate a refresh is needed
      } catch (e) {
        print("Error saving work experience: $e");
      }
    }
  }

  Future<void> deleteWorkExperience() async {
    try {
      await supabase
          .from('tbl_workexperience')
          .delete()
          .eq('id', widget.workExperienceData!['id']);

      Navigator.pop(
          context, true); // Return true to indicate a refresh is needed
    } catch (e) {
      print("Error deleting work experience: $e");
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
        } else if (!isCurrentlyWorking) {
          // Only set end date if not currently working
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
        title: Text(widget.workExperienceData != null
            ? "Edit Work Experience"
            : "Add Work Experience"),
        actions: [
          if (widget.workExperienceData != null)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                bool confirmDelete = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Delete Work Experience"),
                    content: Text(
                        "Are you sure you want to delete this work experience entry?"),
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
                  deleteWorkExperience();
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
                Text("Company"),
                TextFormField(
                  controller: _companyController,
                  decoration: customInputDecoration("Enter company name"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter company name" : null,
                ),
                SizedBox(height: 20),
                Text("Designation"),
                TextFormField(
                  controller: _positionController,
                  decoration: customInputDecoration("Enter Designation"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter Designation" : null,
                ),
                SizedBox(height: 20),
                Text("Description"),
                TextFormField(
                  controller: _descriptionController,
                  decoration: customInputDecoration("Enter description"),
                  validator: (value) =>
                      value!.isEmpty ? "Enter description" : null,
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
                CheckboxListTile(
                  title: Text("Currently Working"),
                  value: isCurrentlyWorking,
                  onChanged: (bool? value) {
                    setState(() {
                      isCurrentlyWorking = value ?? false;
                      if (isCurrentlyWorking) {
                        endDate = null;
                        _endDateController
                            .clear(); // Clear end date when checked
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Colors.blueAccent,
                ),
                SizedBox(height: 20),
                Text("End Date"),
                TextFormField(
                  readOnly: true,
                  enabled: !isCurrentlyWorking, // Disable if currently working
                  controller: _endDateController,
                  decoration: customInputDecoration("Select end date").copyWith(
                    suffixIcon: Icon(Icons.calendar_today),
                    fillColor: isCurrentlyWorking
                        ? Colors.grey.shade200
                        : Colors.white,
                  ),
                  onTap: isCurrentlyWorking
                      ? null
                      : () => _selectDate(context, false),
                  validator: (value) => isCurrentlyWorking
                      ? null
                      : endDate == null
                          ? "Select end date"
                          : null,
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

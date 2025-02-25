import 'package:flutter/material.dart';
import 'package:main_draft1/screens/education.dart';

class WorkExperienceForm extends StatefulWidget {
  const WorkExperienceForm({super.key});

  @override
  State<WorkExperienceForm> createState() => _WorkExperienceFormState();
}

class _WorkExperienceFormState extends State<WorkExperienceForm> {
  TextEditingController companyController = TextEditingController();
  TextEditingController designationController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            SizedBox(
              height: 65,
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              
                Text("Any",style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
                TextButton(onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EducationListScreen(),));
                }, child: Text("Skip",style: TextStyle(fontSize: 17),)),
              ],
              
            ),
            Text("Work Experience??",style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
            SizedBox(height: 25,),
            
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Text("Instituition Name"),
            ),
          TextFormField(
              controller: companyController,
              validator: (value) =>
                  value!.isEmpty ? "Please enter Instituition name" : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                
                
              ),
            ),
            SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Text("Designation"),
            ),
            TextFormField(
              controller: designationController,
              validator: (value) =>
                  value!.isEmpty ? "Please enter your designation" : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                
                
              ),
            ),
            SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Text("From Date"),
            ),
            TextFormField(
              controller: designationController,
              validator: (value) =>
                  value!.isEmpty ? "Please from date" : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                
                
              ),
            ),
             SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Text("To Date"),
            ),
            TextFormField(
              controller: designationController,
              validator: (value) =>
                  value!.isEmpty ? "Please to date" : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                
                
              ),
            ),
             SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Text("From Date"),
            ),
            TextFormField(
              minLines: 5,
              maxLines: null,
              controller: designationController,
              validator: (value) =>
                  value!.isEmpty ? "Please from date" : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EducationListScreen(),));
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
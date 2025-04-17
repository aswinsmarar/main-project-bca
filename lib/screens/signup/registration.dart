import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:main_draft1/main.dart';
import 'package:main_draft1/screens/login.dart';
import 'package:main_draft1/screens/softskill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  bool passwordVisible = true;
  bool confirmPasswordVisible = true;
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController dobController = TextEditingController();

  File? _image;

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  bool isAdult(String dob) {
    final birthDate = DateFormat('yyyy-MM-dd').parse(dob);
    final today = DateTime.now();
    final age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      return age - 1 >= 18;
    }
    return age >= 18;
  }

  Future<void> signup() async {
    if (_formKey.currentState!.validate()) {
      if (!isAdult(dobController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be at least 18 years old")),
        );
        return;
      }
      try {
        final AuthResponse response = await supabase.auth.signUp(
          password: passwordController.text,
          email: emailController.text,
        );
        await uploadImage(response.user!.id);
        submit(response.user!.id);
      } catch (e) {
        print("Signup error: $e");
      }
    }
  }

  Future<void> uploadImage(String uid) async {
    if (_image == null) return;
    final fileName = "${uid}_${DateTime.now().millisecondsSinceEpoch}";
    try {
      await supabase.storage.from('profilepictures').upload(fileName, _image!);
    } catch (e) {
      print("Image upload error: $e");
    }
  }

  Future<void> submit(String uid) async {
    try {
      await supabase.from('tbl_user').insert({
        'id': uid,
        'user_name': nameController.text,
        'user_email': emailController.text,
        'user_phone': phoneController.text,
        'user_address': addressController.text,
        'user_password': passwordController.text,
        'user_dob': dobController.text,
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SoftSkill()),
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("New User Added")));
    } catch (e) {
      print("Error $e");
    }
  }

  DateTime? selectedDOB;

  Future<void> _selectDate(BuildContext context) async {
    DateTime today = DateTime.now();
    DateTime initialDate = today.subtract(const Duration(days: 18 * 365));
    DateTime firstDate =
        today.subtract(const Duration(days: 100 * 365)); // Max 100 years old
    DateTime lastDate =
        today.subtract(const Duration(days: 18 * 365)); // Min 18 years old

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && picked != selectedDOB) {
      setState(() {
        selectedDOB = picked;
        dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(
                  height: 15,
                ),
                Lottie.asset('assets/JobAnimation.json', height: 150),
                const SizedBox(height: 20),
                const Text(
                  "Sign Up",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Create a new account.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: pickImage,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              _image != null ? FileImage(_image!) : null,
                          child: _image == null
                              ? const Icon(Icons.camera_alt, size: 40)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: nameController,
                        validator: (value) => value!.isEmpty
                            ? "Please enter your full name"
                            : null,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintText: "Full Name",
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        validator: (value) =>
                            value!.isEmpty ? "Please enter your email" : null,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintText: "Email",
                          prefixIcon: const Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: phoneController,
                        validator: (value) => value!.isEmpty
                            ? "Please enter your phone number"
                            : null,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintText: "Phone",
                          prefixIcon: const Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: dobController,
                        readOnly: true, // Prevent manual input
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please select your date of birth";
                          }
                          return null;
                        },
                        onTap: () => _selectDate(context),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintText: "Date of Birth",
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: passwordController,
                        obscureText: passwordVisible,
                        validator: (value) => value!.isEmpty
                            ? "Please enter your password"
                            : null,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintText: "Password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(passwordVisible
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                passwordVisible = !passwordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: confirmPasswordVisible,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please confirm your password";
                          } else if (value != passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintText: "Confirm Password",
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(confirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                confirmPasswordVisible =
                                    !confirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => signup(),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                const Color.fromARGB(255, 51, 31, 199),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Sign Up",
                              style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Login()),
                          );
                        },
                        child: const Text(
                          "Already have an account? Log in",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Color.fromARGB(255, 11, 12, 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50), // Extra spacing at bottom
                    ],
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

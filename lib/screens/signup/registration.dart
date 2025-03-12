import 'dart:io';
import 'package:flutter/material.dart';
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

  Future<void> signup() async {
    if (_formKey.currentState!.validate()) {
      try {
        final AuthResponse response = await supabase.auth.signUp(
            password: passwordController.text, email: emailController.text);
        submit(response.user!.id);
        print(response.user!.id);
      } catch (e) {
        print("Signup error: $e");
      }
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
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SoftSkill()),
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("New User Added")));
    } catch (e) {
      print("Error $e");
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
                SizedBox(
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

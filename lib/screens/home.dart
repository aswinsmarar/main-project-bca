import 'package:flutter/material.dart';
import 'package:main_draft1/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final Session? session = supabase.auth.currentSession;
  String? name;
  bool _isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchUser();
  }
  
  Future<void> fetchUser() async {
    try {
      String uid = session!.user.id;
      final user = await supabase.from('tbl_user').select().eq('id', uid).single();
      print(user['user_name']);
      setState(() {
        name=user['user_name'];
        _isLoading=false;
      });
    } catch (e) {
      print("Error fetching user: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: 
        _isLoading ? const CircularProgressIndicator() : Text(name!)
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:main_draft1/intro.dart';
import 'package:main_draft1/screens/education.dart';
import 'package:main_draft1/screens/homescreen.dart';
import 'package:main_draft1/screens/login.dart';
import 'package:main_draft1/screens/mail.dart';
import 'package:main_draft1/screens/objective.dart';
import 'package:main_draft1/screens/softskill.dart';
import 'package:main_draft1/screens/technicalskills.dart';
import 'package:main_draft1/screens/uploadcv.dart';
import 'package:main_draft1/screens/viewjob.dart';
import 'package:main_draft1/screens/workexperience-form.dart';
import 'package:main_draft1/screens/workexperience.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://vikweyufqcgpnoyqxmld.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZpa3dleXVmcWNncG5veXF4bWxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ5MjkxNDgsImV4cCI6MjA1MDUwNTE0OH0.X1Fb8H9j8ryh14M4AlyjJkrWK-WJWG4Yq0aj-tfklIg',
  );
  runApp(const MainApp());
}

final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: EmailSender());
  }
}

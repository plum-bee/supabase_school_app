import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_school_app/src/app.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://hvhmngdpbtsyoburdzxj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2aG1uZ2RwYnRzeW9idXJkenhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDQzMTMzNDcsImV4cCI6MjAxOTg4OTM0N30.4R9TuPvouUM7XN72qhvaf3at8ZgURBJMrZ79FedI9Qg',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

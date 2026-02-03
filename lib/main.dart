import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:ofatodoapps/firebase_options.dart';
import 'package:ofatodoapps/authentication/authgate.dart';
import 'models/todo_model.dart';
import 'package:get/get.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  Hive.registerAdapter(TodoModelAdapter());
  await Hive.openBox<TodoModel>('todos');
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
   const MyApp({super.key});
  @override
  Widget build(BuildContext context) {

    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: AuthGate()
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:ofatodoapps/models/todo_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ofatodoapps/pages/login_page.dart';
import 'package:ofatodoapps/view/todo_view.dart';

class TodoModelController extends GetxController {
  RxList<TodoModel> todos = <TodoModel>[].obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final box = Hive.box<TodoModel>('todos');
  var isLoading = false.obs;
  @override
  void onInit() {
    super.onInit();
    //syncOfflineTodos();
    _firebaseAuth.authStateChanges().listen((user) async {
      if (user != null) {
        await syncOfflineTodos();
        await syncFromFirebaseToHive();
        loadTodos();
      }
    });
  }

  void loadTodos() {
    todos.value = box.values.toList();
  }

  Future<void> addTodo({String? title}) async {
    if (title == null || title.trim().isEmpty) return;
    final todo = TodoModel(title: title);
    await box.add(todo);
    final connected = await Connectivity().checkConnectivity();
    final user = _firebaseAuth.currentUser;
    if (connected != ConnectivityResult.none && user != null) {
      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('todos')
          .add({'title': title, 'isDone': false});
      todo.firebaseId = docRef.id;
      await todo.save();
    }
    // loadTodos();
  }

  Future<void> deleteTodo(int index) async {
    try {
      final todokey = box.keyAt(index);
      final todo = box.get(todokey)!;
      final user = _firebaseAuth.currentUser;

      if (user != null && todo.firebaseId != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('todos')
            .doc(todo.firebaseId)
            .delete();
      }
      await todo.delete();
      // loadTodos();
    } catch (e) {
      Text('Error deleting todo: $e');
    }
  }

  Future<void> syncOfflineTodos() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    for (var todo in box.values) {
      if (todo.firebaseId == null) {
        try {
          final docRef = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('todos')
              .add({'title': todo.title, 'isDone': todo.isDone});
          todo.firebaseId = docRef.id;
          await todo.save();
        } catch (e) {
          print('Error syncing todo $e');
          ScaffoldMessenger.of(
            Get.context!,
          ).showSnackBar(SnackBar(content: Text('error is: $e')));
        }
      }
    } //only sync if offline
    loadTodos();
  }

  Future<void> syncFromFirebaseToHive() async {
    final connected = await Connectivity().checkConnectivity();
    final user = _firebaseAuth.currentUser;
    if (connected == ConnectivityResult.none) return;
    if (user == null) return;
    final querySnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .get();
    for (var doc in querySnapshot.docs) {
      final exists = box.values.any((todo) => todo.firebaseId == doc.id);
      if (!exists) {
        final todo = TodoModel(
          title: doc['title'],
          isDone: doc['isDone'],
          firebaseId: doc.id,
        );
        await box.add(todo);
      }
    }
    printAllTodos();
    loadTodos();
  }

  void printAllTodos() {
    final box = Hive.box<TodoModel>('todos');

    if (box.isEmpty) {
      print('Hive box is empty!');
      return;
    }

    print('--- All Todos in Hive ---');
    for (var todo in box.values) {
      print(
        'Title: ${todo.title}, isDone: ${todo.isDone}, firebaseId: ${todo.firebaseId}',
      );
    }
    print('------------------------');
  }

  Future<void> logIn(String email, String password) async {
    try {
      isLoading.value = true;
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      ScaffoldMessenger.of(
        Get.context!,
      ).showSnackBar(SnackBar(content: Text('Login Successful')));
      Get.off(() => TodoPage());
    } catch (e) {
      print('Error logging in: $e');
      ScaffoldMessenger.of(
        Get.context!,
      ).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      isLoading.value = true;
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        SnackBar(content: Text('Registration successful Successful')),
      );
      Get.off(() => LoginPage());
    } catch (e) {
      print('Error registering the account: $e');
      ScaffoldMessenger.of(
        Get.context!,
      ).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await Hive.box<TodoModel>('todos').clear();
    Get.offAll(() => LoginPage());
  }
}

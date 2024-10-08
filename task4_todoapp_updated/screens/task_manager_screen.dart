import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class TaskManagerScreen extends StatefulWidget {
  @override
  _TaskManagerScreenState createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _taskController = TextEditingController();
  List<String> _tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _requestPermission();
  }

  Future<void> _fetchTasks() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore.collection('tasks').where('userId', isEqualTo: user.uid).get();
      setState(() {
        _tasks = snapshot.docs.map((doc) => doc['task']).toList();
      });
    }
  }

  Future<void> _addTask() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('tasks').add({'task': _taskController.text, 'userId': user.uid});
      _taskController.clear();
      _fetchTasks();
      _sendNotification(_taskController.text); // Send notification for the task
    }
  }

  Future<void> _sendNotification(String task) async {
    // This function should send notifications via Firebase Cloud Messaging (to be implemented).
  }

  Future<void> _requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      print("FCM Token: $token");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task Manager"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _taskController,
              decoration: InputDecoration(labelText: "Add a new task"),
            ),
          ),
          ElevatedButton(
            onPressed: _addTask,
            child: Text("Add Task"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_tasks[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

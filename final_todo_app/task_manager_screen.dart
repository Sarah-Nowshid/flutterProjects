import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'weather_service.dart';
import 'login_screen.dart';

class TaskManagerScreen extends StatefulWidget {
  @override
  _TaskManagerScreenState createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _taskController = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  List<String> _tasks = [];
  String _weatherInfo = '';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _requestPermission();
    _refreshTokenPeriodically();
    _fetchWeather();
  }

  Future<void> _refreshTokenPeriodically() async {
    Future.delayed(Duration(hours: 1), () async {
      User? user = _auth.currentUser;
      if (user != null) {
        String idToken = await user.getIdToken(true);
        print('Refreshed ID Token: $idToken');
      }
      _refreshTokenPeriodically();
    });
  }

  Future<void> _requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      String? token = await messaging.getToken();
      print("FCM Token: $token");
    } else {
      print('User declined or has not accepted permission');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('Notification Title: ${message.notification!.title}');
        print('Notification Body: ${message.notification!.body}');
      }
    });
  }

  Future<void> _fetchTasks() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore.collection('tasks')
            .where('userId', isEqualTo: user.uid).get();
        final tasks = snapshot.docs.map((doc) => doc['task'] as String).toList();
        setState(() {
          _tasks = tasks;
        });
        _saveTasksLocally(tasks);
      }
    } catch (e) {
      print('Error fetching tasks from Firestore. Loading from local storage...');
      _loadTasksFromLocalStorage();
    }
  }

  Future<void> _addTask() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('tasks').add({
        'task': _taskController.text,
        'userId': user.uid,
      });
      _taskController.clear();
      _fetchTasks();
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final weatherData = await _weatherService.fetchWeather('New York'); 
      setState(() {
        _weatherInfo = '${weatherData['weather'][0]['description']} in ${weatherData['name']}, Temperature: ${weatherData['main']['temp']}K';
      });
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  Future<void> _saveTasksLocally(List<String> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tasks', tasks);
  }

  Future<void> _loadTasksFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTasks = prefs.getStringList('tasks') ?? [];
    setState(() {
      _tasks = savedTasks;
    });
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
          Text(
            'Weather Info: $_weatherInfo',
            style: TextStyle(fontSize: 16),
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

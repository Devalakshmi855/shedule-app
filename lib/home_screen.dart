import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Declare AssetsAudioPlayer globally
  final AssetsAudioPlayer assetsAudioPlayer = AssetsAudioPlayer();

  String selectedDay = 'Monday';
  TimeOfDay selectedTime = TimeOfDay.now();
  String selectedActivity = 'Wake up';

  final List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> activities = [
    'Wake up',
    'Go to gym',
    'Breakfast',
    'Meetings',
    'Lunch',
    'Quick nap',
    'Go to library',
    'Dinner',
    'Go to sleep',
  ];

  List<Map<String, dynamic>> reminders = [];
  bool showReminderForm = true; // Flag to toggle form visibility

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Start checking the time every minute
    Timer.periodic(Duration(minutes: 1), (timer) {
      _checkTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the debug banner by setting `debugShowCheckedModeBanner` to false in MaterialApp
      body: Center(
        // Center all content vertically and horizontally
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Align items to the top
          children: <Widget>[
            // Your Schedule Div with Trash Icon
            Container(
              width: double.infinity, // Takes full width
              color: Colors.blue, // Blue colored div
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Your Schedule',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.white),
                    onPressed: () {
                      _clearReminders();
                    },
                  ),
                ],
              ),
            ),

            // Show reminders as labels with toggle button
            ...reminders.asMap().entries.map((entry) {
              int index = entry.key;
              var reminder = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${reminder['day']} - ${reminder['activity']} at ${reminder['time'].hour}:${reminder['time'].minute.toString().padLeft(2, '0')}",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Switch(
                      value: reminder['isEnabled'],
                      onChanged: (bool value) {
                        setState(() {
                          reminders[index]['isEnabled'] = value;
                        });
                      },
                    ),
                  ],
                ),
              );
            }).toList(),

            // Conditionally show the form
            if (showReminderForm) ...[
              SizedBox(height: 32),

              // Day Dropdown
              DropdownButton<String>(
                value: selectedDay,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedDay = newValue!;
                  });
                },
                items: daysOfWeek.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),

              SizedBox(height: 16),

              // Time Picker Button
              TextButton(
                onPressed: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null && picked != selectedTime)
                    setState(() {
                      selectedTime = picked;
                    });
                },
                child: Text(
                  "Select Time: ${selectedTime.format(context)}",
                ),
              ),

              SizedBox(height: 16),

              // Activity Dropdown
              DropdownButton<String>(
                value: selectedActivity,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedActivity = newValue!;
                  });
                },
                items: activities.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),

              SizedBox(height: 32),

              // Set Reminder Button
              ElevatedButton(
                onPressed: _setReminder,
                child: Text('Set Reminder'),
              ),
            ],

            // Spacer to push the '+' button to the bottom
            Spacer(),
          ],
        ),
      ),
      // Floating '+' Button at the bottom-right corner
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            showReminderForm = !showReminderForm;
          });
        },
        child: Icon(showReminderForm ? Icons.close : Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _setReminder() async {
    final now = DateTime.now();
    var scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(Duration(days: 1));
    }

    var androidDetails = AndroidNotificationDetails(
      'channelId',
      'Local Notification',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    var generalNotificationDetails =
        NotificationDetails(android: androidDetails);

    try {
      await flutterLocalNotificationsPlugin.schedule(
        0,
        'Reminder',
        'Time for $selectedActivity',
        scheduledDateTime,
        generalNotificationDetails,
        androidAllowWhileIdle: true,
        payload: 'Reminder Notification',
      );

      setState(() {
        reminders.add({
          'day': selectedDay,
          'time': scheduledDateTime,
          'activity': selectedActivity,
          'isEnabled': true, // Initialize the toggle as enabled
        });
        showReminderForm = false; // Hide form after setting reminder
      });

      print('Notification scheduled successfully');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  void _checkTime() {
    final now = DateTime.now();
    String currentDay = daysOfWeek[now.weekday - 1];

    for (var reminder in reminders) {
      final reminderTime = reminder['time'] as DateTime;
      final reminderDay = reminder['day'] as String;
      final isEnabled = reminder['isEnabled'] as bool;

      if (isEnabled &&
          currentDay == reminderDay &&
          now.hour == reminderTime.hour &&
          now.minute == reminderTime.minute) {
        _playSound();
        _showReminderNotification(reminder);
      }
    }
  }

  void _playSound() {
    assetsAudioPlayer.open(
      Audio("assets/audio/chimes-25845.mp3"),
      autoStart: true,
      showNotification: true,
    );
  }

  void _showReminderNotification(Map<String, dynamic> reminder) async {
    var androidDetails = AndroidNotificationDetails(
      'channelId',
      'Local Notification',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    var generalNotificationDetails =
        NotificationDetails(android: androidDetails);

    try {
      await flutterLocalNotificationsPlugin.show(
        0,
        'Reminder',
        'Time for ${reminder['activity']}',
        generalNotificationDetails,
        payload: 'Reminder Notification',
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  void _clearReminders() {
    setState(() {
      reminders.clear();
    });
    print('All reminders cleared');
  }
}

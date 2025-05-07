// scheduled_jobs_screen.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class Job {
  String customerName;
  String address;
  String dateTime;
  bool isCompleted;

  Job({required this.customerName, required this.address, required this.dateTime, required this.isCompleted});

  Map<String, dynamic> toJson() => {
    'customerName': customerName,
    'address': address,
    'dateTime': dateTime,
    'isCompleted': isCompleted,
  };

  static Job fromJson(Map<String, dynamic> json) => Job(
    customerName: json['customerName'],
    address: json['address'],
    dateTime: json['dateTime'],
    isCompleted: json['isCompleted'],
  );
}

class ScheduledJobsScreen extends StatefulWidget {
  @override
  _ScheduledJobsScreenState createState() => _ScheduledJobsScreenState();
}

class _ScheduledJobsScreenState extends State<ScheduledJobsScreen> {
  List<Job> _jobs = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final jobList = prefs.getStringList('scheduled_jobs') ?? [];
    setState(() {
      _jobs = jobList.map((jobStr) => Job.fromJson(json.decode(jobStr))).toList();
    });
  }

  Future<void> _saveJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final jobList = _jobs.map((job) => json.encode(job.toJson())).toList();
    await prefs.setStringList('scheduled_jobs', jobList);
  }

  void _markAsCompleted(int index) {
    setState(() {
      _jobs[index].isCompleted = true;
    });
    _saveJobs();
  }

  void _addJobOnSelectedDate(DateTime selectedDate) {
    final jobsOnDate = _getJobsForDay(selectedDate);
    if (jobsOnDate.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠ Warning: Job(s) already scheduled on this day!')),
      );
    }

    final newJob = Job(
      customerName: 'Jane Smith',
      address: '456 Another Road',
      dateTime: selectedDate.toIso8601String(),
      isCompleted: false,
    );
    setState(() {
      _jobs.add(newJob);
    });
    _saveJobs();
  }

  List<Job> _getJobsForDay(DateTime day) {
    return _jobs.where((job) {
      final jobDate = DateTime.parse(job.dateTime);
      return jobDate.year == day.year && jobDate.month == day.month && jobDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final jobsForSelectedDay = _getJobsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: AppBar(title: Text('Scheduled Jobs')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final selected = _selectedDay ?? _focusedDay;
          _addJobOnSelectedDate(selected);
        },
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final jobs = _getJobsForDay(date);
                if (jobs.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          Expanded(
            child: jobsForSelectedDay.isEmpty
              ? Center(child: Text('No jobs on this day'))
              : ListView.builder(
                  itemCount: jobsForSelectedDay.length,
                  itemBuilder: (context, index) {
                    final job = jobsForSelectedDay[index];
                    return ListTile(
                      title: Text(job.customerName),
                      subtitle: Text('${job.address}\n${job.dateTime}'),
                      trailing: IconButton(
                        icon: Icon(
                          job.isCompleted ? Icons.check_circle : Icons.schedule,
                          color: job.isCompleted ? Colors.green : Colors.orange,
                        ),
                        onPressed: () => _markAsCompleted(_jobs.indexOf(job)),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

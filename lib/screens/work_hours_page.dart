import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserWorkHoursPage extends StatefulWidget {
  final String userId;

  UserWorkHoursPage({required this.userId});

  @override
  _UserWorkHoursPageState createState() => _UserWorkHoursPageState();
}

class _UserWorkHoursPageState extends State<UserWorkHoursPage> {
  late DateTime todayStart;
  late DateTime todayEnd;
  late Duration currentActiveTime;
  late Map<String, Duration> officeWorkHoursMap;
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0); // Midnight today
    todayEnd = DateTime.now(); // Current time
    currentActiveTime = Duration.zero;
    officeWorkHoursMap = {};
    _getWorkHours();
  }

  Future<void> _getWorkHours() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    QuerySnapshot checkInsSnapshot = await firestore
        .collection('checkins')
        .where('user_id', isEqualTo: widget.userId)
        .orderBy('check_in_time', descending: true)
        .get();

    DateTime? currentCheckInTime;
    Map<String, Duration> tempOfficeWorkHoursMap = {};

    for (var doc in checkInsSnapshot.docs) {
      DateTime checkInTime = (doc['check_in_time'] as Timestamp).toDate();
      String officeName = doc['office_name'];
      DateTime? checkOutTime;
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('check_out_time') && data['check_out_time'] != null) {
        checkOutTime = (data['check_out_time'] as Timestamp).toDate();
      }

      if (checkOutTime != null) {
        Duration officeDuration = checkOutTime.difference(checkInTime);
        tempOfficeWorkHoursMap[officeName] = (tempOfficeWorkHoursMap[officeName] ?? Duration.zero) + officeDuration;
      } else {
        if (doc['status'] == 'checked_in') {
          currentCheckInTime = checkInTime;
        }
      }
    }

    if (currentCheckInTime != null) {
      Duration activeTime = todayEnd.difference(currentCheckInTime);
      String currentOffice = checkInsSnapshot.docs.first['office_name'];
      tempOfficeWorkHoursMap[currentOffice] = (tempOfficeWorkHoursMap[currentOffice] ?? Duration.zero) + activeTime;
    }

    setState(() {
      officeWorkHoursMap = tempOfficeWorkHoursMap;
      totalDuration = officeWorkHoursMap.values.fold(Duration.zero, (sum, current) => sum + current);
      currentActiveTime = currentCheckInTime != null ? todayEnd.difference(currentCheckInTime) : Duration.zero;
    });
  }

  String formatDuration(Duration duration) {
    int days = duration.inDays;
    int hours = duration.inHours % 24;
    int minutes = duration.inMinutes % 60;
    return '$days days, $hours hrs, $minutes mins';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('User Work Hours',style: TextStyle(fontWeight: FontWeight.w700,color: Colors.white),),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade300, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Current Active Time (Today's work hour)
            _buildSectionCard(
              title: 'Current Active Time',
              value: formatDuration(currentActiveTime),
              valueColor: Colors.green,
              icon: Icons.timer,
            ),
            SizedBox(height: 20),

            // Display Total Work Time across all check-ins
            _buildSectionCard(
              title: 'Total Work Time',
              value: formatDuration(totalDuration),
              valueColor: Colors.blue,
              icon: Icons.access_time,
            ),
            SizedBox(height: 20),

            // Display Total Work Time for each office
            Text(
              'Work Hours by Office:',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: officeWorkHoursMap.length,
                itemBuilder: (context, index) {
                  String office = officeWorkHoursMap.keys.elementAt(index);
                  Duration officeDuration = officeWorkHoursMap[office]!;
                  String formattedDuration = formatDuration(officeDuration);

                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      title: Text(
                        office,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      subtitle: Text(
                        'Worked Hours: $formattedDuration',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [valueColor.withOpacity(0.3), valueColor.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: valueColor, size: 30),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

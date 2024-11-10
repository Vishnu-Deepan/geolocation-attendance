import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryPage extends StatelessWidget {
  final String userId; // Pass userId as argument

  AttendanceHistoryPage({required this.userId});

  // Helper function to format timestamps
  String formatTime(Timestamp timestamp) {
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  // Function to show detailed view in a popup
  void showDetailsDialog(BuildContext context, DocumentSnapshot checkin) {
    final checkInTime = checkin['check_in_time'] as Timestamp?;
    final checkOutTime = checkin['check_out_time'] as Timestamp?;
    final officeName = checkin['office_name'] as String;
    final status = checkin['status'] as String;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.teal[50], // Subtle background color for the dialog
          title: Text(
            '$officeName - ${status == 'checked_in' ? 'Checked In' : 'Checked Out'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.teal,
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Check-in Time
                Row(
                  children: [
                    Text(
                      'Check-in Time: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      checkInTime != null ? formatTime(checkInTime) : 'N/A',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // Check-out Time (if available)
                if (checkOutTime != null) ...[
                  Row(
                    children: [
                      Text(
                        'Check-out Time: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        formatTime(checkOutTime),
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700, // Red for check-out
                        ),
                      ),
                    ],
                  ),
                ],
                // Still checked in status
                if (status == 'checked_in') ...[
                  SizedBox(height: 10),
                  Text(
                    'Still checked in...',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Attendance History',style: TextStyle(fontWeight: FontWeight.w700),),
        backgroundColor: Colors.teal.shade400,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('checkins') // Accessing the checkins collection
              .where('user_id', isEqualTo: userId) // Assuming user_id is stored with each checkin
              .orderBy('check_in_time', descending: true) // Sort by check-in time
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No attendance history available.'));
            }

            // Get the check-in data
            final checkinData = snapshot.data!.docs;

            return ListView.builder(
              itemCount: checkinData.length,
              itemBuilder: (context, index) {
                final checkin = checkinData[index];
                final checkInTime = checkin['check_in_time'] as Timestamp?;
                final officeName = checkin['office_name'] as String;

                return Card(
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: InkWell(
                    onTap: () => showDetailsDialog(context, checkin),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.teal.shade300,
                            Colors.blue.shade300,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  officeName,
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  checkInTime != null
                                      ? formatTime(checkInTime)
                                      : 'No check-in time',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

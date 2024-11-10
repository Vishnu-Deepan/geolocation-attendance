import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ManualAttendancePage extends StatefulWidget {
  final User? user;

  ManualAttendancePage({required this.user});

  @override
  _ManualAttendancePageState createState() => _ManualAttendancePageState();
}

class _ManualAttendancePageState extends State<ManualAttendancePage> {
  bool isCheckedIn = false;
  String checkInOfficeId = ''; // Track the office ID where the user checked in
  DateTime? checkOutTime;
  String? userName; // To store the user's name

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadCheckInStatus();
  }

  Future<void> _loadUserName() async {
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user!.uid)
        .get();

    if (userSnapshot.exists) {
      setState(() {
        userName = userSnapshot.data()?['name'] ?? 'Guest';
      });
    }
  }

  Future<void> _loadCheckInStatus() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('checkins')
        .where('user_id', isEqualTo: widget.user!.uid)
        .orderBy('check_in_time', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        isCheckedIn = snapshot.docs.first['status'] == 'checked_in';
        checkInOfficeId = snapshot.docs.first['office_id'];
      });
    }
  }

  Future<void> _handleCheckIn(String officeId) async {
    final officeSnapshot = await FirebaseFirestore.instance
        .collection('officeLocations')
        .doc(officeId)
        .get();

    if (officeSnapshot.exists) {
      String officeName = officeSnapshot.data()?['office_name'] ?? 'Unknown Office';

      await FirebaseFirestore.instance.collection('checkins').add({
        'user_id': widget.user!.uid,
        'office_id': officeId,
        'office_name': officeName,
        'status': 'checked_in',
        'check_in_time': DateTime.now(),
        'user_name': userName,
      });

      setState(() {
        isCheckedIn = true;
        checkInOfficeId = officeId;
      });
    }
  }

  Future<void> _handleCheckOut(String officeId) async {
    await FirebaseFirestore.instance
        .collection('checkins')
        .where('user_id', isEqualTo: widget.user!.uid)
        .where('office_id', isEqualTo: officeId)
        .where('status', isEqualTo: 'checked_in')
        .limit(1)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        snapshot.docs.first.reference.update({
          'status': 'checked_out',
          'check_out_time': DateTime.now(),
        });

        setState(() {
          isCheckedIn = false;
          checkInOfficeId = '';
          checkOutTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _showConfirmationDialog(String officeId, String officeName, bool isCheckIn) async {
    DateTime currentTime = DateTime.now();
    String timeString = DateFormat('hh:mm a').format(currentTime);

    String action = isCheckIn ? "Check-In" : "Check-Out";
    String formattedTime = isCheckIn
        ? timeString
        : DateFormat('hh:mm a').format(currentTime);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Confirm $action',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Office: $officeName',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Time: $formattedTime',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isCheckIn) {
                  _handleCheckIn(officeId);
                } else {
                  _handleCheckOut(officeId);
                }
              },
              child: Text(
                'Confirm',
                style: TextStyle(color: Colors.blue),
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
      appBar: AppBar(
        centerTitle:
        true,
        title: Text("Manual Check-In/Out",style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                userName != null ? "Welcome $userName !!" : "Loading...",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('officeLocations').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var office = snapshot.data!.docs[index];
                      String officeId = office.id;
                      String officeName = office['office_name'];

                      return Card(
                        elevation: 8,
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.white.withOpacity(0.9),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                officeName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  isCheckedIn && checkInOfficeId == officeId
                                      ? ElevatedButton.icon(
                                    onPressed: () {
                                      _showConfirmationDialog(officeId, officeName, false);
                                    },
                                    icon: Icon(Icons.exit_to_app),
                                    label: Text("Check-Out"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  )
                                      : !isCheckedIn
                                      ? ElevatedButton.icon(
                                    onPressed: () {
                                      _showConfirmationDialog(officeId, officeName, true);
                                    },
                                    icon: Icon(Icons.check_circle),
                                    label: Text("Check-In"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  )
                                      : SizedBox(),
                                ],
                              ),
                              if (checkOutTime != null && checkInOfficeId == officeId)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    "Checked out at: ${DateFormat('hh:mm a').format(checkOutTime!)}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

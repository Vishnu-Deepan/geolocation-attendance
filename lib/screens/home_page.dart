import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocation_attendance/screens/login_page.dart';
import 'package:geolocation_attendance/screens/manual_check_in.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../service/location_service.dart';
import 'attendance_history.dart';
import 'work_hours_page.dart';

class HomeScreen extends StatefulWidget {
  User? user;

  HomeScreen({required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? latitude;
  double? longitude;
  bool isCheckedIn = false;
  bool isGpsTrackingEnabled =
      true; // New variable to manage GPS tracking toggle
  final LocationService locationService = LocationService();
  late StreamSubscription<Position> _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    if (isGpsTrackingEnabled) {
      locationService.setCheckInOutCallback(_handleCheckInOut);
      _startLocationTracking();
      _loadCheckInStatus();
      _startListeningToCheckInStatus();
    }
  }

  Future<void> _loadCheckInStatus() async {
    bool status = await locationService.getCheckInStatus(widget.user!.uid);
    setState(() {
      isCheckedIn = status;
    });
  }

  void _handleCheckInOut(bool checkedIn) {
    setState(() {
      isCheckedIn = checkedIn;
    });
  }

  void _startLocationTracking() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      await locationService.handleCheckInOut(
        widget.user!,
        LatLng(latitude!, longitude!),
      );
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    super.dispose();
  }

  void _startListeningToCheckInStatus() {
    FirebaseFirestore.instance
        .collection('checkins')
        .where('user_id', isEqualTo: widget.user!.uid)
        .orderBy('check_in_time', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        setState(() {
          isCheckedIn = doc['status'] == 'checked_in';
        });
      }
    });
  }

  void _toggleGpsTracking() {
    setState(() {
      isGpsTrackingEnabled = !isGpsTrackingEnabled;
    });
    if (isGpsTrackingEnabled) {
      locationService.setCheckInOutCallback(_handleCheckInOut);
      _startLocationTracking();
      _loadCheckInStatus();
      _startListeningToCheckInStatus();
    } else {
      _positionStreamSubscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff17EAD9), Color(0xff6078EA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Employee Attendance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCheckInStatusCard(),
            SizedBox(height: 20),
            _buildToggleGpsButton(), // Add the toggle button here
            SizedBox(height: 20),
            isGpsTrackingEnabled
                ? _buildMap()
                : Card(
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    color: Colors.red.shade100
              ,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Please Check-in/Out Manually at Required Location.",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.0,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Automated Attendance System is turned off.",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.0,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    icon: Icons.edit_location,
                    label: "Manual Check-In/Out",
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  ManualAttendancePage(
                                    user: widget.user,
                                  )));
                    },
                    color: Colors.purpleAccent,
                  ),
                  _buildActionCard(
                    icon: Icons.access_time,
                    label: "Working Hours",
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  UserWorkHoursPage(
                                    userId: widget.user!.uid,
                                  )));
                    },
                    color: Colors.blueAccent,
                  ),
                  _buildActionCard(
                    icon: Icons.history,
                    label: "Attendance History",
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  AttendanceHistoryPage(
                                    userId: widget.user!.uid,
                                  )));
                    },
                    color: Color(0xff1BCEDF),
                  ),
                  _buildActionCard(
                    icon: Icons.settings,
                    label: "Settings",
                    onTap: () {},
                    color: Color(0xff000000),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Toggle Button for GPS tracking
  Widget _buildToggleGpsButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Automatic GPS Tracking",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(width: 10),
        Switch(
          value: isGpsTrackingEnabled,
          onChanged: (value) => _toggleGpsTracking(),
          activeColor: Colors.blueAccent,
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.shade300,
        ),
      ],
    );
  }

  // Check-In Status Card and other widgets remain unchanged
  Widget _buildCheckInStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isCheckedIn
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isCheckedIn ? Icons.check_circle : Icons.cancel,
              color: isCheckedIn ? Colors.green : Colors.red,
              size: 40,
            ),
            SizedBox(width: 16),
            Text(
              isCheckedIn ? 'You are Checked In' : 'You are Checked Out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCheckedIn ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Map Section
  Widget _buildMap() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: latitude != null && longitude != null
          ? FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(latitude!, longitude!),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(latitude!, longitude!),
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: Color(0xff1BCEDF), // Blue color from theme
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }

  // Action Cards for manual check-in, working hours, etc.
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

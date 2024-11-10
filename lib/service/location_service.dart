import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  List<Map<String, dynamic>> officeLocations = [];

  // Callback to notify the widget about state changes
  Function(bool)? onCheckInOutChanged;

  // Method to set the callback function
  void setCheckInOutCallback(Function(bool) callback) {
    onCheckInOutChanged = callback;
  }

  // Fetch office locations from Firestore dynamically
  Future<void> fetchOfficeLocations() async {
    final QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('officeLocations').get();

    officeLocations = snapshot.docs.map((doc) {
      return {
        'latitude': doc['latitude'],
        'longitude': doc['longitude'],
        'radius': doc['radius'],
        'office_name': doc['office_name'],
      };
    }).toList();
  }

  // Get the current location of the user
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    // Check if the app has permission to access location
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permission permanently denied');
    }

    // When permission is granted, get the current location
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // Get user's name from Firestore
  Future<String> getUserName(String userId) async {
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc['name'] ?? 'Unknown User';
    }
    return 'Unknown User';
  }

  // Check if the current location is inside any office area (geofence check)
  String isOffice(LatLng userLocation) {
    for (var office in officeLocations) {
      double officeLat = office['latitude'];
      double officeLon = office['longitude'];
      int radius = office['radius'];

      double distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        officeLat,
        officeLon,
      );

      if (distance <= radius) {
        return office['office_name'];
      }
    }
    return ''; // Return empty string if the user is outside all office locations
  }

  Future<bool> getCheckInStatus(String userId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore
        .collection('checkins')
        .where('user_id', isEqualTo: userId)
        .orderBy('check_in_time', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var data = snapshot.docs.first;
      String status = data['status'];
      return status == 'checked_in';
    }
    return false;
  }

  Future<void> checkIn(User user, LatLng location) async {
    String officeName = isOffice(location);
    if (officeName.isNotEmpty) {
      String userName = await getUserName(user.uid);

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference checkins = firestore.collection('checkins');

      await checkins.add({
        'user_id': user.uid,
        'name': userName,
        'office_name': officeName,
        'check_in_time': Timestamp.now(),
        'latitude': location.latitude,
        'longitude': location.longitude,
        'status': 'checked_in',
      }).then((value) {
        if (onCheckInOutChanged != null) {
          onCheckInOutChanged!(true);
        }
      }).catchError((error) {
        print("Failed to check in: $error");
      });
    } else {
      print("User is not at an office location.");
    }
  }

  Future<void> checkOut(User user, LatLng location) async {
    String officeName = isOffice(location);
    if (officeName.isEmpty) {
      String userName = await getUserName(user.uid);

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference checkins = firestore.collection('checkins');

      QuerySnapshot checkInSnapshot = await checkins
          .where('user_id', isEqualTo: user.uid)
          .orderBy('check_in_time', descending: true)
          .limit(1)
          .get();

      if (checkInSnapshot.docs.isNotEmpty) {
        var checkInDoc = checkInSnapshot.docs.first;
        String checkInDocId = checkInDoc.id;

        await checkInDoc.reference.update({
          'status': 'checked_out',
          'check_out_time': Timestamp.now(),
        }).then((value) {
          CollectionReference checkouts = firestore.collection('checkouts');
          checkouts.add({
            'user_id': user.uid,
            'name': userName,
            'office_name': officeName,
            'check_out_time': Timestamp.now(),
            'latitude': location.latitude,
            'longitude': location.longitude,
            'status': 'checked_out',
          }).then((value) {
            if (onCheckInOutChanged != null) {
              onCheckInOutChanged!(false);
            }
          }).catchError((error) {
            print("Failed to check out: $error");
          });
        }).catchError((error) {
          print("Failed to update check-in status: $error");
        });
      } else {
        print("No check-in record found for the user.");
      }
    } else {
      print("User is not at an office location.");
    }
  }

  Future<void> handleCheckInOut(User user, LatLng currentLocation) async {
    await fetchOfficeLocations(); // Fetch office locations before handling check-in/out

    bool isCheckedIn = await getCheckInStatus(user.uid);

    if (isCheckedIn && isOffice(currentLocation).isEmpty) {
      await checkOut(user, currentLocation);
    } else if (!isCheckedIn && isOffice(currentLocation).isNotEmpty) {
      await checkIn(user, currentLocation);
    } else {
      print("No operation needed.");
    }
  }
}

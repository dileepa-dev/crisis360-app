import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class DashboardController extends GetxController {
  final RxString userName = ''.obs;
  final RxBool isLoading = true.obs;

  late GoogleMapController mapController;

  final Location _location = Location();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  RxSet<Marker> markers = <Marker>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserName();
    initLocation();
    loadDummyRiskLocations();
  }

  /// 👤 Fetch user name
  Future<void> fetchUserName() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        userName.value = 'Guest';
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      userName.value = doc.exists ? (doc['name'] ?? 'User') : 'User';
    } catch (e) {
      userName.value = 'Error';
    } finally {
      isLoading.value = false;
    }
  }

  /// 📍 INIT LOCATION (FIXED)
  Future<void> initLocation() async {
    try {
      // 1️⃣ Check service
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      // 2️⃣ Check permission
      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) return;
      }

      // 3️⃣ Get location
      final loc = await _location.getLocation();

      if (loc.latitude == null || loc.longitude == null) return;

      currentLocation.value = LatLng(
        loc.latitude!,
        loc.longitude!,
      );

      // 4️⃣ Add user marker
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: currentLocation.value!,
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    } catch (e) {
      print('Location error: $e');
    }
  }

  /// 🧪 Dummy risk locations
  void loadDummyRiskLocations() {
    final dummyData = [
      {'lat': 6.9275, 'lng': 79.8620, 'risk': 'HIGH'},
      {'lat': 6.9250, 'lng': 79.8580, 'risk': 'MEDIUM'},
      {'lat': 6.9300, 'lng': 79.8650, 'risk': 'LOW'},
    ];

    for (var item in dummyData) {
      BitmapDescriptor color;

      switch (item['risk']) {
        case 'HIGH':
          color = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          );
          break;
        case 'MEDIUM':
          color = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          );
          break;
        default:
          color = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
      }

      markers.add(
        Marker(
          markerId: MarkerId('${item['lat']}_${item['lng']}'),
          position: LatLng(item['lat'] as double , item['lng'] as double),
          icon: color,
          infoWindow: InfoWindow(title: 'Risk: ${item['risk']}'),
        ),
      );
    }
  }

  /// ➕ Zoom in
  void zoomIn() {
    mapController.animateCamera(CameraUpdate.zoomIn());
  }

  /// ➖ Zoom out
  void zoomOut() {
    mapController.animateCamera(CameraUpdate.zoomOut());
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final RxString userName = ''.obs;
  final RxBool isLoading = true.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        userName.value = 'Guest';
        isLoading.value = false;
        return;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        userName.value = doc['name'] ?? 'Unknown User';
      } else {
        userName.value = 'Unknown User';
      }
    } catch (e) {
      userName.value = 'Error loading user';
      print('Error fetching user name: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

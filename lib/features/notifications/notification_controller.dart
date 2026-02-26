import 'dart:async';
import 'package:crisis360app/core/utils/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationsController extends ChangeNotifier {
  final RxString district;
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;
  Timer? _timer;

  NotificationsController({required this.district}) {
    fetchNotifications();

    // Refresh notifications every 10s
    _timer = Timer.periodic(Duration(seconds: 10), (_) {
      fetchNotifications();
    });
  }

  Future<void> fetchNotifications() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoints.authEndpoints.getNotifications}/${district.value}',
        ),
      );
      print("District: ${district.value}");
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        notifications = data.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        print("Failed to load notifications");
      }
    } catch (e) {
      print("Error fetching notifications: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  void showSafetyPopup(BuildContext context, Map<String, dynamic> notif) {
    final TextEditingController messageController = TextEditingController();

    String? isSafe;
    String? peopleCount;
    String? needHelp;
    double severityLevel = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Center(
                      child: Text(
                        "Safety Confirmation",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 1️⃣ Are you safe?
                    const Text("Are you safe right now?"),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile(
                            title: const Text("Yes"),
                            value: "YES",
                            groupValue: isSafe,
                            onChanged: (value) {
                              setState(() => isSafe = value.toString());
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile(
                            title: const Text("No"),
                            value: "NO",
                            groupValue: isSafe,
                            onChanged: (value) {
                              setState(() => isSafe = value.toString());
                            },
                          ),
                        ),
                      ],
                    ),

                    /// 2️⃣ People count
                    const SizedBox(height: 10),
                    const Text("How many people are with you?"),
                    DropdownButtonFormField<String>(
                      value: peopleCount,
                      items: const [
                        DropdownMenuItem(value: "1", child: Text("1")),
                        DropdownMenuItem(value: "2-5", child: Text("2-5")),
                        DropdownMenuItem(value: "6-10", child: Text("6-10")),
                        DropdownMenuItem(value: "10+", child: Text("10+")),
                      ],
                      onChanged: (value) {
                        setState(() => peopleCount = value);
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),

                    /// 3️⃣ Need help?
                    const SizedBox(height: 15),
                    const Text("Do you need emergency assistance?"),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile(
                            title: const Text("Yes"),
                            value: "YES",
                            groupValue: needHelp,
                            onChanged: (value) {
                              setState(() => needHelp = value.toString());
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile(
                            title: const Text("No"),
                            value: "NO",
                            groupValue: needHelp,
                            onChanged: (value) {
                              setState(() => needHelp = value.toString());
                            },
                          ),
                        ),
                      ],
                    ),

                    /// 4️⃣ Severity Rating
                    const SizedBox(height: 15),
                    const Text("Rate the severity around you (1-5)"),
                    Slider(
                      value: severityLevel,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: severityLevel.toString(),
                      onChanged: (value) {
                        setState(() => severityLevel = value);
                      },
                    ),

                    /// 5️⃣ Text field
                    const SizedBox(height: 15),
                    const Text("Describe your situation"),
                    TextField(
                      controller: messageController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "Describe what is happening...",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () async {
                        final notificationId =
                            notif['id']?.toString() ?? '';

                        await submitSafetyStatus(
                          messageController.text,
                          notificationId,
                          isSafe,
                          peopleCount,
                          needHelp,
                          severityLevel,
                        );

                        Navigator.pop(context);
                      },
                      child: const Text("Submit"),
                    ),

                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Future<void> submitSafetyStatus(
      String message,
      String notificationId,
      String? isSafe,
      String? peopleCount,
      String? needHelp,
      double severityLevel,
      ) async {
    final position = await getUserLocation();

    final response = await http.post(
      Uri.parse("http://YOUR_BACKEND_URL/api/safety/submit"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "notificationId": notificationId,
        "district": district.value,
        "message": message,
        "isSafe": isSafe,
        "peopleCount": peopleCount,
        "needHelp": needHelp,
        "severityLevel": severityLevel,
        "latitude": position.latitude,
        "longitude": position.longitude,
      }),
    );

    if (response.statusCode == 200) {
      print("Safety status submitted successfully");
    }
  }
  Future<Position> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
  // Cancel the timer when the controller is disposed
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
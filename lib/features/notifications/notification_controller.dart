import 'dart:async';
import 'dart:convert';

import 'package:crisis360app/core/utils/api_endpoints.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:http/http.dart' as http;

class NotificationsController extends ChangeNotifier {
  final RxString district;

  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;
  bool _isFetching = false;

  Timer? _timer;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userId;

  bool _isDisposed = false;

  NotificationsController({required this.district}) {
    fetchLoggedUser();
    fetchNotifications();

    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_isDisposed) {
        fetchNotifications();
      }
    });
  }

  void fetchLoggedUser() {
    final user = _auth.currentUser;

    if (user != null) {
      userId = user.uid;
      debugPrint("Logged user ID: $userId");
    } else {
      debugPrint("No logged user found");
    }
  }

  Future<void> fetchNotifications() async {
    if (_isDisposed || _isFetching) return;

    _isFetching = true;
    isLoading = true;
    _safeNotify();

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoints.authEndpoints.getNotifications}/${district.value}',
        ),
      );

      if (_isDisposed) return;

      debugPrint("District: ${district.value}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        notifications = data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        debugPrint("Failed to load notifications: ${response.statusCode}");
      }
    } catch (e) {
      if (!_isDisposed) {
        debugPrint("Error fetching notifications: $e");
      }
    } finally {
      _isFetching = false;

      if (_isDisposed) return;

      isLoading = false;
      _safeNotify();
    }
  }

  void showSafetyPopup(BuildContext parentContext, Map<String, dynamic> notif) {
    final TextEditingController messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String? isSafe;
    String? peopleCount;
    String? needHelp;
    double severityLevel = 3;

    String? isSafeError;
    String? needHelpError;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            Future<void> validateAndSubmit() async {
              if (isSubmitting) return;

              final isFormValid = formKey.currentState?.validate() ?? false;

              isSafeError = (isSafe == null) ? "Please select Yes or No" : null;
              needHelpError =
              (needHelp == null) ? "Please select Yes or No" : null;

              setState(() {});

              if (!isFormValid || isSafeError != null || needHelpError != null) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text("Please fill all required fields"),
                  ),
                );
                return;
              }

              final notificationId = notif['id']?.toString() ?? '';

              setState(() {
                isSubmitting = true;
              });

              final success = await submitSafetyStatus(
                sheetContext,
                messageController.text.trim(),
                notificationId,
                isSafe,
                peopleCount,
                needHelp,
                severityLevel,
              );

              if (sheetContext.mounted) {
                setState(() {
                  isSubmitting = false;
                });
              }

              if (success && sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Center(
                        child: Text(
                          "Safety Confirmation",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text("Are you safe right now?"),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Yes"),
                              value: "YES",
                              groupValue: isSafe,
                              onChanged: (value) => setState(() {
                                isSafe = value;
                                isSafeError = null;
                              }),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("No"),
                              value: "NO",
                              groupValue: isSafe,
                              onChanged: (value) => setState(() {
                                isSafe = value;
                                isSafeError = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                      if (isSafeError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
                          child: Text(
                            isSafeError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),

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
                        onChanged: (value) => setState(() => peopleCount = value),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select people count";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),
                      const Text("Do you need emergency assistance?"),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Yes"),
                              value: "YES",
                              groupValue: needHelp,
                              onChanged: (value) => setState(() {
                                needHelp = value;
                                needHelpError = null;
                              }),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("No"),
                              value: "NO",
                              groupValue: needHelp,
                              onChanged: (value) => setState(() {
                                needHelp = value;
                                needHelpError = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                      if (needHelpError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
                          child: Text(
                            needHelpError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 15),
                      const Text("Rate the severity around you (1-5)"),
                      Slider(
                        value: severityLevel,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: severityLevel.toStringAsFixed(0),
                        onChanged: (value) =>
                            setState(() => severityLevel = value),
                      ),

                      const SizedBox(height: 15),
                      const Text("Describe your situation"),
                      TextFormField(
                        controller: messageController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Describe what is happening...",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? "";
                          if (text.isEmpty) return "Message cannot be empty";
                          if (text.length < 5) {
                            return "Please enter at least 5 characters";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 25),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: isSubmitting ? null : validateAndSubmit,
                        child: Text(
                          isSubmitting ? "Submitting..." : "Submit",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      messageController.dispose();
    });
  }

  Future<bool> submitSafetyStatus(
      BuildContext context,
      String message,
      String notificationId,
      String? isSafe,
      String? peopleCount,
      String? needHelp,
      double severityLevel,
      ) async {
    try {
      _showLoader(context);

      final position = await getUserLocation();

      final response = await http.post(
        Uri.parse(ApiEndpoints.authEndpoints.submitSafetyStatus),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
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

      _closeLoader(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackbar(
          context,
          "Safety status submitted successfully ✅",
          Colors.green,
        );
        return true;
      } else {
        _showSnackbar(
          context,
          "Submission failed ❌ (${response.statusCode})",
          Colors.red,
        );
        return false;
      }
    } catch (e) {
      _closeLoader(context);
      _showSnackbar(context, "Error: ${e.toString()} ❌", Colors.red);
      return false;
    }
  }

  void _showLoader(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void _closeLoader(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<Position> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception("Location permission denied");
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Location permission permanently denied. Please enable it from settings",
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    DelightToastBar(
      builder: (context) {
        return ToastCard(
          title: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.0,
              color: Colors.white,
            ),
          ),
          color: color,
        );
      },
      position: DelightSnackbarPosition.top,
      autoDismiss: true,
    ).show(context);
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
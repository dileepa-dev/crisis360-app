import 'dart:async';
import 'dart:convert';

import 'package:crisis360app/core/utils/api_endpoints.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:http/http.dart' as http;

class NotificationsController extends ChangeNotifier {
  final RxString district;

  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;
  bool isRefreshingOverlay = false;
  bool _isFetching = false;
  bool _isDisposed = false;

  Timer? _timer;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userId;

  NotificationsController({required this.district}) {
    fetchLoggedUser();
    fetchNotifications();

    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_isDisposed) {
        fetchNotifications(showOverlay: false);
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

  Future<void> refreshNotificationsManually() async {
    await fetchNotifications(showOverlay: true);
  }

  Future<void> fetchNotifications({bool showOverlay = false}) async {
    if (_isDisposed || _isFetching) return;

    _isFetching = true;
    isLoading = true;
    isRefreshingOverlay = showOverlay;
    _safeNotify();

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoints.authEndpoints.getNotifications}/${district.value}',
        ),
      );

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        notifications = data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        // newest first
        notifications.sort((a, b) {
          final dateA = _parseNotificationDate(a['timestamp']);
          final dateB = _parseNotificationDate(b['timestamp']);
          return dateB.compareTo(dateA);
        });
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
      isRefreshingOverlay = false;
      _safeNotify();
    }
  }

  DateTime _parseNotificationDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);

    final text = value.toString().trim();
    if (text.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    try {
      return DateTime.parse(text).toLocal();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String formatNotificationDate(dynamic value) {
    final date = _parseNotificationDate(value);

    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$year/$month/$day $hour:$minute';
  }

  void showSafetyPopup(BuildContext parentContext, Map<String, dynamic> notif) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController messageController = TextEditingController();

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
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            Future<void> validateAndSubmit() async {
              if (isSubmitting) return;

              final isFormValid = formKey.currentState?.validate() ?? false;

              isSafeError = isSafe == null ? "Please select Yes or No" : null;
              needHelpError =
              needHelp == null ? "Please select Yes or No" : null;

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

              if (!sheetContext.mounted) return;

              setState(() {
                isSubmitting = false;
              });

              if (success && sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 18,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                ),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: SingleChildScrollView(
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Container(
                                  width: 42,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      "Safety Confirmation",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFF3F3),
                                      Color(0xFFFFFAFA),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.10),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.health_and_safety_outlined,
                                        color: Colors.red,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Please provide your current status.",
                                            style: TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              _sectionTitle("Are you safe right now?"),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      contentPadding: EdgeInsets.zero,
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
                                      contentPadding: EdgeInsets.zero,
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
                                  padding:
                                  const EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(
                                    isSafeError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 8),
                              _sectionTitle("How many people are with you?"),
                              DropdownButtonFormField<String>(
                                value: peopleCount,
                                items: const [
                                  DropdownMenuItem(
                                    value: "1",
                                    child: Text("1"),
                                  ),
                                  DropdownMenuItem(
                                    value: "2-5",
                                    child: Text("2-5"),
                                  ),
                                  DropdownMenuItem(
                                    value: "6-10",
                                    child: Text("6-10"),
                                  ),
                                  DropdownMenuItem(
                                    value: "10+",
                                    child: Text("10+"),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => peopleCount = value),
                                decoration:
                                _inputDecoration("Select people count"),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please select people count";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),
                              _sectionTitle(
                                "Do you need emergency assistance?",
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      contentPadding: EdgeInsets.zero,
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
                                      contentPadding: EdgeInsets.zero,
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
                                  padding:
                                  const EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(
                                    needHelpError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 12),
                              _sectionTitle(
                                "Rate the severity around you (1-5)",
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                  Border.all(color: Colors.grey.shade200),
                                ),
                                child: Slider(
                                  value: severityLevel,
                                  min: 1,
                                  max: 5,
                                  divisions: 4,
                                  label: severityLevel.toStringAsFixed(0),
                                  activeColor: Colors.red,
                                  onChanged: (value) =>
                                      setState(() => severityLevel = value),
                                ),
                              ),

                              const SizedBox(height: 16),
                              _sectionTitle("Describe your situation"),
                              TextFormField(
                                controller: messageController,
                                maxLines: 4,
                                decoration: _inputDecoration(
                                  "This will be ranked using AI...",
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? "";
                                  if (text.isEmpty) {
                                    return "Message cannot be empty";
                                  }
                                  if (text.length < 5) {
                                    return "Please enter at least 5 characters";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: isSubmitting
                                          ? null
                                          : () =>
                                          Navigator.of(sheetContext).pop(),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize:
                                        const Size(double.infinity, 54),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(18),
                                        ),
                                        side: BorderSide(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        minimumSize:
                                        const Size(double.infinity, 54),
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(18),
                                        ),
                                      ),
                                      onPressed: isSubmitting
                                          ? null
                                          : validateAndSubmit,
                                      child: Text(
                                        isSubmitting
                                            ? "Submitting..."
                                            : "Submit",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isSubmitting)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(20)),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 22,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 14),
                                    Text("Submitting..."),
                                  ],
                                ),
                              ),
                            ),
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
    );
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          "Success",
          "Safety status submitted successfully",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        Get.snackbar(
          "Fail",
          "Submission failed (${response.statusCode})",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 2),
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        "Fail",
        "Submission failed Error: ${e.toString()}",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      );
      return false;
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
              fontSize: 14,
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
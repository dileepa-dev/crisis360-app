import 'package:crisis360app/features/dashboard/dashboard_controller.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 710,
      left: 20,
      right: 20,
      child: Center(
        child: SizedBox(
          width: 250,
          height: 60,
          child: ElevatedButton(
            onPressed: () async {
              _showLogoutConfirmation(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8162FF),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _showLogoutConfirmation(BuildContext context) {
  final DashboardController dashboardController = DashboardController();
  showDialog(
    context: context,
    barrierDismissible: false, // user must choose
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
            },
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // close dialog first
              await dashboardController.logout(context);
            },
            child: const Text(
              "Yes",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );
}


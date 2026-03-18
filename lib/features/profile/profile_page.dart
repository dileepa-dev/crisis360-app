import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                child: Text(
                  controller.userName.isNotEmpty
                      ? controller.userName.value[0]
                      : '?',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                controller.userName.value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w500),
              ),

              Text(
                controller.email.value,
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 10),

              /// 🔹 Show Role
              Text(
                controller.role.value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                ),
              ),

              const SizedBox(height: 30),

              /// 🔥 Send Safety Notification (ADMIN + SUPER_ADMIN)
              if (controller.isAdmin || controller.isSuperAdmin)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      _showSafetyDialog(context, controller);
                    },
                    child: const Text("Send Safety Notification"),
                  ),
                ),

              const SizedBox(height: 15),

              /// 🔥 Create User (SUPER_ADMIN ONLY)
              if (controller.isSuperAdmin)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    onPressed: () {
                      _showCreateUserDialog(context, controller);
                    },
                    child: const Text("Create User"),
                  ),
                ),

              const Spacer(),

              /// 🔴 Logout
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red),
                  onPressed: () =>
                      _showLogoutConfirmation(context, controller),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showLogoutConfirmation(BuildContext context,
      ProfileController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await controller.logout(context);
              },
              child: const Text("Yes",
                  style: TextStyle(color: Colors.red)
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateUserDialog(BuildContext context,
      ProfileController controller) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final RxString selectedProvince = ''.obs;
    final RxString selectedDistrict = ''.obs;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Admin User"),
          content: SingleChildScrollView(
            child: Obx(
                  () =>
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: selectedProvince.value.isEmpty
                            ? null
                            : selectedProvince.value,
                        decoration: const InputDecoration(
                          labelText: "Select Province",
                          border: OutlineInputBorder(),
                        ),
                        items: controller.provinces
                            .map(
                              (province) =>
                              DropdownMenuItem(
                                value: province,
                                child: Text(province),
                              ),
                        )
                            .toList(),
                        onChanged: (value) {
                          selectedProvince.value = value!;
                          selectedDistrict.value = '';
                        },
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: selectedDistrict.value.isEmpty
                            ? null
                            : selectedDistrict.value,
                        decoration: const InputDecoration(
                          labelText: "Select District",
                          border: OutlineInputBorder(),
                        ),
                        items: selectedProvince.value.isEmpty
                            ? []
                            : controller
                            .districtsByProvince[selectedProvince.value]!
                            .map(
                              (district) =>
                              DropdownMenuItem(
                                value: district,
                                child: Text(district),
                              ),
                        )
                            .toList(),
                        onChanged: (value) {
                          selectedDistrict.value = value!;
                        },
                      ),
                    ],
                  ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text
                    .trim()
                    .isEmpty ||
                    emailController.text
                        .trim()
                        .isEmpty ||
                    passwordController.text
                        .trim()
                        .isEmpty ||
                    selectedProvince.value.isEmpty ||
                    selectedDistrict.value.isEmpty) {
                  Get.snackbar("Error", "Please fill all fields");
                  return;
                }

                Navigator.pop(context);

                await controller.createAdminUser(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                  province: selectedProvince.value,
                  district: selectedDistrict.value,
                );
              },
              child: const Text("Create Admin"),
            ),
          ],
        );
      },
    );
  }

  void _showSafetyDialog(BuildContext context, ProfileController controller) {
    controller.selectedProvince.value = '';
    controller.selectedDistrict.value = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Send Safety Confirmation"),
          content: Obx(() =>
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// Province Dropdown
                  DropdownButtonFormField<String>(
                    value: controller.selectedProvince.value.isEmpty
                        ? null
                        : controller.selectedProvince.value,
                    decoration: const InputDecoration(
                      labelText: "Select Province",
                      border: OutlineInputBorder(),
                    ),
                    items: controller.provinces
                        .map((province) =>
                        DropdownMenuItem(
                          value: province,
                          child: Text(province),
                        ))
                        .toList(),
                    onChanged: (value) {
                      controller.selectedProvince.value = value!;
                      controller.selectedDistrict.value = '';
                    },
                  ),

                  const SizedBox(height: 15),

                  /// District Dropdown
                  DropdownButtonFormField<String>(
                    value: controller.selectedDistrict.value.isEmpty
                        ? null
                        : controller.selectedDistrict.value,
                    decoration: const InputDecoration(
                      labelText: "Select District",
                      border: OutlineInputBorder(),
                    ),
                    items: controller.selectedProvince.value.isEmpty
                        ? []
                        : controller
                        .districtsByProvince[
                    controller.selectedProvince.value]!
                        .map((district) =>
                        DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        ))
                        .toList(),
                    onChanged: (value) {
                      controller.selectedDistrict.value = value!;
                    },
                  ),
                ],
              )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.selectedProvince.value.isEmpty ||
                    controller.selectedDistrict.value.isEmpty) {
                  Get.snackbar("Error", "Please select province and district");
                  return;
                }

                Navigator.pop(context);

                await controller.sendSafetyNotification(
                  controller.selectedProvince.value,
                  controller.selectedDistrict.value,
                );

                Get.snackbar(
                  "Success",
                  "Safety notification sent successfully",
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }
}
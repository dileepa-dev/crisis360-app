import 'package:flutter/material.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'register_controller.dart';

void main() {
  runApp(const MaterialApp(
    home: RegisterPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final RegisterController registerController = RegisterController();

  String? selectedProvince;
  String? selectedDistrict;

  // Sri Lankan provinces
  final List<String> provinces = [
    'Central', 'Eastern', 'North Central', 'Northern',
    'North Western', 'Sabaragamuwa', 'Southern', 'Uva', 'Western'
  ];

  // Districts by province
  final Map<String, List<String>> districts = {
    'Central': ['Kandy', 'Matale', 'Nuwara Eliya'],
    'Eastern': ['Ampara', 'Batticaloa', 'Trincomalee'],
    'North Central': ['Anuradhapura', 'Polonnaruwa'],
    'Northern': ['Jaffna', 'Kilinochchi', 'Mannar', 'Mullaitivu', 'Vavuniya'],
    'North Western': ['Kurunegala', 'Puttalam'],
    'Sabaragamuwa': ['Kegalle', 'Ratnapura'],
    'Southern': ['Galle', 'Matara', 'Hambantota'],
    'Uva': ['Badulla', 'Moneragala'],
    'Western': ['Colombo', 'Gampaha', 'Kalutara'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        color: Colors.white,
        child: Stack(
          children: [
            const LogoAndTitle(),
            RegisterPageImage(),
            RegisterInputFields(
              nameController: nameController,
              emailController: emailController,
              passwordController: passwordController,
              confirmPasswordController: confirmPasswordController,
              selectedProvince: selectedProvince,
              selectedDistrict: selectedDistrict,
              provinces: provinces,
              districts: districts,
              onProvinceChanged: (val) {
                setState(() {
                  selectedProvince = val;
                  selectedDistrict = null;
                });
              },
              onDistrictChanged: (val) {
                setState(() {
                  selectedDistrict = val;
                });
              },
            ),
            RegisterButton(
              nameController: nameController,
              emailController: emailController,
              passwordController: passwordController,
              confirmPasswordController: confirmPasswordController,
              selectedProvince: selectedProvince,
              selectedDistrict: selectedDistrict,
              registerController: registerController,
            ),
            const AlreadyHaveAccountText(),
          ],
        ),
      ),
    );
  }
}

/* ---------------- LOGO + TITLE ---------------- */

class LogoAndTitle extends StatelessWidget {
  const LogoAndTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: MediaQuery.of(context).size.width * 0.17,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo/logo.png',
            width: 90,
          ),
          const Text(
            'Crisis360',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- INPUT FIELDS ---------------- */

class RegisterInputFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? selectedProvince;
  final String? selectedDistrict;
  final List<String> provinces;
  final Map<String, List<String>> districts;
  final ValueChanged<String?> onProvinceChanged;
  final ValueChanged<String?> onDistrictChanged;

  const RegisterInputFields({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.selectedProvince,
    required this.selectedDistrict,
    required this.provinces,
    required this.districts,
    required this.onProvinceChanged,
    required this.onDistrictChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 260,
      left: 20,
      right: 20,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          // Province dropdown
          DropdownButtonFormField<String>(
            value: selectedProvince,
            decoration: const InputDecoration(
              labelText: 'Province',
              border: OutlineInputBorder(),
            ),
            items: provinces
                .map((province) => DropdownMenuItem(
              value: province,
              child: Text(province),
            ))
                .toList(),
            onChanged: onProvinceChanged,
          ),
          const SizedBox(height: 20),
          // District dropdown
          DropdownButtonFormField<String>(
            value: selectedDistrict,
            decoration: const InputDecoration(
              labelText: 'District',
              border: OutlineInputBorder(),
            ),
            items: selectedProvince == null
                ? []
                : districts[selectedProvince]!
                .map((district) => DropdownMenuItem(
              value: district,
              child: Text(district),
            ))
                .toList(),
            onChanged: onDistrictChanged,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- REGISTER BUTTON ---------------- */

class RegisterButton extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? selectedProvince;
  final String? selectedDistrict;
  final RegisterController registerController;

  const RegisterButton({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.selectedProvince,
    required this.selectedDistrict,
    required this.registerController,
  });

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
              final name = nameController.text;
              final email = emailController.text;
              final password = passwordController.text;
              final confirmPassword = confirmPasswordController.text;

              if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || selectedProvince == null || selectedDistrict == null) {
                _showToast(context, "Please fill all fields", Colors.red);
                return;
              }

              if (password != confirmPassword) {
                _showToast(context, "Passwords do not match", Colors.red);
                return;
              }

              try {
                await registerController.register(
                  name,
                  email,
                  selectedProvince!,
                  selectedDistrict!,
                  password,
                );
                _showToast(context, "Registration successful", const Color(0xFF2BED9D));
                Navigator.pushNamed(context, '/login');
              } catch (e) {
                _showToast(context, registerController.errorMessage?? "Registration failed", const Color(0xFFBF7066));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8162FF),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            child: const Text(
              'Register',
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

  void _showToast(BuildContext context, String message, Color color) {
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
}

/* ---------------- ALREADY HAVE ACCOUNT ---------------- */

class AlreadyHaveAccountText extends StatelessWidget {
  const AlreadyHaveAccountText({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: RichText(
            text: const TextSpan(
              text: "Already have an account? ",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
              children: [
                TextSpan(
                  text: "Login",
                  style: TextStyle(
                    color: Color(0xFF8162FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPageImage extends StatelessWidget {
  const RegisterPageImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60, // below logo & title
      left: 0,
      right: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/register_page_image.jpg',
            width: 200,
            fit: BoxFit.contain,
          )
        ],
      ),
    );
  }
}

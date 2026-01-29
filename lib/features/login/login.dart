import 'package:flutter/material.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'login_controller.dart';

void main() {
  runApp(const MaterialApp(
    home: Login(),
    debugShowCheckedModeBanner: false,
  ));
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final LoginController loginController = LoginController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            const LogoAndTitle(),
            const LoginPageImage(),
            LoginInputFields(
              usernameController: usernameController,
              passwordController: passwordController,
            ),
            LoginButton(
              usernameController: usernameController,
              passwordController: passwordController,
              loginController: loginController,
            ),
            const CreateAccountText(),
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
      top: 10,
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

class LoginInputFields extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const LoginInputFields({
    super.key,
    required this.usernameController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 430.0,
      left: 20.0,
      right: 20.0,
      child: Column(
        children: [
          TextFormField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20.0),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final LoginController loginController;

  const LoginButton({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.loginController,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 580.0,
      left: 20.0,
      right: 20.0,
      child: Center(
        child: SizedBox(
          width: 250.0,
          height: 60.0,
          child: ElevatedButton(
            onPressed: () async {
              final username = usernameController.text;
              final password = passwordController.text;

              if (username.isEmpty) {
                _showSnackbar(context, "Username cannot be empty", Colors.red);
                return;
              }

              if (password.isEmpty) {
                _showSnackbar(context, "Password cannot be empty", Colors.red);
                return;
              }

              try {
                await loginController.login(username, password);
                _showSnackbar(context, "Login success", const Color(0xFF2BED9D));
                Navigator.pushNamed(context, '/navbar');
              } catch (e) {
                _showSnackbar(context, loginController.error ?? "Failed to sign in", const Color(
                    0xFFBF7066));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8162FF),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                fontSize: 20.0,
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
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
}

class LoginPageImage extends StatelessWidget {
  const LoginPageImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 120, // below logo & title
      left: 0,
      right: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/login_page_image.png', // change if needed
            width: 220,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 26), // spacing between image and text
          const Text(
            'Welcome Back !',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.normal,
              color: Colors.black, // adjust color if needed
            ),
          ),
        ],
      ),
    );
  }
}

class CreateAccountText extends StatelessWidget {
  const CreateAccountText({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/register');
          },
          child: RichText(
            text: const TextSpan(
              text: "Don’t have an account? ",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
              children: [
                TextSpan(
                  text: "Create Account",
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
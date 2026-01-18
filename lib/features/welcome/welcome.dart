import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        color: Colors.white,
        child: Center(
          child: Stack(
            children: const [
              LogoAndTitle(),
              ImageCarousel(),
              GetStartedButton(),
            ],
          ),
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
      top: MediaQuery.of(context).size.height * 0.12,
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

/* ---------------- IMAGE CAROUSEL ---------------- */

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _currentIndex = 0;

  final List<String> imageList = [
    'assets/images/welcome_image_1.jpg',
    'assets/images/welcome_image_2.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 280,
      left: 0,
      right: 0,
      child: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 350,
              viewportFraction: 1,
              autoPlay: true,
              onPageChanged: (index, _) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            items: imageList.map((path) {
              return Image.asset(
                path,
                width: double.infinity,
                fit: BoxFit.cover,
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: imageList.asMap().entries.map((entry) {
              return Container(
                width: _currentIndex == entry.key ? 10 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentIndex == entry.key
                      ? const Color(0xFF8162FF)
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/* ---------------- GET STARTED BUTTON ---------------- */

class GetStartedButton extends StatelessWidget {
  const GetStartedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 90,
      left: 40,
      right: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Stay informed and protected during Emergencies!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: 250,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8162FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

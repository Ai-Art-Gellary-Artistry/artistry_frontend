import 'package:artistry/screens/auth/login_screen.dart';
import 'package:artistry/screens/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  _checkUserAndNavigate() async {
    await Future.delayed(const Duration(seconds: 0), () {});

    // 현재 로그인된 사용자 확인
    User? user = FirebaseAuth.instance.currentUser;

    // ignore: use_build_context_synchronously
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            user != null ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
      (route) => false,
    );
  }

  // 화면 넘김 애니메이션 O
  // _navigateToLogin() async {
  //   await Future.delayed(Duration(seconds: 3), () {});
  //   Navigator.of(context).pushReplacement(
  //     MaterialPageRoute(builder: (context) => LoginScreen()),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image.asset(
            //   'assets/logo.png',
            //   width: 100,
            // ),
            Text(
              "Artistry",
              style: TextStyle(
                // color: AppColors.textColor, // 필요하다면 텍스트 색상을 지정하세요
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            )
          ],
        ),
      ),
    );
  }
}

import 'package:artistry/screens/home/widgets/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProPlanScreen extends StatefulWidget {
  const ProPlanScreen({super.key});

  @override
  _ProPlanScreenState createState() => _ProPlanScreenState();
}

class _ProPlanScreenState extends State<ProPlanScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isProPlan = false;
  bool _isLoadingSubscribe = false;
  bool _isLoadingCancel = false;

  String getSignInProvider(User user) {
    for (var provider in user.providerData) {
      if (provider.providerId == 'google.com') {
        return 'Google 계정';
      } else if (provider.providerId == 'github.com') {
        return 'GitHub 계정';
      }
    }
    return '로그인 제공자 알 수 없음';
  }

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    _user = _auth.currentUser;
    if (_user != null) {
      await _checkProPlanStatus();
    }
    setState(() {});
  }

  Future<void> _checkProPlanStatus() async {
    if (_user != null) {
      final docSnapshot =
          await _firestore.collection('users').doc(_user!.uid).get();
      setState(() {
        _isProPlan = docSnapshot.data()?['isProPlan'] ?? false;
      });
    }
  }

  Future<void> _simulateSubscribe() async {
    // Navigator.push(
    //   context,
    //   PageRouteBuilder(
    //     pageBuilder: (context, animation1, animation2) =>
    //         LoadingScreen(text: "결제중입니다"),
    //     transitionDuration: Duration.zero,
    //     reverseTransitionDuration: Duration.zero,
    //   ),
    // );

    setState(() {
      _isLoadingSubscribe = true;
    });
    // 결제 프로세스 시뮬레이션
    await Future.delayed(const Duration(seconds: 2));

    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).set({
        'isProPlan': true,
      }, SetOptions(merge: true));
      await _checkProPlanStatus();
    }
    setState(() {
      _isLoadingSubscribe = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로 플랜 구독이 완료되었습니다!')),
    );
  }

  Future<void> _cancelSubscription() async {
    setState(() {
      _isLoadingCancel = true;
    });
    // 구독 취소 프로세스 시뮬레이션
    await Future.delayed(const Duration(seconds: 2));

    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).set({
        'isProPlan': false,
      }, SetOptions(merge: true));
      await _checkProPlanStatus();
    }
    setState(() {
      _isLoadingCancel = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로 플랜 구독이 취소되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('프로 플랜 구독')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 50,
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 10),
            if (user != null) Text(getSignInProvider(user)),
            const SizedBox(height: 20),
            Text('이름: ${user?.displayName ?? "이름 없음"}'),
            const SizedBox(height: 10),
            Text('이메일: ${user?.email ?? "이메일 없음"}'),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Divider(
                thickness: 1.0,
              ),
            ),
            if (_isProPlan)
              Column(
                children: [
                  const Text('프로 플랜 구독 중입니다.',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 1.2,
                    child: ElevatedButton(
                      onPressed: _isLoadingCancel ? null : _cancelSubscription,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: _isLoadingCancel
                          ? Image.asset(
                              "assets/images/emoji/emoji2.png",
                              width: 35,
                            )
                          : const Text('구독 취소하기'),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Text('베이직 플랜입니다.',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 1.2,
                    child: ElevatedButton(
                      onPressed:
                          _isLoadingSubscribe ? null : _simulateSubscribe,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: _isLoadingSubscribe
                          ? Image.asset(
                              "assets/images/emoji/emoji3.png",
                              width: 35,
                            )
                          : const Text('프로 플랜 구독하기 (월 3,000원)'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

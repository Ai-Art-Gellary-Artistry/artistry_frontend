import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:artistry/screens/auth/login_screen.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

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

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            "계정 삭제",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text("정말로 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "취소",
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text(
                "삭제",
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (!confirmDelete) return;

    try {
      // Delete user's arts from Firestore
      QuerySnapshot artDocs = await FirebaseFirestore.instance
          .collection('arts')
          .where('creatorId', isEqualTo: user.uid)
          .get();

      for (var doc in artDocs.docs) {
        // Delete the image from Firebase Storage
        String imageUrl = doc['imageUrl'];
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();

        // Delete the document from Firestore
        await doc.reference.delete();
      }

      // Delete user document from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Delete the user account
      await user.delete();

      // Sign out
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('계정이 삭제되었습니다.'),
          backgroundColor: Colors.red,
        ),
      );

      // Navigate to LoginScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계정 삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('계정 정보'),
      ),
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
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Divider(
                thickness: 1.0,
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 1.2,
              child: ElevatedButton(
                onPressed: () => _deleteAccount(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('계정 삭제'),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

import 'package:artistry/screens/art/detail_art_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SavedArtScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('저장한 작품'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('savedArts')
            .where('userId', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitSpinningLines(
                color: Colors.black,
                size: 50.0,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('저장한 작품이 없습니다.'));
          }

          // 모든 저장된 작품의 데이터를 한 번에 가져옵니다.
          final savedArtIds =
              snapshot.data!.docs.map((doc) => doc['artId'] as String).toList();

          return FutureBuilder<List<DocumentSnapshot>>(
            future: Future.wait(savedArtIds.map((id) =>
                FirebaseFirestore.instance.collection('arts').doc(id).get())),
            builder: (context, artSnapshot) {
              if (artSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SpinKitSpinningLines(
                    color: Colors.black,
                    size: 50.0,
                  ),
                );
              }

              if (!artSnapshot.hasData || artSnapshot.data!.isEmpty) {
                return const Center(child: Text('저장한 작품을 불러올 수 없습니다.'));
              }

              final artDataList = artSnapshot.data!
                  .where((doc) => doc.exists)
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();

              return ListView.builder(
                itemCount: artDataList.length,
                itemBuilder: (context, index) {
                  final artData = artDataList[index];

                  return ListTile(
                    leading: Image.network(artData['imageUrl'],
                        width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(artData['title']),
                    subtitle: Text(artData['creatorName']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailArtScreen(artData: artData),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

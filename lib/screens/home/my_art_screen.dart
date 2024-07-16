import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artistry/screens/art/detail_art_screen.dart';

class MyArtScreen extends StatefulWidget {
  const MyArtScreen({super.key});

  @override
  State<MyArtScreen> createState() => _MyArtScreenState();
}

class _MyArtScreenState extends State<MyArtScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final List<String> placeholderImages = [
    'assets/images/emoji/emoji1.png',
    'assets/images/emoji/emoji2.png',
    'assets/images/emoji/emoji3.png',
    'assets/images/emoji/emoji4.png',
    'assets/images/emoji/emoji5.png',
    'assets/images/emoji/emoji6.png',
    'assets/images/emoji/emoji7.png',
    'assets/images/emoji/emoji8.png',
    'assets/images/emoji/emoji9.png',
    'assets/images/emoji/emoji10.png',
  ];

  Future<void> _deleteArt(String docId, int index) async {
    final artsCollection = FirebaseFirestore.instance.collection('arts');

    await artsCollection.doc(docId).delete();

    final querySnapshot =
        await artsCollection.orderBy('index').startAfter([index]).get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.update({'index': FieldValue.increment(-1)});
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('My Artworks'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('arts')
            .where('creatorId', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('현재 제작한 작품이 없습니다.'));
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              var randomImage =
                  placeholderImages[Random().nextInt(placeholderImages.length)];

              return GestureDetector(
                onLongPress: () {
                  _deleteArt(doc.id, data['index']);
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailArtScreen(artData: data),
                    ),
                  );
                },
                child: Card(
                  color: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.network(
                          data['imageUrl'] ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            } else {
                              return Center(
                                child: Image.asset(
                                  randomImage,
                                  width: 80,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

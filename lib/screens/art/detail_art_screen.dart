import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

class DetailArtScreen extends StatefulWidget {
  final Map<String, dynamic> artData;

  const DetailArtScreen({Key? key, required this.artData}) : super(key: key);

  @override
  _DetailArtScreenState createState() => _DetailArtScreenState();
}

class _DetailArtScreenState extends State<DetailArtScreen> {
  late Map<String, dynamic> _artData;
  bool _isSaved = false;
  String? _savedDocId;

  @override
  void initState() {
    super.initState();
    _artData = widget.artData;
    _checkIfSaved();
  }

  void _checkIfSaved() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('savedArts')
        .where('userId', isEqualTo: currentUser.uid)
        .where('artId', isEqualTo: _artData['id'])
        .get();

    setState(() {
      _isSaved = querySnapshot.docs.isNotEmpty;
      if (_isSaved) {
        _savedDocId = querySnapshot.docs.first.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUserArt = currentUser?.uid == _artData['creatorId'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Art Detail",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleSaveArtwork,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareArtwork,
          ),
          if (isCurrentUserArt)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteArtwork,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              _artData['imageUrl'] ?? '',
              width: double.infinity,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage:
                          NetworkImage(_artData['creatorPhotoUrl'] ?? ''),
                    ),
                    title: Text(_artData['creatorName'] ?? 'Unknown Artist'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _artData['title'] ?? 'Untitled',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _artData['description'] ?? 'No description',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSaveArtwork() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      if (_isSaved) {
        // 저장
        final docRef =
            await FirebaseFirestore.instance.collection('savedArts').add({
          'userId': currentUser.uid,
          'artId': _artData['id'],
          'savedAt': FieldValue.serverTimestamp(),
        });
        _savedDocId = docRef.id;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('작품이 저장되었습니다.')),
        );
      } else {
        // 저장 취소
        if (_savedDocId != null) {
          await FirebaseFirestore.instance
              .collection('savedArts')
              .doc(_savedDocId)
              .delete();
          _savedDocId = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('작품 저장이 취소되었습니다.')),
          );
        }
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('작업 중 오류가 발생했습니다: $e')),
      );
      // 에러 발생 시 상태를 되돌립니다.
      setState(() {
        _isSaved = !_isSaved;
      });
    }
  }

  Future<void> _shareArtwork() async {
    try {
      // 이미지 URL 가져오기
      final imageUrl = _artData['imageUrl'];

      // 이미지 파일 다운로드
      final response = await http.get(Uri.parse(imageUrl));
      final bytes = response.bodyBytes;

      // 임시 디렉토리에 이미지 파일 저장
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/shared_image.png').create();
      await file.writeAsBytes(bytes);

      // 이미지 파일 공유
      await Share.shareFiles([file.path], text: _artData['title']);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 공유 중 오류가 발생했습니다: $e')),
      );
    }
  }

  void _deleteArtwork() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            "작품 삭제",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          content: const Text("이 작품을 정말 삭제하시겠습니까?"),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "취소",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                "삭제",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _confirmDeleteArtwork();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteArtwork() async {
    try {
      // Firestore에서 문서 삭제
      await FirebaseFirestore.instance
          .collection('arts')
          .doc(_artData['id'])
          .delete();

      // Storage에서 이미지 파일 삭제
      final storageRef =
          FirebaseStorage.instance.refFromURL(_artData['imageUrl']);
      await storageRef.delete();

      // savedArts 컬렉션에서 해당 작품의 저장 기록 삭제
      final savedArtsQuery = await FirebaseFirestore.instance
          .collection('savedArts')
          .where('artId', isEqualTo: _artData['id'])
          .get();

      for (var doc in savedArtsQuery.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('작품이 삭제되었습니다.')),
        );
        Navigator.of(context).pop(); // 상세 화면 닫기
      }
    } catch (e) {
      if (mounted) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('작품 삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artistry/models/art_model.dart';
import 'package:intl/intl.dart'; // 날짜 형식을 사용하기 위해 추가

class AddArtScreen extends StatefulWidget {
  const AddArtScreen({super.key});

  @override
  State<AddArtScreen> createState() => _AddArtScreenState();
}

class _AddArtScreenState extends State<AddArtScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _imageUrl;
  bool _isLoading = false;
  User? _user;
  bool _isProPlan = false;
  int _remainingUploads = 0;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _checkProPlanStatus();
      _checkUploadCount();
    }
  }

  Future<void> _checkProPlanStatus() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();
    setState(() {
      _isProPlan = docSnapshot.data()?['isProPlan'] ?? false;
    });
  }

  Future<void> _checkUploadCount() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('uploads')
        .doc(today)
        .get();

    int maxUploads = _isProPlan ? 5 : 50;
    int count = docSnapshot.data()?['count'] ?? 0;

    setState(() {
      _remainingUploads = maxUploads - count;
    });
  }

  Future<void> _generateImage() async {
    if (_remainingUploads <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오늘의 업로드 한도를 초과했습니다.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/generate-image'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'prompt': _promptController.text,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _imageUrl = result['image_url'];
        });
      } else {
        throw Exception('Failed to generate image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadArt() async {
    if (_imageUrl == null ||
        _titleController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and generate an image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Upload image to Firebase Storage
      final response = await http.get(Uri.parse(_imageUrl!));
      final imageData = response.bodyBytes;
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef
          .child('generated_images/${DateTime.now().toIso8601String()}.png');
      await imageRef.putData(imageData);
      final downloadUrl = await imageRef.getDownloadURL();

      // Create ArtModel
      final art = ArtModel(
        title: _titleController.text,
        description: _descriptionController.text,
        imageUrl: downloadUrl,
        creatorName: user.displayName ?? 'Anonymous',
        creatorPhotoUrl: user.photoURL ?? '',
        creatorId: user.uid,
        index: await _getNextIndex(),
      );

      // Save to Firestore
      final docRef =
          await FirebaseFirestore.instance.collection('arts').add(art.toMap());

      // Update the document with its ID
      await docRef.update({'id': docRef.id});

      // Update upload count
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final uploadsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('uploads')
          .doc(today);

      final docSnapshot = await uploadsRef.get();
      int currentCount = docSnapshot.data()?['count'] ?? 0;

      await uploadsRef
          .set({'count': currentCount + 1}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.black,
          content: Text('갤러리에 작품이 전시되었습니다!'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패!: $e')),
      );
    } finally {
      _checkUploadCount(); // 업데이트된 업로드 횟수를 다시 체크
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<int> _getNextIndex() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('arts')
        .orderBy('index', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return 1;
    } else {
      final lastIndex = querySnapshot.docs.first['index'] as int;
      return lastIndex + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text(
          "예술작품 만들기",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black,
                width: 2.0,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '현재 남은 횟수: $_remainingUploads',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                // 이미지가 들어갈 자리
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Text(
                            '이미지가 여기에 표시됩니다',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '작품 제목',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  cursorColor: Colors.black,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '작품 설명',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  cursorColor: Colors.black,
                  maxLines: 3,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Divider(
                    thickness: 1.0,
                    color: Colors.grey[300],
                  ),
                ),
                TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: '작품의 내용을 상세하게 적어주세요!',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  cursorColor: Colors.black,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _generateImage,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: _isLoading
                        ? Image.asset(
                            "assets/images/emoji/astonished_face.png",
                            width: 35,
                          )
                        : const Text('제작하기'),
                  ),
                ),
                if (_imageUrl != null) ...[
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _uploadArt,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text('갤러리에 올리기'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

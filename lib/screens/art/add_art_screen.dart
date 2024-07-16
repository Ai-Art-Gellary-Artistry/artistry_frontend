import 'dart:convert';
import 'package:artistry/screens/art/widgets/complete_screen.dart';
import 'package:artistry/screens/art/widgets/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artistry/models/art_model.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _isImageGenerated = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _generateImage() async {
    if (_promptController.text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작품 내용은 5자 이상 입력해주세요.')),
      );
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => LoadingScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

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
          _isImageGenerated = true;
        });

        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();

        // LoadingScreen을 닫고 CompleteScreen으로 부드럽게 전환
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const CompleteScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.ease;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );

        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Failed to generate image');
      }
    } catch (e) {
      Navigator.pop(context); // LoadingScreen 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _uploadArt() async {
    if (_imageUrl == null ||
        _titleController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 채우고 다시 눌러주세요.')),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => LoadingScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.black,
          content: Text('갤러리에 작품이 전시되었습니다!'),
        ),
      );
      Navigator.pop(context); // LoadingScreen 닫기
      Navigator.pop(context); // AddArtScreen 닫기
    } catch (e) {
      print(e);
      Navigator.pop(context); // LoadingScreen 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패!: $e')),
      );
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

  void _resetImage() {
    setState(() {
      _isImageGenerated = false;
      _imageUrl = null;
      _titleController.clear();
      _descriptionController.clear();
    });
  }

  void _shareImage() {
    if (_imageUrl != null) {
      Share.share('내가 만든 AI 작품을 확인해보세요!\n$_imageUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 1,
          centerTitle: false,
          title: const Text(
            "예술작품 만들기",
          ),
          actions: _isImageGenerated
              ? [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _shareImage,
                  ),
                ]
              : null,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                ),
                              );
                            }
                          },
                        ),
                      )
                    : const Center(
                        child: Text(
                          '작품이 여기에 표시됩니다',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Divider(
                  thickness: 1.0,
                ),
              ),
              if (!_isImageGenerated) ...[
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
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(50),
                  ],
                  cursorColor: Colors.black,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: ElevatedButton(
                    onPressed: _generateImage,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('제작하기'),
                  ),
                ),
              ],
              if (_isImageGenerated) ...[
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _uploadArt,
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
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _resetImage,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: Colors.black),
                        ),
                      ),
                      child: const Text('다시 제작'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

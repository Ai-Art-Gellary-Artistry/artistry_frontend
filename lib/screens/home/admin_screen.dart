import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('관리자 화면'),
          bottom: TabBar(
            tabs: [
              Tab(text: '숨겨진 작품'),
              Tab(text: '신고된 작품'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHiddenArtworksList(),
            _buildReportedArtworksList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHiddenArtworksList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('arts')
          .where('isHidden', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _buildArtworkListTile(context, doc.id, data, isHidden: true);
          },
        );
      },
    );
  }

  Widget _buildReportedArtworksList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('arts')
          .where('reportCount', isGreaterThan: 0)
          .orderBy('reportCount', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return _buildArtworkListTile(context, doc.id, data,
                isHidden: false);
          },
        );
      },
    );
  }

  Widget _buildArtworkListTile(
      BuildContext context, String docId, Map<String, dynamic> data,
      {required bool isHidden}) {
    return ListTile(
      title: Text(data['title'] ?? 'Untitled'),
      subtitle: Text(
          '${data['creatorName'] ?? 'Unknown Artist'} - 신고 ${data['reportCount'] ?? 0}회'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteArtwork(context, docId),
          ),
          IconButton(
            icon: Icon(isHidden ? Icons.visibility : Icons.visibility_off),
            onPressed: () => _toggleArtworkVisibility(context, docId, isHidden),
          ),
        ],
      ),
    );
  }

  void _deleteArtwork(BuildContext context, String docId) async {
    // 실제 삭제 로직
    await FirebaseFirestore.instance.collection('arts').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('작품이 영구적으로 삭제되었습니다.')),
    );
  }

  void _toggleArtworkVisibility(
      BuildContext context, String docId, bool currentlyHidden) async {
    await FirebaseFirestore.instance
        .collection('arts')
        .doc(docId)
        .update({'isHidden': !currentlyHidden});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(currentlyHidden ? '작품이 복원되었습니다.' : '작품이 숨겨졌습니다.')),
    );
  }
}

class ArtModel {
  final String? id;
  final String title;
  final String description;
  final String imageUrl;
  final String creatorName;
  final String creatorPhotoUrl;
  final String creatorId;
  final int index; // 새로운 인덱스 필드 추가

  ArtModel({
    this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.creatorName,
    required this.creatorPhotoUrl,
    required this.creatorId,
    required this.index, // 생성자에 인덱스 필드 추가
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'creatorName': creatorName,
      'creatorPhotoUrl': creatorPhotoUrl,
      'creatorId': creatorId,
      'index': index, // 인덱스 필드 추가
    };
  }

  factory ArtModel.fromMap(Map<String, dynamic> map) {
    return ArtModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      creatorName: map['creatorName'],
      creatorPhotoUrl: map['creatorPhotoUrl'],
      creatorId: map['creatorId'],
      index: map['index'], // 인덱스 필드 추가
    );
  }
}

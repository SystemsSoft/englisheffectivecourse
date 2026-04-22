class UploadFilteredDto {
  final String title;
  final String? videoName;

  const UploadFilteredDto({
    required this.title,
    this.videoName,
  });

  factory UploadFilteredDto.fromJson(Map<String, dynamic> json) {
    return UploadFilteredDto(
      title: json['title'] as String,
      videoName: json['videoName'] as String?,
    );
  }
}


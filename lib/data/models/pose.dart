class Pose {
  final String name;
  final String imagePath;
  final String audioPath;
  final int duration; // Duration in seconds

  Pose({
    required this.name,
    required this.imagePath,
    required this.audioPath,
    required this.duration,
  });

  // A factory constructor for creating a new Pose instance from a map.
  // This is how we'll parse the JSON.
  factory Pose.fromJson(Map<String, dynamic> json) {
    return Pose(
      name: json['pose_name'] as String,
      imagePath: json['image_path'] as String,
      audioPath: json['audio_path'] as String,
      duration: json['duration_seconds'] as int,
    );
  }
}

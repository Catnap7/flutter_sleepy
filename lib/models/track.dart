class Track {
  final String id;
  final String title;
  final String assetPath;
  final double volumeMultiplier;

  const Track({
    required this.id,
    required this.title,
    required this.assetPath,
    this.volumeMultiplier = 1.0,
  });
}

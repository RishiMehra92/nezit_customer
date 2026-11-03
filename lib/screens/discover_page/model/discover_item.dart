class DiscoverItem {
  final List<List<dynamic>> icon;
  final String label;
  int likes;
  bool isLiked;

  DiscoverItem({
    required this.icon,
    required this.label,
    required this.likes,
    this.isLiked = false,
  });
}

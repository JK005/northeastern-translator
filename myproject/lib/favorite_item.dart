class FavoriteItem {
  final String isan;
  final String thai;

  FavoriteItem({required this.isan, required this.thai});

  String toStorageString() => '$isan|$thai';

  static FavoriteItem fromStorageString(String s) {
    final parts = s.split('|');
    return FavoriteItem(isan: parts[0], thai: parts[1]);
  }
}
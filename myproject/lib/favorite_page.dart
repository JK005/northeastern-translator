import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'favorite_item.dart'; // ไฟล์ model (favorite_item.dart)

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<FavoriteItem> favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favStrings = prefs.getStringList('favorites') ?? [];
    setState(() {
      favorites = favStrings.map(FavoriteItem.fromStorageString).toList();
    });
  }

  Future<void> _removeFavorite(int index) async {
    final prefs = await SharedPreferences.getInstance();
    favorites.removeAt(index);
    final updated = favorites.map((f) => f.toStorageString()).toList();
    await prefs.setStringList('favorites', updated);
    setState(() {});
  }

void _shareFavorite(FavoriteItem item) {
  final text = 'คำอีสาน: ${item.isan}\nคำแปล: ${item.thai}';
  Share.share(text); //แชร์ข้อความจริง
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("รายการคำโปรด")),
      body:
          favorites.isEmpty
              ? const Center(child: Text("ยังไม่มีคำที่บันทึกไว้"))
              : ListView.builder(
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final item = favorites[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(item.isan),
                      subtitle: Text(item.thai),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () => _shareFavorite(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeFavorite(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

class ItemGroup {
  final String name;
  final List<String> categories;

  ItemGroup({required this.name, required this.categories});

  factory ItemGroup.fromJson(Map<String, dynamic> json) {
    return ItemGroup(
      name: json['item_group'] as String,
      categories: List<String>.from(json['item_categories'] as List),
    );
  }
}

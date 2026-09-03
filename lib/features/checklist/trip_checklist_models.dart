/// A single checklist/packing item.
class ChecklistItem {
  ChecklistItem({
    required this.id,
    required this.title,
    required this.category,
    this.isDone = false,
    this.isEssential = false,
  });

  final String id;
  final String title;
  final String category;
  bool isDone;
  final bool isEssential;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'isDone': isDone,
    'isEssential': isEssential,
  };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    category: json['category'] as String? ?? 'Varie',
    isDone: json['isDone'] as bool? ?? false,
    isEssential: json['isEssential'] as bool? ?? false,
  );
}

/// Category grouping for checklist items.
class ChecklistCategory {
  const ChecklistCategory({
    required this.name,
    required this.iconName,
    required this.items,
  });

  final String name;
  final String iconName;
  final List<ChecklistItem> items;
}

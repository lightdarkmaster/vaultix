class DefaultCategory {
  const DefaultCategory(this.name, this.iconKey, this.color);
  final String name;
  final String iconKey;
  final int color; // ARGB
}

class DefaultCategories {
  DefaultCategories._();

  static const otherName = 'Other';

  static const all = <DefaultCategory>[
    DefaultCategory('Social Media', 'social', 0xFF4C8DF6),
    DefaultCategory('Email', 'email', 0xFFE65B65),
    DefaultCategory('Banking', 'bank', 0xFF20B486),
    DefaultCategory('Shopping', 'shopping', 0xFFF4B740),
    DefaultCategory('Work', 'work', 0xFF536DFE),
    DefaultCategory('Entertainment', 'entertainment', 0xFFE8559B),
    DefaultCategory('Gaming', 'gaming', 0xFF7655E8),
    DefaultCategory(otherName, 'other', 0xFF8A8F9E),
  ];

  static final Set<String> names = all.map((c) => c.name).toSet();
}

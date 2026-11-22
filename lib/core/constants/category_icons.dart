import 'package:flutter/material.dart';

/// Category icons are stored in SQLite as string keys and resolved here.
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> all = {
    'social': Icons.groups_rounded,
    'email': Icons.mail_rounded,
    'bank': Icons.account_balance_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'work': Icons.work_rounded,
    'entertainment': Icons.movie_rounded,
    'gaming': Icons.sports_esports_rounded,
    'other': Icons.category_rounded,
    'folder': Icons.folder_rounded,
    'star': Icons.star_rounded,
    'home': Icons.home_rounded,
    'school': Icons.school_rounded,
    'travel': Icons.flight_rounded,
    'health': Icons.favorite_rounded,
    'code': Icons.code_rounded,
    'cloud': Icons.cloud_rounded,
    'phone': Icons.smartphone_rounded,
    'wifi': Icons.wifi_rounded,
    'car': Icons.directions_car_rounded,
    'pets': Icons.pets_rounded,
  };

  static IconData resolve(String key) => all[key] ?? Icons.category_rounded;
}

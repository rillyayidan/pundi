import 'package:flutter/material.dart';

class CategoryModel {
  const CategoryModel({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  final String name;
  final IconData icon;
  final Color color;
  final String type;
}

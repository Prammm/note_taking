import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  bool isPinned = false;

  @HiveField(5)
  int colorValue;

  Color get color => Color(colorValue);
  set color(Color color) => colorValue = color.value;

  Note({
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    int? colorValue,
  }) : colorValue = colorValue ?? Colors.white.value;


}

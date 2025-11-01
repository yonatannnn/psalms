import 'package:equatable/equatable.dart';

class SundayPrayersModel extends Equatable {
  final String userId;
  final Map<int, List<String>> weeklyPrayers; // week number -> list of prayer topics
  final DateTime createdAt;
  final DateTime updatedAt;

  const SundayPrayersModel({
    required this.userId,
    required this.weeklyPrayers,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SundayPrayersModel.fromJson(Map<String, dynamic> json) {
    final weeklyPrayersData = json['weeklyPrayers'] as Map<String, dynamic>;
    final weeklyPrayers = <int, List<String>>{};
    
    weeklyPrayersData.forEach((key, value) {
      weeklyPrayers[int.parse(key)] = List<String>.from(value as List);
    });

    return SundayPrayersModel(
      userId: json['userId'] as String,
      weeklyPrayers: weeklyPrayers,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final weeklyPrayersData = <String, List<String>>{};
    weeklyPrayers.forEach((key, value) {
      weeklyPrayersData[key.toString()] = value;
    });

    return {
      'userId': userId,
      'weeklyPrayers': weeklyPrayersData,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  SundayPrayersModel copyWith({
    String? userId,
    Map<int, List<String>>? weeklyPrayers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SundayPrayersModel(
      userId: userId ?? this.userId,
      weeklyPrayers: weeklyPrayers ?? this.weeklyPrayers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [userId, weeklyPrayers, createdAt, updatedAt];
}

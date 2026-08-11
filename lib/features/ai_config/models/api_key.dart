import 'package:equatable/equatable.dart';

class APIKey extends Equatable {
  final String value;
  final bool isExhausted;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  const APIKey({
    required this.value,
    this.isExhausted = false,
    required this.createdAt,
    this.lastUsedAt,
  });

  APIKey copyWith({
    String? value,
    bool? isExhausted,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return APIKey(
      value: value ?? this.value,
      isExhausted: isExhausted ?? this.isExhausted,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'isExhausted': isExhausted,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  factory APIKey.fromJson(Map<String, dynamic> json) {
    return APIKey(
      value: json['value'],
      isExhausted: json['isExhausted'],
      createdAt: DateTime.parse(json['createdAt']),
      lastUsedAt: json['lastUsedAt'] != null ? DateTime.parse(json['lastUsedAt']) : null,
    );
  }

  @override
  List<Object?> get props => [value, isExhausted, createdAt, lastUsedAt];
}

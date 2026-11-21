import 'package:equatable/equatable.dart';
import 'api_key.dart';

class APIKeyPool extends Equatable {
  final String providerId;
  final List<APIKey> keys;
  final int activeIndex;

  const APIKeyPool({
    required this.providerId,
    required this.keys,
    this.activeIndex = 0,
  });

  APIKey? get activeKey {
    if (keys.isEmpty) return null;
    if (activeIndex >= 0 && activeIndex < keys.length) {
      return keys[activeIndex];
    }
    return null;
  }

  APIKeyPool copyWith({
    String? providerId,
    List<APIKey>? keys,
    int? activeIndex,
  }) {
    return APIKeyPool(
      providerId: providerId ?? this.providerId,
      keys: keys ?? this.keys,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'keys': keys.map((k) => k.toJson()).toList(),
      'activeIndex': activeIndex,
    };
  }

  factory APIKeyPool.fromJson(Map<String, dynamic> json) {
    return APIKeyPool(
      providerId: json['providerId'],
      keys: (json['keys'] as List).map((k) => APIKey.fromJson(k)).toList(),
      activeIndex: json['activeIndex'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [providerId, keys, activeIndex];
}

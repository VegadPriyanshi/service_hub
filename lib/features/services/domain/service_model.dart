
class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.providerId,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.isActive,
    this.createdAt,
  });

  final String id;
  final String providerId;
  final String name;
  final String category;
  final String description;
  final double price;
  final int durationMinutes;
  final bool isActive;
  final DateTime? createdAt;

  factory ServiceModel.fromMap(
      String id,
      Map<String, dynamic> map,
      ) {
    return ServiceModel(
      id: id,
      providerId: map['providerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      durationMinutes: map['durationMinutes'] as int? ?? 60,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as dynamic)?.toDate() as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? providerId,
    String? name,
    String? category,
    String? description,
    double? price,
    int? durationMinutes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

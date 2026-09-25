class MedicineModel {
  final String id;
  final String name;
  final int compartment; // 1 to 6 (S1 is primary hardware compartment)
  final String dosage;
  final String instructions;
  final List<String> times; // ["08:00", "20:00"]
  final List<String> days; // ["Mon", "Tue", "Wed", ...]
  final bool active;
  final DateTime createdAt;

  MedicineModel({
    required this.id,
    required this.name,
    required this.compartment,
    required this.dosage,
    required this.instructions,
    required this.times,
    required this.days,
    this.active = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      compartment: (json['compartment'] ?? 1) as int,
      dosage: (json['dosage'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      times: List<String>.from(json['times'] ?? []),
      days: List<String>.from(json['days'] ?? []),
      active: json['active'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'compartment': compartment,
      'dosage': dosage,
      'instructions': instructions,
      'times': times,
      'days': days,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MedicineModel copyWith({
    String? id,
    String? name,
    int? compartment,
    String? dosage,
    String? instructions,
    List<String>? times,
    List<String>? days,
    bool? active,
    DateTime? createdAt,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      compartment: compartment ?? this.compartment,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      times: times ?? this.times,
      days: days ?? this.days,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

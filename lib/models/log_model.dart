enum EventType { taken, missed, wrongCompartment, unknown }

extension EventTypeExtension on EventType {
  String get rawValue {
    switch (this) {
      case EventType.taken:
        return 'TAKEN';
      case EventType.missed:
        return 'MISSED';
      case EventType.wrongCompartment:
        return 'WRONG_COMPARTMENT';
      default:
        return 'UNKNOWN';
    }
  }

  static EventType fromString(String val) {
    switch (val.toUpperCase()) {
      case 'TAKEN':
        return EventType.taken;
      case 'MISSED':
        return EventType.missed;
      case 'WRONG_COMPARTMENT':
        return EventType.wrongCompartment;
      default:
        return EventType.unknown;
    }
  }
}

class LogModel {
  final String id;
  final int compartment;
  final DateTime timestamp;
  final EventType eventType;
  final String details;

  LogModel({
    required this.id,
    required this.compartment,
    required this.timestamp,
    required this.eventType,
    required this.details,
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      id: (json['id'] ?? '').toString(),
      compartment: (json['compartment'] ?? 1) as int,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      eventType: EventTypeExtension.fromString((json['eventType'] ?? '').toString()),
      details: (json['details'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'compartment': compartment,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType.rawValue,
      'details': details,
    };
  }
}

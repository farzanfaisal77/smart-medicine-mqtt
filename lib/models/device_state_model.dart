class CompartmentStatus {
  final int id;
  final bool isOpen;
  final bool ledOn;
  final String ledColor; // 'OFF', 'GREEN', 'RED', 'BLUE', 'PURPLE', 'PINK', 'WHITE', 'YELLOW', 'CYAN', 'ORANGE'

  CompartmentStatus({
    required this.id,
    required this.isOpen,
    required this.ledOn,
    this.ledColor = 'OFF',
  });

  factory CompartmentStatus.fromMap(Map<String, dynamic> map, [int defaultId = 1]) {
    String color = (map['ledColor'] ?? 'OFF').toString().toUpperCase();
    bool ledOn = map['ledOn'] ?? (color != 'OFF');
    return CompartmentStatus(
      id: (map['id'] ?? defaultId) as int,
      isOpen: map['isOpen'] ?? false,
      ledOn: ledOn,
      ledColor: color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isOpen': isOpen,
      'ledOn': ledOn || ledColor != 'OFF',
      'ledColor': ledColor,
    };
  }
}

class DeviceStateModel {
  final String deviceId;
  final bool isOnline;
  final int batteryLevel;
  final DateTime lastSeen;
  final List<CompartmentStatus> compartmentStatus;
  final String lastEvent;
  final String lastEventDetails;
  final int lastEventCompartment;

  DeviceStateModel({
    required this.deviceId,
    required this.isOnline,
    required this.batteryLevel,
    required this.lastSeen,
    required this.compartmentStatus,
    this.lastEvent = '',
    this.lastEventDetails = '',
    this.lastEventCompartment = 0,
  });

  factory DeviceStateModel.fromJson(Map<String, dynamic> json) {
    List<CompartmentStatus> statusList = [];
    if (json['compartmentStatus'] is List) {
      final rawList = json['compartmentStatus'] as List<dynamic>;
      for (int i = 0; i < 6; i++) {
        if (i < rawList.length && rawList[i] is Map) {
          statusList.add(CompartmentStatus.fromMap(Map<String, dynamic>.from(rawList[i]), i + 1));
        } else {
          statusList.add(CompartmentStatus(id: i + 1, isOpen: false, ledOn: false, ledColor: 'OFF'));
        }
      }
    } else {
      statusList = List.generate(
        6,
        (index) => CompartmentStatus(id: index + 1, isOpen: false, ledOn: false, ledColor: 'OFF'),
      );
    }

    return DeviceStateModel(
      deviceId: (json['deviceId'] ?? 'ESP32_001').toString(),
      isOnline: json['isOnline'] ?? false,
      batteryLevel: (json['batteryLevel'] ?? 100) as int,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString()) ?? DateTime.now()
          : DateTime.now(),
      compartmentStatus: statusList,
      lastEvent: (json['lastEvent'] ?? '').toString(),
      lastEventDetails: (json['lastEventDetails'] ?? '').toString(),
      lastEventCompartment: (json['lastEventCompartment'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'isOnline': isOnline,
      'batteryLevel': batteryLevel,
      'lastSeen': lastSeen.toIso8601String(),
      'compartmentStatus': compartmentStatus.map((c) => c.toMap()).toList(),
      'lastEvent': lastEvent,
      'lastEventDetails': lastEventDetails,
      'lastEventCompartment': lastEventCompartment,
    };
  }
}

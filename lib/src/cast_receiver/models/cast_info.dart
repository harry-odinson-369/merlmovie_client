class CastDeviceInfo {
  String appName;
  String deviceName;
  String deviceModel;

  CastDeviceInfo({
    required this.appName,
    required this.deviceName,
    required this.deviceModel,
  });

  factory CastDeviceInfo.fromMap(Map<String, dynamic> map) => CastDeviceInfo(
    appName: map["app_name"] ?? "TV Receiver",
    deviceName: map["device_name"] ?? "",
    deviceModel: map["device_model"] ?? "",
  );

  Map<String, dynamic> toMap() => {
    "app_name": appName,
    "device_name": deviceName,
    "device_model": deviceModel,
  };
}

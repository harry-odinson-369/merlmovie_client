import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InformationHelper {
  static Future<Map<String, dynamic>> get appInfo async {
    final info = await PackageInfo.fromPlatform();
    return {
      "version": info.version,
      "build_number": info.buildNumber,
      "install_store": info.installerStore,
      "app_name": info.appName,
      "package_name": info.packageName,
    };
  }

  static Future<Map<String, dynamic>> get deviceInfo async {
    DeviceInfoPlugin device = DeviceInfoPlugin();
    Map<String, dynamic> deviceInformation = {};
    final devInfo =
        await (Platform.isIOS ? device.iosInfo : device.androidInfo);
    if (devInfo is IosDeviceInfo) {
      deviceInformation["os"] = "iOS";
      deviceInformation["os_version"] = devInfo.systemVersion;
      deviceInformation["is_physical"] = devInfo.isPhysicalDevice;
      deviceInformation["model"] = devInfo.model;
    } else if (devInfo is AndroidDeviceInfo) {
      deviceInformation["os"] = "Android";
      deviceInformation["os_version"] = devInfo.version.release;
      deviceInformation["is_physical"] = devInfo.isPhysicalDevice;
      deviceInformation["model"] = devInfo.model;
    }
    return deviceInformation;
  }

  static Future<String> get xci async {
    String info = json.encode({
      "device_info": await deviceInfo,
      "app_info": await appInfo,
    });
    final encoded = base64.encode(utf8.encode(info));
    return encoded;
  }

  static Future<String> requestUrlWithXCI(String requestUrl) async {
    String xciEncoded = await xci;
    if (requestUrl.contains("?")) {
      return "$requestUrl&__xci__=$xciEncoded";
    } else {
      return "$requestUrl?__xci__=$xciEncoded";
    }
  }
}

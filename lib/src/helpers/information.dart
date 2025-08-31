import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:merlmovie_client/src/models/plugin.dart';
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

  static Future<Map<String, dynamic>> getClientInfo(PluginModel plugin) async {
    return {
      "device_info": await deviceInfo,
      "app_info": await appInfo,
      "plugin_info": plugin.toMap(),
    };
  }

  static Future<String> xci(PluginModel plugin) async {
    String info = json.encode(await getClientInfo(plugin));
    final encoded = base64.encode(utf8.encode(info));
    return encoded;
  }

  static Future<String> requestUrlWithXCI(
    String requestUrl,
    PluginModel plugin,
  ) async {
    String xciEncoded = await xci(plugin);
    if (requestUrl.contains("?")) {
      return "$requestUrl&__xci__=$xciEncoded";
    } else {
      return "$requestUrl?__xci__=$xciEncoded";
    }
  }
}

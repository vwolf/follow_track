import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Request permissions
///
class RequestPermissions {

  /// Request permission for [PermissionGroup.storage]
  ///
  Future requestWritePermissions(PermissionGroup permission) async {

    final List<PermissionGroup> permissions = <PermissionGroup>[permission];
    bool externalStoragePermission = false;
    //bool sdCardPermission = false;

    if (Platform.isAndroid) {
      final Map<PermissionGroup, PermissionStatus> permissionRequestResult = await PermissionHandler().requestPermissions(permissions);
      externalStoragePermission = permissionRequestResult[PermissionGroup.storage ] == PermissionStatus.granted;

      //sdCardPermission = permissionRequestResult[PermissionGroup.photos ] == PermissionStatus.granted;
    }

    return externalStoragePermission;
  }
}
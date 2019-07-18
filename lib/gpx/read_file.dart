import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

/// Read file from local storage
class ReadFile {

  String filePath;
  String contents;

  Future<String> getPath() {
    return _getPath();
  }

  Future<String> _getPath() async {
    try {
      String fPath = await FilePicker.getFilePath(type: FileType.ANY);
      if ( filePath == '') {
        return null;
      }
      print('fPath: ' + fPath);
      return fPath;
    } on Platform catch (e) {
      print("FilePicker Error: $e");
    }

    return null;
  }

  Future<String> readFile(String fp) async {
    try {
      String fileContents = await File(fp).readAsString();
      return fileContents;
    } catch (e) {
      print("File Error $e");
    }

    return null;
  }

  List<String>getWayPointsFiles(String dirPath) {
    List<String> wayPointsFiles = [];
    Directory(dirPath).list(recursive: false, followLinks: false)
        .listen((FileSystemEntity entity) {
          if (path.extension(entity.path) == ".gpx") {
            wayPointsFiles.add(entity.path);
          }
    })
    .onDone(() => {
      this.readWayPoints(wayPointsFiles)

      //return wayPointsFiles;
    });
    return wayPointsFiles;
  }

  readWayPoints(List<String> pathList) {
    return pathList;
  }


}
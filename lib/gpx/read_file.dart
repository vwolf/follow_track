import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
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
}
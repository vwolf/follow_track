import 'dart:io';
import 'dart:async';

import 'package:path_provider/path_provider.dart';
//import 'package:permission_handler/permission_handler.dart'

class LocalFile {

  String fileName;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }


  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  Future<File> writeContent(String contents) async {
    final file = await _localFile;
    return file.writeAsString(contents);
  }

  Future<String> readContent() async {
    try {
      final file = await _localFile;

      String contents = await file.readAsString();
      return contents;
    } catch (e) {
      return "Error";
    }
  }

  Future<File> addTo(String c) async {
    final file = await _localFile;
    var openFile = file.openWrite(mode: FileMode.append);
    
    openFile.close();
  }
}
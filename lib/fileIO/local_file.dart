import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
//import 'package:permission_handler/permission_handler.dart'

class LocalFile {

  String _fileName;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }


  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  /// Write string to file
  Future<File> writeContent(String fileName, String contents) async {
    _fileName = fileName;
    final file = await _localFile;
    bool fileExist = file.existsSync();

    return file.writeAsString(contents);
  }

  /// Read file and return  as string
  Future<String> readContent(String fileName) async {
    _fileName = fileName;
    try {
      final file = await _localFile;
      if (file.existsSync()) {
        String contents = await file.readAsString();
        return contents;
      } else {
        return ("No file $fileName");
      }

    } catch (e) {
      return "Error";
    }
  }


  Future<File> addTo(String c) async {
    final file = await _localFile;
    var openFile = file.openWrite(mode: FileMode.append);

    openFile.close();
  }

  /// Write a Map<String, String> to file
  ///
  writeMapToJson(String fileName, Map<String, String> content) async{
    _fileName = fileName;
    try {
      final file = await _localFile;
      bool fileExist = file.existsSync();
      file.writeAsStringSync(jsonEncode(content));
    } on FileSystemException  {
      return "Write Error";
    }
  }

  /// Add a key:value to file
  ///
  addToJson(String fileName, String key, String value) async {
    _fileName = fileName;
    Map<String, String> content = {key: value};
    try {
      final file = await _localFile;
      if (file.existsSync()) {
        Map<String, dynamic> fileContent = json.decode(file.readAsStringSync());
        fileContent.addAll(content);
        file.writeAsStringSync(jsonEncode(fileContent));
      } else {
        print("Can't add to file! No file ${file.path}");
        print("Create file ${file.path}");
        writeMapToJson(fileName, content);
      }
    } on FileSystemException {
      return null;
    }
  }

  Future<Map<String, dynamic>> readJson(String fileName) async {
    _fileName = fileName;
    try {
      final file =  await _localFile;
      if (file.existsSync()) {
        var fileContent = file.readAsStringSync();
        Map<String, dynamic> contentAsMap = jsonDecode(fileContent);

        return contentAsMap;
      } else {
        return {};
      }

    } catch (e) {
      return null;
    }
  }

}
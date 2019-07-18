import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';


///
class DirectoryList extends StatefulWidget {
  final callback;

  DirectoryList(this.callback);

  @override
  DirectoryListState createState() => DirectoryListState();
}

class DirectoryListState extends State<DirectoryList> {

  Directory externalStorageDir;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text("Select Directory"),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            FutureBuilder(
              future: _inFutureList(),
              builder: (BuildContext context, AsyncSnapshot<List<String>>snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text("Loading...");
                } else {
                  List<String>directoryContent = snapshot.data;
                  return buildDirectoryList(context, directoryContent);
//                  return Container(
//                    child: Expanded(
//                        child: ListView.builder(
//                          itemCount: snapshot.data.length,
//                            itemBuilder: (context, index) {
//                              return ListTile(
//                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 1),
//                                title: Text(snapshot.data[index]),
//                                trailing: IconButton(
//                                    icon: Icon(Icons.arrow_forward),
//                                    onPressed: () {_directoryList(snapshot.data[index]);}),
//                              );
//                              //return Text(snapshot.data[index]);
//                            })
//                    ),
//                  );
                }
              },
            )
          ],
        ),
      ),
    );
  }

  /// Make list with directorys for [FutureBuilder]
  ///
  Future<List<String>>_inFutureList() async{
    var filesList = new List<String>();
    if (externalStorageDir == null) {
      externalStorageDir = await getExternalStorageDirectory();
      List<FileSystemEntity>dirList = externalStorageDir.listSync(recursive: false, followLinks: false);
      for (var i = 0; i < dirList.length; i++) {
        filesList.add(dirList[i].path.split('/').last);
      }
//      externalStorageDir.list(recursive: false, followLinks: false)
//          .listen((FileSystemEntity entity) {
//            print(entity.path);
//            filesList.add(entity.path.split('/').last);
//          });

    } else {
      externalStorageDir.list(recursive: false, followLinks: false)
          .listen((FileSystemEntity entity) {
        print(entity.path);

        filesList.add(entity.path.split('/').last);
      });
    }

    return filesList;
    //filesList = await FilePicker.getFilePath().getFilesFromDir();
    //await new Future.delayed(new Duration(milliseconds: 500));
    //return filesList;
  }

  Widget buildDirectoryList(BuildContext context, List<String> snapshot) {
    return Container(
      child: Expanded(
          child: ListView.builder(
              itemCount: snapshot.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () {
                    print(snapshot[index]);
                    inspectDirectory("${externalStorageDir.path}/${snapshot[index]}");
//                    if ( inspectDirectory("${externalStorageDir.path}/${snapshot[index]}") == true) {
//                      widget.callback("${externalStorageDir.path}/${snapshot[index]}");
//                      Navigator.pop(context);
//                    }
//                    print("over");
                    //widget.callback("${externalStorageDir.path}/${snapshot[index]}");
                    //Navigator.pop(context);
                  },
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                  title: Text(snapshot[index]),
                  trailing: IconButton(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: () {_directoryList(snapshot[index]);}),
                );
                //return Text(snapshot.data[index]);
              })
      ),
    );
  }

  Future<List<String>>_directoryList(String directory) async {
    var directoryContent = List<String>();

    externalStorageDir = Directory('${externalStorageDir.path}/$directory');
    print (externalStorageDir);

    setState(() {

    });

    return directoryContent;
//    await Directory(directoryPath).list(recursive: false, followLinks: false)
//    .listen((FileSystemEntity entity) {
//      directoryContent.add(entity.path);
//    })
//    .onDone(() {
//      buildDirectoryList(context, directoryContent);
//      setState(() {
//
//      });
//    }

   // );



  }

  /// Does directory contains directorys between 1 and 18 (zoom levels)
  ///
  bool inspectDirectory(String directoryPath) {
    List<String> filesList = [];

    Directory(directoryPath).list(recursive: false, followLinks: false)
    .listen((FileSystemEntity entity) {
      filesList.add(entity.path.split('/').last);
    })
    .onDone(() {
      print(filesList.length);
      // directories 1..18?
      int minDir = -1;
      int maxDir = -1;
      for (var i = 0; i < 19; i++) {
        if ( filesList.contains(i.toString()) ) {
          print("Directory contains directory $i");
          if (i == 0) { minDir = 0; }
          maxDir = max(maxDir, i);
          if (minDir == -1) {
            minDir = i;
          } else {
            minDir = min(minDir, i);
          }
        }
      }

      if (minDir <= maxDir && minDir > -1) {
        print("Directory contains directorys between $minDir & $maxDir");

        widget.callback(directoryPath);
        Navigator.pop(context);

        return true;
      } else {
        return false;
      }
    });
    return false;
  }

}
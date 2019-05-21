import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<List<String>>_inFutureList() async{
    var filesList = new List<String>();
    if (externalStorageDir == null) {
      externalStorageDir = await getExternalStorageDirectory();
      externalStorageDir.list(recursive: false, followLinks: false)
          .listen((FileSystemEntity entity) {
        print(entity.path);
        filesList.add(entity.path.split('/').last);
      });
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
                    widget.callback("${externalStorageDir.path}/${snapshot[index]}");
                    Navigator.pop(context);
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
}
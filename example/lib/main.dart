import 'dart:io';

import 'package:example/ftpAuth.dart';
import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpConnect.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter FTP Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final ValueNotifier<String> _logNotifier = ValueNotifier('');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Example FTP")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                onPressed: _uploadStepByStep,
                child: Text("Upload step by step"),
                color: Theme.of(context).primaryColor,
              ),
              RaisedButton(
                onPressed: _uploadWithRetry,
                child: Text("Upload with retry"),
                color: Theme.of(context).primaryColor,
              )
            ],
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                onPressed: _downloadStepByStep,
                child: Text("Download step by step"),
                color: Theme.of(context).primaryColorDark,
              ),
              RaisedButton(
                onPressed: _downloadWithRetry,
                child: Text("Download with retry"),
                color: Theme.of(context).primaryColorDark,
              )
            ],
          ),
          ValueListenableBuilder(
              valueListenable: _logNotifier,
              builder: (context, String text, widget) {
                return Text(text ?? '');
              })
        ],
      ),
    );
  }

  Future<void> _uploadStepByStep() async {
    FTPConnect ftpConnect =
        FTPConnect(FTPAuth.host, user: FTPAuth.user, pass: FTPAuth.pass);
    try {
      await _log('Connecting to FTP ...');
      ftpConnect.ftpClient.connect();
      File fileToUpload = await _fileMock(
          fileName: 'uploadStepByStep.txt', content: 'uploaded Step By Step');
      await _log('Uploading ...');
      await ftpConnect.ftpClient.uploadFile(fileToUpload);
      await _log('file uploaded sucessfully');
      ftpConnect.ftpClient.disconnect();
    } catch (e) {
      await _log('Error: ${e.toString()}');
    }
  }

  Future<void> _uploadWithRetry() async {
    FTPConnect ftpConnect =
        FTPConnect(FTPAuth.host, user: FTPAuth.user, pass: FTPAuth.pass);
    File fileToUpload = await _fileMock(
        fileName: 'uploadwithRetry.txt', content: 'uploaded with Retry');
    await _log('Uploading ...');
    bool res = await ftpConnect.uploadFile(fileToUpload, pRetryCount: 2);
    await _log('file uploaded: ' + (res ? 'SUCCESSFULLY' : 'FAILED'));
  }

  Future<void> _downloadWithRetry() async {
    await _log('Downloading ...');
    FTPConnect ftpConnect =
        FTPConnect(FTPAuth.host, user: FTPAuth.user, pass: FTPAuth.pass);
    String fileName = 'uploadedDownload.txt';
    File fileToUpload = await _fileMock(
        fileName: fileName, content: 'test download with retry');
    //we upload a file and we try to download it
    await ftpConnect.uploadFile(fileToUpload);
    //here we just prepare a file as a path for the downloaded file
    File downloadedFile = await _fileMock(fileName: 'downloadwithRetry.txt');
    bool res =
        await ftpConnect.downloadFile(fileName, downloadedFile, pRetryCount: 2);
    await _log('file downloaded  ' +
        (res ? 'path: ${downloadedFile.path}' : 'FAILED'));
  }

  Future<void> _downloadStepByStep() async {
    try {
      await _log('Connecting to FTP ...');
      FTPConnect ftpConnect =
          FTPConnect(FTPAuth.host, user: FTPAuth.user, pass: FTPAuth.pass);
      ftpConnect.ftpClient.connect();
      await _log('Downloading ...');
      String fileName = 'uploadedDownload.txt';
      File fileToUpload = await _fileMock(
          fileName: fileName, content: 'test download step by step');
      //we upload a file and we try to download it
      await ftpConnect.ftpClient.uploadFile(fileToUpload);
      //here we just prepare a file as a path for the downloaded file
      File downloadedFile = await _fileMock(fileName: 'downloadStepByStep.txt');
      ftpConnect.ftpClient.downloadFile(fileName, downloadedFile);
      await _log('file downloaded path: ${downloadedFile.path}');
      ftpConnect.ftpClient.disconnect();
    } catch (e) {
      await _log('file downloaded : FAILED');
    }
  }

  ///an auxiliary function that manage showed log to UI
  Future<void> _log(String log) async {
    _logNotifier.value = log;
    await Future.delayed(Duration(seconds: 1));
  }

  ///mock a file for the demonstration example
  Future<File> _fileMock({fileName = 'FlutterTest.txt', content = ''}) async {
    final Directory directory = await getTemporaryDirectory();
    final File file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }
}

<h1 align="center">
  Flutter FTP Connect
  <br>
</h1>

<h4 align="center">
  <a href="https://flutter.io" target="_blank">Flutter</a> simple and robust dart FTP Connect Library to interact with FTP Servers with possibility of zip and unzip files.
</h4>

<p align="center">
  <a href="https://pub.dev/packages/ftpconnect">
    <img src="https://img.shields.io/badge/build-passing-brightgreen"
         alt="Build">
  </a>
  <a href="https://pub.dev/packages/ftpconnect"><img src="https://img.shields.io/pub/v/ftpconnect"></a>
</p>

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="https://github.com/salim-lachdhaf/ftpconnect/blob/master/example">Examples</a> •
  <a href="#license">License</a>
</p>


## Key Features
* Upload files to FTP
* Download files/directories from FTP
* List FTP directory contents
* Manage FTP files (rename/delete)
* Manage file zipping/unzipping


## Example upload file
###example 1:
```dart
import 'dart:io';
import 'package:ftpconnect/ftpConnect.dart';

main() async{
   FTPConnect ftpConnect =FTPConnect('example.com',user:'user', pass:'pass');
    File fileToUpload = File('fileToUpload.txt');
    bool res = await ftpConnect.uploadFile(fileToUpload, pRetryCount: 2);
    print(res);
}
```

###example 2: step by step
```dart
import 'dart:io';
import 'package:ftpconnect/ftpConnect.dart';

main() async{
  FTPConnect ftpConnect =FTPConnect('example.com',user:'user', pass:'pass');
 try {
      ftpConnect.ftpClient.connect();
      File fileToUpload = File('fileToUpload.txt');
      await ftpConnect.ftpClient.uploadFile(fileToUpload);
      ftpConnect.ftpClient.disconnect();
    } catch (e) {
      //error
    }
}
```

## Download file
###example 1:
```dart
import 'dart:io';
import 'package:ftpconnect/ftpConnect.dart';

main() async{
    FTPConnect ftpConnect =FTPConnect('example.com',user:'user', pass:'pass');
    String fileName = 'toDownload.txt';
    File fileToUpload = File(fileName);
    bool res = await ftpConnect.downloadFile(fileName, File('myFileFromFTP.txt'));
    print(res)
}
```

###example 2: step by step
```dart
import 'dart:io';
import 'package:ftpconnect/ftpConnect.dart';

main() {
  FTPConnect ftpConnect =FTPConnect('example.com',user:'user', pass:'pass');
 try {
      ftpConnect.ftpClient.connect();
      String fileName = 'toDownload.txt';
      ftpConnect.ftpClient.downloadFile(fileName, File('myFileFromFTP.txt'));
      ftpConnect.ftpClient.disconnect();
    } catch (e) {
      //error
    }
}
```
## Other Features
###Directory functions:
```dart
//Get directory content
ftpConnect.ftpClient.listDirectoryContent();

//Create directory
ftpConnect.ftpClient.makeDirectory('newDir');

//Change directory
ftpConnect.ftpClient.changeDirectory('moveHereDir');

//get current directory
ftpConnect.ftpClient.currentDirectory();

//Delete directory
ftpConnect.ftpClient.deleteDirectory('dirToDelete');

//check for directory existance
ftpConnect.checkFolderExistence('dirToCheck');

//create a directory if it does not exist
ftpConnect.createFolderIfNotExist('dirToCreate');
```
###File functions:
```dart
//rename file
ftpConnect.ftpClient.rename('test1.txt', 'test2.txt');

//delete file
ftpConnect.ftpClient.deleteFile('test2.zip');
```
###Zip functions:
```dart
//compress a list of files/directories into Zip file
ftpConnect.zipFiles(List<String> paths, String destinationZipFile);

//unzip a zip file
ftpConnect.unZipFile(File zipFile, String destinationPath, {password});
```

## Paramaters

|  Properties |   Description|
| ------------ | ------------ |
|`host`|Hostname or IP Address|
|`port`|Port number (Defaults to 21)|
|`user`|Username (Defaults to anonymous)|
|`pass`|Password if not anonymous login|
|`debug`|Enable Debug Logging|
|`timeout`|Timeout in seconds to wait for responses (Defaults to 30)|
|`bufferSize`|buffer size (Defaults to 1024 * 1024)|

# [View more Examples](https://github.com/salim-lachdhaf/ftpconnect/tree/master/example)

## License
MIT
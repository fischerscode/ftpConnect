import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:ftpconnect/src/commands/file.dart';
import 'package:ftpconnect/src/commands/filedownload.dart';
import 'package:ftpconnect/src/commands/fileupload.dart';
import 'package:ftpconnect/src/debug/debuglog.dart';
import 'package:ftpconnect/src/debug/nooplog.dart';
import 'package:ftpconnect/src/debug/printlog.dart';
import 'package:path/path.dart';

import 'commands/directory.dart';
import 'dto/FTPEnty.dart';
import 'ftpsocket.dart';
import 'transfermode.dart';

class FTPConnect {
  final String _user;
  final String _pass;
  FTPSocket _socket;
  final int _bufferSize;
  final DebugLog _log;

  /// Create a FTP Client instance
  ///
  /// [host]: Hostname or IP Address
  /// [port]: Port number (Defaults to 21)
  /// [user]: Username (Defaults to anonymous)
  /// [pass]: Password if not anonymous login
  /// [debug]: Enable Debug Logging
  /// [timeout]: Timeout in secods to wait for responses
  FTPConnect(String host,
      {int port = 21,
      String user = 'anonymous',
      String pass = '',
      bool debug = false,
      int timeout = 30,
      int bufferSize = 1024 * 1024})
      : _user = user,
        _pass = pass,
        _bufferSize = bufferSize,
        _log = debug ? PrintLog() : NoOpLogger() {
    _socket = FTPSocket(host, port, _log, timeout);
  }

  /// Connect to the FTP Server
  void connect() {
    _socket.connect(_user, _pass);
  }

  /// Disconnect from the FTP Server
  void disconnect() {
    _socket.disconnect();
  }

  /// Upload the File [fFile] to the current directory
  Future<void> uploadFile(File fFile,
      {String sRemoteName = '',
      TransferMode mode = TransferMode.binary}) async {
    await FileUpload(_socket, mode, _log).uploadFile(fFile, sRemoteName);
  }

  /// Download the Remote File [sRemoteName] to the local File [fFile]
  void downloadFile(String sRemoteName, File fFile,
      {TransferMode mode = TransferMode.binary}) {
    FileDownload(_socket, mode, _log).downloadFile(sRemoteName, fFile);
  }

  /// Create a new Directory with the Name of [sDirectory] in the current directory.
  ///
  /// Returns `true` if the directory was created successfully
  /// Returns `false` if the directory could not be created or already exists
  bool makeDirectory(String sDirectory) {
    return FTPDirectory(_socket).makeDirectory(sDirectory);
  }

  /// Deletes the Directory with the Name of [sDirectory] in the current directory.
  ///
  /// Returns `true` if the directory was deleted successfully
  /// Returns `false` if the directory could not be deleted or does not nexist
  bool deleteDirectory(String sDirectory) {
    return FTPDirectory(_socket).deleteDirectory(sDirectory);
  }

  /// Change into the Directory with the Name of [sDirectory] within the current directory.
  ///
  /// Use `..` to navigate back
  /// Returns `true` if the directory was changed successfully
  /// Returns `false` if the directory could not be changed (does not exist, no permissions or another error)
  bool changeDirectory(String sDirectory) {
    return FTPDirectory(_socket).changeDirectory(sDirectory);
  }

  /// Returns the current directory
  String currentDirectory() {
    return FTPDirectory(_socket).currentDirectory();
  }

  /// Returns the content of the current directory
  List<FTPEntry> listDirectoryContent() {
    return FTPDirectory(_socket).listDirectoryContent();
  }

  /// Rename a file (or directory) from [sOldName] to [sNewName]
  bool rename(String sOldName, String sNewName) {
    return FTPFile(_socket).rename(sOldName, sNewName);
  }

  /// Delete the file [sFilename] from the server
  bool deleteFile(String sFilename) {
    return FTPFile(_socket).delete(sFilename);
  }


  /// Upload the File [fileToUpload] to the current directory
  /// if [pRemoteName] is not setted the remote file will take take the same local name
  /// [pRetryCount] number of attempts
  ///
  /// this strategy can be used when we don't need to go step by step
  /// (connect -> upload -> disconnect) or there is a need for a number of attemps
  /// in case of a poor connexion for example
  Future<bool> uploadFileWithRetry(File fileToUpload,
      {String pRemoteName = '', int pRetryCount = 1}) async {
    for (int lRetryCount = 1; lRetryCount <= pRetryCount; lRetryCount++) {
      try {
        this.connect();
        await this.uploadFile(fileToUpload, sRemoteName: pRemoteName);
        this.disconnect();
        //if there is no exception we exit the loop
        return true;
      } catch (e) {
        //disconnect if we are connected
        try {
          this.disconnect();
        } catch (ignore) {}
      }
    }
    return false;
  }

  /// Download the Remote File [pRemoteName] to the local File [pLocalFile]
  /// [pRetryCount] number of attempts
  ///
  /// this strategy can be used when we don't need to go step by step
  /// (connect -> download -> disconnect) or there is a need for a number of attempts
  /// in case of a poor connexion for example
  Future<bool> downloadFileWithRetry(String pRemoteName, File pLocalFile,
      {int pRetryCount = 1}) async {
    for (int lRetryCount = 1; lRetryCount <= pRetryCount; lRetryCount++) {
      try {
        this.connect();
        this.downloadFile(pRemoteName, pLocalFile);
        this.disconnect();
        //if there is no exception we exit the loop
        return true;
      } catch (e) {
        //disconnect if we are connected
        try {
          this.disconnect();
        } catch (ignore) {}
      }
    }
    return false;
  }

  /// Download the Remote Directory [pRemoteDir] to the local File [pLocalDir]
  /// [pRetryCount] number of attempts
  Future<bool> downloadDirectory(String pRemoteDir, Directory pLocalDir,
      {int pRetryCount = 1}) async {
    Future<bool> downloadDir(String pRemoteDir, Directory pLocalDir) async {
      //read remote directory content
      if (this.changeDirectory(pRemoteDir)) {
        List<FTPEntry> dirContent = this.listDirectoryContent();
        await Future.forEach(dirContent, (FTPEntry entry) async {
          if (entry.type == 'file' && entry.size > 0) {
            File localFile = File(join(pLocalDir.path, entry.name));
            downloadFile(entry.name, localFile);
          } else if (entry.type == 'dir') {
            //create a local directory
            var localDir = await Directory(join(pLocalDir.path, entry.name))
                .create(recursive: true);
            await downloadDir(entry.name, localDir);
            //back to current folder
            this.changeDirectory('..');
          }
        });
        return true;
      }
      return false;
    }

    for (int lRetryCount = 1; lRetryCount <= pRetryCount; lRetryCount++) {
      try {
        this.connect();
        await downloadDir(pRemoteDir, pLocalDir);
        //if there is no exception we exit the loop
        return true;
      } catch (e) {
        //disconnect if we are connected
        try {
          this.disconnect();
        } catch (ignore) {}
      }
    }
    return false;
  }

  /// check the existence of the Directory with the Name of [pDirectory].
  ///
  /// Returns `true` if the directory was changed successfully
  /// Returns `false` if the directory could not be changed (does not exist, no permissions or another error)
  bool checkFolderExistence(String pDirectory) {
    return this.changeDirectory(pDirectory);
  }

  /// Create a new Directory with the Name of [pDirectory] in the current directory if it does not exist.
  ///
  /// Returns `true` if the directory exists or was created successfully
  /// Returns `false` if the directory not found and could not be created
  bool createFolderIfNotExist(String pDirectory) {
    if (!checkFolderExistence(pDirectory)) {
      return this.makeDirectory(pDirectory);
    }
    return true;
  }

  ///Function that compress list of files and directories into a Zip file
  ///Return true if files compression is finished successfully
  ///[paths] list of files and directories paths to be compressed into a Zip file
  ///[destinationZipFile] full path of destination zip file
  static bool zipFiles(List<String> paths, String destinationZipFile) {
    var encoder = ZipFileEncoder();
    encoder.create(destinationZipFile);
    for (String path in paths) {
      if (FileSystemEntity.typeSync(path) == FileSystemEntityType.directory) {
        encoder.addDirectory(Directory(path));
      } else if (FileSystemEntity.typeSync(path) == FileSystemEntityType.file) {
        encoder.addFile(File(path));
      }
    }
    encoder.close();
    return true;
  }

  ///Function that unZip a zip file and returns the decompressed files/directories path
  ///[zipFile] file to decompress
  ///[destinationPath] local directory path where the zip file will be extracted
  ///[password] optional: use password if the zip is crypted
  static List<String> unZipFile(File zipFile, String destinationPath, {password}) {
    //path should ends with '/'
    if (destinationPath != null && !destinationPath.endsWith('/'))
      destinationPath += '/';
    //list that will be returned with extracted paths
    List<String> lPaths = List();

    // Read the Zip file from disk.
    final bytes = zipFile.readAsBytesSync();

    // Decode the Zip file
    final archive = ZipDecoder().decodeBytes(bytes, password: password);

    // Extract the contents of the Zip archive to disk.
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        var f = File(destinationPath + filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
        lPaths.add(f.path);
      } else {
        var dir = Directory(destinationPath + filename)
          ..create(recursive: true);
        lPaths.add(dir.path);
      }
    }
    return lPaths;
  }
}

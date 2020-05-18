library ftpconnect;

import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:ftpclient/ftpclient.dart';
import 'package:path/path.dart';

class FTPConnect {
  /// Create a FTP Connect instance
  ///
  /// [host]: Hostname or IP Address
  /// [port]: Port number (Defaults to 21)
  /// [user]: Username (Defaults to anonymous)
  /// [pass]: Password if not anonymous login
  /// [debug]: Enable Debug Logging
  /// [timeout]: Timeout in seconds to wait for responses
  /// [bufferSize]: buffer size
  final FTPClient ftpClient;

  FTPConnect(String host,
      {int port = 21,
      String user = 'anonymous',
      String pass = '',
      bool debug = false,
      int timeout = 30,
      int bufferSize = 1024 * 1024})
      : assert(debug != null),
        assert(port != null),
        assert(user != null),
        assert(pass != null),
        assert(timeout != null),
        assert(bufferSize != null),
        ftpClient = FTPClient(host,
            port: port,
            user: user,
            pass: pass,
            debug: debug,
            timeout: timeout,
            bufferSize: bufferSize);

  /// Upload the File [fileToUpload] to the current directory
  /// if [pRemoteName] is not setted the remote file will take take the same local name
  /// [pRetryCount] number of attempts
  ///
  /// this strategy can be used when we don't need to go step by step
  /// (connect -> upload -> disconnect) or there is a need for a number of attemps
  /// in case of a poor connexion for example
  Future<bool> uploadFile(File fileToUpload,
      {String pRemoteName = '', int pRetryCount = 1}) async {
    for (int lRetryCount = 1; lRetryCount <= pRetryCount; lRetryCount++) {
      try {
        this.ftpClient.connect();
        await this.ftpClient.uploadFile(fileToUpload, sRemoteName: pRemoteName);
        this.ftpClient.disconnect();
        //if there is no exception we exit the loop
        return true;
      } catch (e) {
        //disconnect if we are connected
        try {
          this.ftpClient.disconnect();
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
  Future<bool> downloadFile(String pRemoteName, File pLocalFile,
      {int pRetryCount = 1}) async {
    for (int lRetryCount = 1; lRetryCount <= pRetryCount; lRetryCount++) {
      try {
        this.ftpClient.connect();
        this.ftpClient.downloadFile(pRemoteName, pLocalFile);
        this.ftpClient.disconnect();
        //if there is no exception we exit the loop
        return true;
      } catch (e) {
        //disconnect if we are connected
        try {
          this.ftpClient.disconnect();
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
      if (this.ftpClient.changeDirectory(pRemoteDir)) {
        List<FTPEntry> dirContent = this.ftpClient.listDirectoryContent();
        await Future.forEach(dirContent, (FTPEntry entry) async {
          if (entry.type == 'file' && entry.size > 0) {
            File localFile = File(join(pLocalDir.path, entry.name));
            ftpClient.downloadFile(entry.name, localFile);
          } else if (entry.type == 'dir') {
            //create a local directory
            var localDir = await Directory(join(pLocalDir.path, entry.name))
                .create(recursive: true);
            await downloadDir(entry.name, localDir);
            //back to current folder
            this.ftpClient.changeDirectory('..');
          }
        });
        return true;
      }
      return false;
    }

    for (int lRetryCount = 1; lRetryCount <= pRetryCount; lRetryCount++) {
      try {
        this.ftpClient.connect();
        await downloadDir(
            pRemoteDir, Directory(join(pLocalDir.path, pRemoteDir)));
        //if there is no exception we exit the loop
        return true;
      } catch (e) {
        //disconnect if we are connected
        try {
          this.ftpClient.disconnect();
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
    return this.ftpClient.changeDirectory(pDirectory);
  }

  /// Create a new Directory with the Name of [pDirectory] in the current directory if it does not exist.
  ///
  /// Returns `true` if the directory exists or was created successfully
  /// Returns `false` if the directory not found and could not be created
  bool createFolderIfNotExist(String pDirectory) {
    if (!checkFolderExistence(pDirectory)) {
      return this.ftpClient.makeDirectory(pDirectory);
    }
    return true;
  }

  ///Function that compress list of files and directories into a Zip file
  ///Return true if files compression is finished successfully
  ///[paths] list of files and directories paths to be compressed into a Zip file
  ///[destinationZipFile] full path of destination zip file
  bool zipFiles(List<String> paths, String destinationZipFile) {
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
  List<String> unZipFile(File zipFile, String destinationPath, {password}) {
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

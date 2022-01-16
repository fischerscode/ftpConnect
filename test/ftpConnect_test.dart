@Timeout(const Duration(minutes: 15))
import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';
import 'package:test/test.dart';

void main() async {
  final FTPConnect _ftpConnect = new FTPConnect(
    "ftp.dlptest.com",
    user: "dlpuser",
    pass: "rNrKYTX9g7z3RgJRmxWuGHbeu",
    debug: true,
  );
  final FTPConnect _ftpConnect2 = new FTPConnect(
    "demo.wftpserver.com",
    user: "demo",
    pass: "demo",
    debug: true,
    timeout: 60,
  );

  const String _testFileDir = 'test/testResFiles';
  const String _localUploadFile = 'test_upload.txt';
  const String _localDownloadFile = 'test_download.txt';
  const String _localZip = 'testZip.zip';
  const String _localUnZipDir = 'test/testUnZip';

  ///mock a file for the demonstration example
  Future<File> _fileMock({fileName = _localUploadFile}) async {
    final Directory directory = Directory(_testFileDir);
    final File file = File('${directory.path}/$fileName');
    await file.writeAsString(DateTime.now().toString());
    return file;
  }

  test('test ftpConnect', () async {
    expect(await _ftpConnect.connect(), equals(true));
    expect(await _ftpConnect.disconnect(), equals(true));
  });

  test('test ftpConnect No log', () async {
    final FTPConnect _ftpConnectNoLog = new FTPConnect("users.on.net",
        user: "pvpt", pass: "Lachdhaf", debug: true);
    expect(await _ftpConnectNoLog.connect(), equals(true));
    await _ftpConnectNoLog.currentDirectory();

    await _ftpConnectNoLog.listDirectoryContent(
        supportIPv6: false, cmd: DIR_LIST_COMMAND.LIST);

    expect(await _ftpConnectNoLog.disconnect(), equals(true));
  });

  test('test ftpConnect timeOut', () async {
    final FTPConnect _ftpConnectTimeOut = new FTPConnect("speedtest.tele2.net",
        user: "xxxcx", pass: "xxxx", isSecured: true);

    expect(() async => await _ftpConnectTimeOut.connect(),
        throwsA(isA<FTPException>()));
  });

  test('test ftpConnect error connect', () async {
    FTPConnect _ftpConnectErrorConnect =
        new FTPConnect("demo.wftpserver.com", user: "xxxx", pass: "xxxx");
    try {
      await _ftpConnectErrorConnect.connect();
    } catch (e) {
      expect(e is FTPException, equals(true));
    }
    _ftpConnectErrorConnect = new FTPConnect("xxxx.wwww.com");
    try {
      await _ftpConnectErrorConnect.connect();
    } catch (e) {
      expect(e is FTPException, equals(true));
    }
  });

  test('test ftpConnect Dir functions', () async {
    expect(await _ftpConnect.connect(), equals(true));

    expect(await _ftpConnect.currentDirectory(), equals("/"));

    String dirName = 'NoNameTest';
    //make sure that the folder does not exist
    expect(
        await _ftpConnect
            .checkFolderExistence("dirName" + DateTime.now().toString()),
        equals(false));
    await _ftpConnect.deleteEmptyDirectory(dirName);
    //create a new dir NoName and change dir to that dir
    expect(await _ftpConnect.createFolderIfNotExist(dirName), equals(true));
    //change directory
    expect(await _ftpConnect.changeDirectory(dirName), equals(true));
    //list directory content
    expect(
        (await _ftpConnect.listDirectoryContent(cmd: DIR_LIST_COMMAND.LIST))
            is List<FTPEntry>,
        equals(true));
    expect((await _ftpConnect.listDirectoryContentOnlyNames()) is List<String>,
        equals(true));

    //back to root
    await _ftpConnect.changeDirectory('..');
    //delete directory
    expect(await _ftpConnect.deleteEmptyDirectory(dirName), equals(true));
    //try delete a non epty dir => crash because permission denied
    try {
      await _ftpConnect.deleteDirectory("../upload",
          cmd: DIR_LIST_COMMAND.LIST);
    } catch (e) {
      expect(e is FTPException, equals(true));
    }

    //change directory to root
    expect(await _ftpConnect.changeDirectory('/'), equals(true));
    //make directory => false because the folder is protected
    expect(await _ftpConnect.createFolderIfNotExist(dirName), equals(true));
    expect(await _ftpConnect.createFolderIfNotExist('newDir'), equals(true));

    String fileName = 'myFileTest.txt';
    expect(await _ftpConnect.uploadFile(await _fileMock(fileName: fileName)),
        equals(true));

    //change directory to root
    expect(await _ftpConnect.changeDirectory('/'), equals(true));

    //download a dir => false to prevent long loading duration of the test
    try {
      bool res = await _ftpConnect.downloadDirectory(
          dirName, Directory(_testFileDir)..createSync(),
          cmd: DIR_LIST_COMMAND.MLSD);
      expect(res, equals(true));
    } catch (e) {}

    try {
      await _ftpConnect.downloadDirectory(
          '/nonExist', Directory(_testFileDir)..createSync(),
          cmd: DIR_LIST_COMMAND.MLSD);
    } catch (e) {
      expect(e is FTPException, equals(true));
    }

    //close connexion
    expect(await _ftpConnect.disconnect(), equals(true));
  });

  test('test ftpConnect File functions', () async {
    expect(await _ftpConnect.connect(), equals(true));
    String dirName1 = 'NoNameTestFileFolder';
    String fileName = 'myFile.txt';
    //change to the directory where we can work
    expect(await _ftpConnect.createFolderIfNotExist('$dirName1'), equals(true));

    //test upload file (this file will be automatically deleted after upload by the server)
    void testUploadProgress(double p, int r, int fileSize) {
      print('uploaded :$r byte =========> $p%');
    }

    expect(
        await _ftpConnect.uploadFile(await _fileMock(fileName: fileName),
            onProgress: testUploadProgress),
        equals(true));

    expect(
        await _ftpConnect.uploadFileWithRetry(
            await _fileMock(fileName: fileName),
            onProgress: testUploadProgress),
        equals(true));

    //chech for file existence
    expect(await _ftpConnect.existFile(fileName), equals(true));
    //test download file
    void testDownloadProgress(double p, int r, int fileSize) {
      print('downloaded :$r byte =========> $p%');
    }

    expect(
        await _ftpConnect.downloadFile(
            fileName, File('$_testFileDir/$_localDownloadFile'),
            onProgress: testDownloadProgress),
        equals(true));

    expect(
        await _ftpConnect.downloadFileWithRetry(
            fileName, File('$_testFileDir/$_localDownloadFile'),
            onProgress: testDownloadProgress),
        equals(true));

    //test download non exist file
    var remoteFile = 'notExist.zip';
    try {
      await _ftpConnect.downloadFile(remoteFile, File('dist'));
    } catch (e) {
      expect(e is FTPException, equals(true));
      expect(
          (e as FTPException).message ==
              'Remote File $remoteFile does not exist!',
          equals(true));
    }
    //get file size
    expect(await _ftpConnect.sizeFile('../notExist.zip'), equals(-1));

    //test rename file (false because the server is protected)
    expect(await _ftpConnect.rename(fileName, fileName + '_renamed.txt'),
        equals(true));

    //test delete file (false because the server is protected)
    expect(
        await _ftpConnect.deleteFile(fileName + '_renamed.txt'), equals(true));

    expect(await _ftpConnect.disconnect(), equals(true));
  });

  test('test ftpConnect ZIP functions', () async {
    Directory emptyDir = Directory('test/emptyDirectory/');
    await emptyDir.create(recursive: true);
    //zip file
    expect(
        await FTPConnect.zipFiles(
            ['$_testFileDir/$_localUploadFile', _testFileDir, emptyDir.path],
            '$_testFileDir$_localZip'),
        equals(true));

    //test unzip
    expect(
        await FTPConnect.unZipFile(
            File('$_testFileDir/$_localZip'), _localUnZipDir) is List<String>,
        equals(true));
  });

  test('test FTP Entry Class', () {
    //test LIST COMMAND with standard response
    var data = '-rw-------    1 105      108        1024 Jan 10 11:50 file.zip';
    FTPEntry ftpEntry = FTPEntry.parse(data, DIR_LIST_COMMAND.LIST);
    expect(ftpEntry.type, equals(FTPEntryType.FILE));
    expect(ftpEntry.persmission, equals('rw-------'));
    expect(ftpEntry.name, equals('file.zip'));
    expect(ftpEntry.owner, equals('105'));
    expect(ftpEntry.group, equals('108'));
    expect(ftpEntry.size, equals(1024));
    expect(ftpEntry.modifyTime is DateTime, equals(true));

    //test LIS COMMAND with IIS servers
    data = '02-11-15  03:05PM      <DIR>     1410887680 directory';
    ftpEntry = FTPEntry.parse(data, DIR_LIST_COMMAND.LIST);
    expect(ftpEntry.type, equals(FTPEntryType.DIR));
    expect(ftpEntry.name, equals('directory'));
    expect(ftpEntry.modifyTime is DateTime, equals(true));

    data = '02-11-15  03:05PM               1410887680 directory';
    ftpEntry = FTPEntry.parse(data, DIR_LIST_COMMAND.LIST);
    expect(ftpEntry.type, equals(FTPEntryType.FILE));
    expect(ftpEntry.name, equals('directory'));
    expect(ftpEntry.modifyTime is DateTime, equals(true));

    var data2 = 'drw-------    1 105      108        1024 Jan 10 11:50 dir/';
    ftpEntry = FTPEntry.parse(data2, DIR_LIST_COMMAND.LIST);
    expect(ftpEntry.type, equals(FTPEntryType.DIR));

    var data3 = ftpEntry.toString();
    ftpEntry = FTPEntry.parse(data3, DIR_LIST_COMMAND.MLSD);
    expect(ftpEntry.type, equals(FTPEntryType.DIR));
    expect(ftpEntry.owner, equals('105'));
    expect(ftpEntry.group, equals('108'));
    expect(ftpEntry.size, equals(1024));
    expect(ftpEntry.modifyTime is DateTime, equals(true));

    var data4 = 'drw-------    1 105';
    ftpEntry = FTPEntry.parse(data4, DIR_LIST_COMMAND.MLSD);
    expect(ftpEntry.name, equals(data4));

    expect(() => FTPEntry.parse(data4, DIR_LIST_COMMAND.LIST),
        throwsA(isA<FTPException>()));

    var data5;
    expect(() => FTPEntry.parse(data5, DIR_LIST_COMMAND.MLSD),
        throwsA(isA<FTPException>()));
    expect(() => FTPEntry.parse(data5, DIR_LIST_COMMAND.LIST),
        throwsA(isA<FTPException>()));
  });

  test('test FTPConnect exception', () {
    String msgError = 'message';
    String msgResponse = 'reply is here';
    FTPException exception = FTPException(msgError);
    expect(exception.message, equals(msgError));
    exception = FTPException(msgError, msgResponse);
    expect(exception.message, equals(msgError));
    expect(exception.response, equals(msgResponse));
    expect(exception.toString(),
        equals('FTPException: $msgError (Response: $msgResponse)'));
  });
}

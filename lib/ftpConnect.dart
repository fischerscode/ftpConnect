library ftpconnect;

import 'dart:io';

import 'package:ftpclient/ftpclient.dart';

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
    bool lResult = false;
    for (int lRetryCount = 1; lRetryCount <= pRetryCount; lRetryCount++) {
      try {
        this.ftpClient.connect();
        await this.ftpClient.uploadFile(fileToUpload, sRemoteName: pRemoteName);
        //if there is no exception we exit the loop
        return true;
      } catch (e) {
        //If lRetryCount==this.retryCount means that we tried all attempts
        //and we should exit with False
        if (lRetryCount == pRetryCount) {
          lResult = false;
        }
      } finally {
        this.ftpClient.disconnect();
      }
    }
    return lResult;
  }

  /// Download the Remote File [pRemoteName] to the local File [pLocalFile]
  /// [pRetryCount] number of attempts
  ///
  /// this strategy can be used when we don't need to go step by step
  /// (connect -> download -> disconnect) or there is a need for a number of attemps
  /// in case of a poor connexion for example
  Future<bool> downloadFile(String pRemoteName, File pLocalFile,
      {int pRetryCount = 1}) async {
    bool lResult = false;
    for (int lRetryCount = 1; lRetryCount <= pRetryCount; lRetryCount++) {
      try {
        this.ftpClient.connect();
        this.ftpClient.downloadFile(pRemoteName, pLocalFile);
        //if there is no exception we exit the loop
        return true;
      } catch (e) {
        //If lRetryCount==this.retryCount means that we tried all attempts
        //and we should exit with False
        if (lRetryCount == pRetryCount) {
          lResult = false;
        }
      } finally {
        this.ftpClient.disconnect();
      }
    }
    return lResult;
  }
}

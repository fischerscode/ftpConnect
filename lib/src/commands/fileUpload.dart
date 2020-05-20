import 'dart:io';

import 'package:path/path.dart';

import '../ftpExceptions.dart';
import '../ftpSocket.dart';
import '../transferMode.dart';
import '../debug/debugLog.dart';
import '../util/transferUtil.dart';

class FileUpload {
  final FTPSocket _socket;
  final TransferMode _mode;
  final DebugLog _log;

  /// File Upload Command
  FileUpload(this._socket, this._mode, this._log);

  /// Upload File [fFile] to the current directory with [sRemoteName] (using filename if not set)
  Future<bool> uploadFile(File fFile, [String sRemoteName = '']) async {
    _log.log('Upload File: ${fFile.path}');

    // Transfer Mode
    await TransferUtil.setTransferMode(_socket, _mode);

    // Enter passive mode
    await _socket.sendCommand('PASV');

    String sResponse = await _socket.readResponse();
    if (!sResponse.startsWith('227')) {
      throw FTPException('Could not start Passive Mode', sResponse);
    }

    int iPort = TransferUtil.parsePort(sResponse);

    // Store File
    String sFilename = sRemoteName;
    if (sFilename == null || sFilename.isEmpty) {
      sFilename = basename(fFile.path);
    }
   await _socket.sendCommand('STOR $sFilename');

    // Data Transfer Socket
    final readStream = fFile.openRead();
    _log.log('Opening DataSocket to Port $iPort');
    final dataSocket = await Socket.connect(_socket.host, iPort);

    final acceptResponse = await _socket.readResponse();
    _log.log('response $acceptResponse');

    await dataSocket.addStream(readStream);
    await dataSocket.flush();
    await dataSocket.close();

    _log.log('File Uploaded!');

    final fileReceivedResponse = await _socket.readResponse();
    _log.log('second response $fileReceivedResponse');
    return true;
  }
}

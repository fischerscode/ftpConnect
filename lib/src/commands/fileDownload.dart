import 'dart:io';

import '../ftpExceptions.dart';
import '../ftpSocket.dart';
import '../transferMode.dart';
import '../debug/debugLog.dart';
import '../util/transferUtil.dart';
import 'file.dart';

class FileDownload {
  final FTPSocket _socket;
  final TransferMode _mode;
  final DebugLog _log;

  /// File Download Command
  FileDownload(this._socket, this._mode, this._log);

  Future<bool> downloadFile(String sRemoteName, File fLocalFile) async {
    _log.log('Download $sRemoteName to ${fLocalFile.path}');

    if (!await FTPFile(_socket).exist(sRemoteName)) {
      throw FTPException('Remote File $sRemoteName does not exist!');
    }

    // Transfer Mode
    await TransferUtil.setTransferMode(_socket, _mode);

    // Enter passive mode
    String sResponse = await _socket.sendCommand('PASV');
    if (!sResponse.startsWith('227')) {
      throw FTPException('Could not start Passive Mode', sResponse);
    }

    //the response will be the file, witch will be loaded with another socket
    await _socket.sendCommand('RETR $sRemoteName', waitResponse: false);

    // Data Transfer Socket
    int iPort = TransferUtil.parsePort(sResponse);
    _log.log('Opening DataSocket to Port $iPort');
    final Socket dataSocket = await Socket.connect(_socket.host, iPort);
    _log.log('Start downloading...');

    var sink = fLocalFile.openWrite(mode: FileMode.writeOnly);
    await sink.addStream(dataSocket.asBroadcastStream());
    sink.flush();
    sink.close();
    await dataSocket.close();

    _log.log('File Downloaded!');
    return true;
  }
}

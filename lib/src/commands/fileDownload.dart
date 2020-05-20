import 'dart:convert';
import 'dart:io';

import '../ftpExceptions.dart';
import '../ftpSocket.dart';
import '../transferMode.dart';
import '../debug/debugLog.dart';
import '../util/transferUtil.dart';

class FileDownload {
  final FTPSocket _socket;
  final TransferMode _mode;
  final DebugLog _log;

  /// File Download Command
  FileDownload(this._socket, this._mode, this._log);

  Future<bool> downloadFile(String sRemoteName, File fLocalFile) async {
    _log.log('Download $sRemoteName to ${fLocalFile.path}');

    // Transfer Mode
    await TransferUtil.setTransferMode(_socket, _mode);

    // Enter passive mode
    await _socket.sendCommand('PASV');

    String sResponse = await _socket.readResponse();
    if (!sResponse.startsWith('227')) {
      throw FTPException('Could not start Passive Mode', sResponse);
    }

    int iPort = TransferUtil.parsePort(sResponse);

    await _socket.sendCommand('RETR $sRemoteName');

//    sResponse = await _socket.readResponse();
//    if (sResponse.startsWith('550')) {
//      throw FTPException('Remote File $sRemoteName does not exist!', sResponse);
//    }


    // Data Transfer Socket
    _log.log('Opening DataSocket to Port $iPort');
    RawSocket dataSocket = await RawSocket.connect(_socket.host, iPort);

    RandomAccessFile lFile = await fLocalFile.open(mode: FileMode.writeOnly);

    int iRead = 0;
    dataSocket.listen((event) async {
      // Transfer file
      switch (event) {
        case RawSocketEvent.read:

          var buffer = dataSocket.read();
          await lFile.writeFrom(buffer);
          iRead += buffer.length;

          break;
        default:
          break;
      }
    }, onDone: () async {
      _log.log('Downloaded: $iRead B');
      await dataSocket.close();
      await lFile.flush();
      await lFile.close();
    }, onError: (e) {
      print(e);
    });

    await _socket.readResponse();

    _log.log('File Downloaded!');
    await _socket.readResponse(true);
    return true;
  }
}

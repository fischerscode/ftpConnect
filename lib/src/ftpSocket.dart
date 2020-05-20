import 'dart:convert';
import 'dart:io';

import 'package:ftpconnect/src/debug/debugLog.dart';

import '../ftpconnect.dart';

class FTPSocket {
  final Encoding _codec = Utf8Codec();

  final String host;
  final int port;
  final DebugLog _log;
  final int _timeout;

  RawSocket _socket;

  FTPSocket(this.host, this.port, this._log, this._timeout);

  /// Read the FTP Server response from the Stream
  ///
  /// Blocks until data is received!
  Future<String> readResponse([bool bOptional = false]) async {
    StringBuffer buffer = StringBuffer();
    int iStart = DateTime.now().millisecondsSinceEpoch;

    await Future.doWhile(() async {
      int iToRead = _socket.available();

      if (iToRead > 0) {
        buffer.write(_codec.decode(_socket.read(iToRead)));
      }

      if (iToRead == 0 && buffer.length == 0) {
        int iCurrent = DateTime.now().millisecondsSinceEpoch;
        if (iCurrent - iStart > _timeout * 1000) {
          throw FTPException('Timeout reached for Receive', '');
        }
        await Future.delayed(Duration(milliseconds: 200));
      }
      if (iToRead > 0 || (buffer.length == 0 && !bOptional)) return true;
      return false;
    });

    String sResponse = buffer.toString().trimRight();
    _log.log('< $sResponse');
    return sResponse;
  }

  /// Send a command to the FTP Server
  Future<void> sendCommand(String sCommand) async {
    if (_socket.available() > 0) {
      await readResponse();
    }

    _log.log('> $sCommand');
    _socket.write(_codec.encode('$sCommand\r\n'));
  }

  /// Connect to the FTP Server and Login with [user] and [pass]
  Future<bool> connect(String user, String pass) async {
    _log.log('Connecting...');
    _socket = await RawSocket.connect(host, port,
        timeout: Duration(seconds: _timeout));

    // Wait for Connect
    String sResponse = await readResponse();
    if (!sResponse.startsWith('220')) {
      throw FTPException('Unknown response from FTP server', sResponse);
    }

    // Send Username
    await sendCommand('USER $user');

    sResponse = await readResponse();
    if (!sResponse.startsWith('331')) {
      throw FTPException('Wrong username $user', sResponse);
    }

    // Send Password
    await sendCommand('PASS $pass');

    sResponse = await readResponse();
    if (!sResponse.startsWith('230')) {
      throw FTPException('Wrong password', sResponse);
    }

    _log.log('Connected!');
    return true;
  }

  // Disconnect from the FTP Server
  Future<bool> disconnect() async {
    _log.log('Disconnecting...');

    try {
      await sendCommand('QUIT');
    } catch (ignored) {
      // Ignore
    } finally {
      await _socket?.close();
    }

    _log.log('Disconnected!');
    return true;
  }
}

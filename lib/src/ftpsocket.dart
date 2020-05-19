import 'dart:convert';
import 'dart:io';

import 'package:ftpconnect/src/debug/debuglog.dart';

import '../ftpconnect.dart';

class FTPSocket {
  final Encoding _codec = Utf8Codec();

  final String host;
  final int port;
  final DebugLog _log;
  final int _timeout;

  RawSynchronousSocket _socket;

  FTPSocket(this.host, this.port, this._log, this._timeout);

  /// Read the FTP Server response from the Stream
  ///
  /// Blocks until data is received!
  String readResponse([bool bOptional = false]) {
    int iToRead = 0;
    StringBuffer buffer = StringBuffer();
    int iStart = DateTime.now().millisecondsSinceEpoch;

    do {
      if (iToRead > 0) {
        buffer.write(_codec.decode(_socket.readSync(iToRead)));
      }

      iToRead = _socket.available();

      if (iToRead == 0 && buffer.length == 0) {
        int iCurrent = DateTime.now().millisecondsSinceEpoch;
        if (iCurrent - iStart > _timeout * 1000) {
          throw FTPException('Timeout reached for Receive', '');
        }
        sleep(Duration(milliseconds: 100));
      }
    } while (iToRead > 0 || (buffer.length == 0 && !bOptional));

    String sResponse = buffer.toString().trimRight();
    _log.log('< $sResponse');
    return sResponse;
  }

  /// Send a command to the FTP Server
  void sendCommand(String sCommand) {
    if (_socket.available() > 0) {
      readResponse();
    }

    _log.log('> $sCommand');
    _socket.writeFromSync(_codec.encode('$sCommand\r\n'));
  }

  /// Connect to the FTP Server and Login with [user] and [pass]
  void connect(String user, String pass) {
    _log.log('Connecting...');
    _socket = RawSynchronousSocket.connectSync(host, port);

    // Wait for Connect
    String sResponse = readResponse();
    if (!sResponse.startsWith('220')) {
      throw FTPException('Unknown response from FTP server', sResponse);
    }

    // Send Username
    sendCommand('USER $user');

    sResponse = readResponse();
    if (!sResponse.startsWith('331')) {
      throw FTPException('Wrong username $user', sResponse);
    }

    // Send Password
    sendCommand('PASS $pass');

    sResponse = readResponse();
    if (!sResponse.startsWith('230')) {
      throw FTPException('Wrong password', sResponse);
    }

    _log.log('Connected!');
  }

  // Disconnect from the FTP Server
  void disconnect() {
    _log.log('Disconnecting...');

    try {
      sendCommand('QUIT');
    } catch (ignored) {
      // Ignore
    } finally {
      _socket.closeSync();
    }

    _log.log('Disconnected!');
  }
}

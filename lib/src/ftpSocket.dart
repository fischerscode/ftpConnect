import 'dart:convert';
import 'dart:io';

import 'package:ftpconnect/src/debug/debugLog.dart';

import '../ftpconnect.dart';

class FTPSocket {
  final String host;
  final int port;
  final DebugLog _log;
  final int _timeout;

  RawSocket _socket;

  FTPSocket(this.host, this.port, this._log, this._timeout);

  /// Read the FTP Server response from the Stream
  ///
  /// Blocks until data is received!
  Future<String> _readResponse() async {
    String sResponse;
    await Future.doWhile(() async {
      if (_socket.available() > 0) {
        sResponse = String.fromCharCodes(_socket.read()).trim();
        return false;
      }
      await Future.delayed(Duration(milliseconds: 200));
      return true;
    }).timeout(Duration(seconds: _timeout), onTimeout: () {
      throw FTPException('Timeout reached for Receiving response !');
    });

    _log.log('< $sResponse');
    return sResponse;
  }

  /// Send a command [cmd] to the FTP Server
  /// if [waitResponse] the function waits for the reply, other wise return ''
  Future<String> sendCommand(String cmd, {bool waitResponse = true}) async {
    _log.log('> $cmd');
    _socket.write(Utf8Codec().encode('$cmd\r\n'));

    if (waitResponse == true) {
      return await _readResponse();
    }
    return '';
  }

  /// Connect to the FTP Server and Login with [user] and [pass]
  Future<bool> connect(String user, String pass) async {
    _log.log('Connecting...');
    _socket = await RawSocket.connect(host, port,
        timeout: Duration(seconds: _timeout));

    // Wait for Connect
    if (_socket == null) {
      throw FTPException('Could not connect to $host ($port)');
    }

    // Send Username
    String sResponse = await sendCommand('USER $user');
    if (!sResponse.startsWith('220')) {
      throw FTPException('Wrong username $user', sResponse);
    }

    // Send Password
    sResponse = await sendCommand('PASS $pass');
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

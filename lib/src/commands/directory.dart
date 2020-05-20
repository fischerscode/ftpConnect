import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';
import 'package:ftpconnect/src/dto/FTPEntry.dart';
import 'package:ftpconnect/src/util/transferUtil.dart';

import '../ftpExceptions.dart';
import '../ftpSocket.dart';

class FTPDirectory {
  final FTPSocket _socket;

  FTPDirectory(this._socket);

  Future<bool> makeDirectory(String sName) async {
    await _socket.sendCommand('MKD $sName');

    String sResponse = await _socket.readResponse();

    return sResponse.startsWith('257');
  }

  Future<bool> deleteDirectory(String sName) async {
    await _socket.sendCommand('RMD $sName');

    String sResponse = await _socket.readResponse();

    return sResponse.startsWith('250');
  }

  Future<bool> changeDirectory(String sName) async {
    await _socket.sendCommand('CWD $sName');

    String sResponse = await _socket.readResponse();

    return sResponse.startsWith('250');
  }

  Future<String> currentDirectory() async {
    await _socket.sendCommand('PWD');

    String sResponse = await _socket.readResponse();
    if (!sResponse.startsWith('257')) {
      throw FTPException('Failed to get current working directory', sResponse);
    }

    int iStart = sResponse.indexOf('"') + 1;
    int iEnd = sResponse.lastIndexOf('"');

    return sResponse.substring(iStart, iEnd);
  }

  Future<List<FTPEntry>> listDirectoryContent() async {
    // Transfer mode
    await TransferUtil.setTransferMode(_socket, TransferMode.ascii);

    // Enter passive mode
    await _socket.sendCommand('PASV');

    String sResponse = await _socket.readResponse();
    if (!sResponse.startsWith('227')) {
      throw FTPException('Could not start Passive Mode', sResponse);
    }

    int iPort = TransferUtil.parsePort(sResponse);

    // Directoy content listing
    await _socket.sendCommand('MLSD');

    // Data transfer socket
    RawSocket dataSocket = await RawSocket.connect(_socket.host, iPort);

    sResponse = await _socket.readResponse();
    if (!sResponse.startsWith('150')) {
      throw FTPException('Can\'t get content of directory.', sResponse);
    }

    List<int> lstDirectoryListing = List<int>();

    await Future.doWhile(() async {
      int iToRead = dataSocket.available();

      if (iToRead > 0) {
        List<int> buffer = List<int>(iToRead);
        buffer = dataSocket.read(iToRead);
        buffer.forEach(lstDirectoryListing.add);
      }

      if (iToRead == 0) {
        await Future.delayed(Duration(milliseconds: 1000));
        iToRead = dataSocket.available();
      }
      if (iToRead > 0) return true;
      return false;
    });

    await dataSocket.close();

    if (!sResponse.contains('226')) {
      sResponse = await _socket.readResponse(true);
      if (!sResponse.startsWith('226')) {
        throw FTPException('Can\'t get content of directory.', sResponse);
      }
    }

    // Convert MLSD response into FTPEntry
    List<FTPEntry> lstFTPEntries = List<FTPEntry>();
    String.fromCharCodes(lstDirectoryListing).split('\n').forEach((line) {
      if (line.trim().isNotEmpty) {
        lstFTPEntries.add(FTPEntry(line));
      }
    });

    return lstFTPEntries;
  }
}

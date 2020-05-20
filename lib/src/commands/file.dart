import '../ftpSocket.dart';

class FTPFile {
  FTPSocket _socket;

  FTPFile(this._socket);

  Future<bool> rename(String sOldName, String sNewName) async {
    await _socket.sendCommand('RNFR $sOldName');

    String sResponse = await _socket.readResponse();
    if (!sResponse.startsWith('350')) {
      return false;
    }

    await _socket.sendCommand('RNTO $sNewName');

    sResponse = await _socket.readResponse();
    if (!sResponse.startsWith('250')) {
      return false;
    }

    return true;
  }

  Future<bool> delete(String sFilename) async {
    await _socket.sendCommand('DELE $sFilename');

    String sResponse = await _socket.readResponse();
    return sResponse.startsWith('250');
  }

  Future<bool> exist(String sFilename) async {
    return await size(sFilename) != -1;
  }

  Future<int> size(String sFilename) async {
    await _socket.sendCommand('SIZE $sFilename');

    try{
      String sResponse = await _socket.readResponse();
      String size = sResponse.replaceAll('213 ','');
      return int.parse(size);
    }catch(e){
      return -1;
    }
  }
}

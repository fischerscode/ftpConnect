import 'dart:async';

import '../ftpSocket.dart';
import '../transferMode.dart';

class TransferUtil {
  /// Set the Transfer mode on [socket] to [mode]
  static Future<void> setTransferMode(
      FTPSocket socket, TransferMode mode) async {
    switch (mode) {
      case TransferMode.ascii:
        // Set to ASCII mode
        await socket.sendCommand('TYPE A');
        await socket.readResponse();
        break;
      case TransferMode.binary:
        // Set to BINARY mode
        await socket.sendCommand('TYPE I');
        await socket.readResponse();
        break;
      default:
        break;
    }
  }

  /// Parse the Passive Mode Port from the Servers [sResponse]
  static int parsePort(String sResponse) {
    int iParOpen = sResponse.indexOf('(');
    int iParClose = sResponse.indexOf(')');

    String sParameters = sResponse.substring(iParOpen + 1, iParClose);
    List<String> lstParameters = sParameters.split(',');

    int iPort1 = int.parse(lstParameters[lstParameters.length - 2]);
    int iPort2 = int.parse(lstParameters[lstParameters.length - 1]);

    return (iPort1 * 256) + iPort2;
  }

  ///retry a function [retryCount] times, until exceed [retryCount] or execute the function successfully
  ///Return true if the future executed successfully , false other wises
  static Future<bool> retryAction(FutureOr<bool> action(), retryCount) async {
    int lRetryCount = 0;
    bool result = true;
    await Future.doWhile(() async {
      if (lRetryCount++ >= retryCount) {
        result = false;
        //return false to exit the future loop
        return false;
      }
      try {
        result = await action();
        //if there is no exception we exit the loop (return false to exit)
        return false;
      } catch (e) {
        print(e);
        //ignore
      }
      //return true to loop again
      return true;
    });
    return result;
  }
}

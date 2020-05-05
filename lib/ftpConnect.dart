library ftpconnect;

import 'package:ftpclient/ftpclient.dart';
class FtpConnect {

  FTPClient ftpClient = FTPClient('example.com', user: 'myname', pass: 'mypass');
}

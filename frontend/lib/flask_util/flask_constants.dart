// const flaskScheme = 'http';
// const flaskHost = '127.0.0.1';
// int? flaskPort = 5000;
const flaskScheme = 'https';
const flaskHost = 'wellreadbackend.jeremyjohn.me';
int? flaskPort;

String _flaskPort = flaskPort == null ? '' : ':$flaskPort';
String flaskServer = '$flaskScheme://$flaskHost$_flaskPort';

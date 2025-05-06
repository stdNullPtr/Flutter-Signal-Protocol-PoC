class Logger {
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _bold = '\x1B[1m';

  static String? _lastSource;

  static void log(String source, String message, {LogType type = LogType.info}) {
    if (_lastSource != null && _lastSource != source) {
      // ignore: avoid_print
      print('');
    }
    _lastSource = source;

    String coloredSource;
    String coloredMessage;

    if (source.toLowerCase().contains('server')) {
      coloredSource = '$_yellow$_bold[SERVER]$_reset';
    } else {
      coloredSource = '$_cyan$_bold[$source]$_reset';
    }

    switch (type) {
      case LogType.encryption:
        coloredMessage = '$_green$message$_reset';
        break;
      case LogType.decryption:
        coloredMessage = '$_blue$message$_reset';
        break;
      case LogType.keyExchange:
        coloredMessage = '$_magenta$message$_reset';
        break;
      case LogType.error:
        coloredMessage = '$_red$message$_reset';
        break;
      case LogType.success:
        coloredMessage = '$_green$_bold$message$_reset';
        break;
      default:
        coloredMessage = message;
    }

    // ignore: avoid_print
    print('$coloredSource $coloredMessage');
  }

  static void server(String message) {
    log('SERVER', message);
  }

  static void client(String clientName, String message, {LogType type = LogType.info}) {
    log(clientName, message, type: type);
  }
}

enum LogType { info, encryption, decryption, keyExchange, error, success }

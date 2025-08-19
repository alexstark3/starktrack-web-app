import 'dart:developer' as dev;

enum LogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._();

  static void debug(
    String message, {
    String name = 'StarkTrack',
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Debug messages are only logged to dev tools, not to console
    dev.log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: _level(LogLevel.debug),
    );
  }

  static void info(
    String message, {
    String name = 'StarkTrack',
  }) {
    dev.log(
      message,
      name: name,
      level: _level(LogLevel.info),
    );
  }

  static void warn(
    String message, {
    String name = 'StarkTrack',
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: _level(LogLevel.warning),
    );
  }

  static void error(
    String message, {
    String name = 'StarkTrack',
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      message,
      name: name,
      error: error,
      stackTrace: stackTrace,
      level: _level(LogLevel.error),
    );
  }

  static int _level(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}

enum LogLevel {
  info,
  warning,
  error,
  success,
}

class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;

  const LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
  });

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }

  String get levelName {
    switch (level) {
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.success:
        return 'SUCCESS';
    }
  }
}
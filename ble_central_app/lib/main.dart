import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'views/home_view.dart';
import 'view_models/central_scanner_view_model.dart';
import 'package:clover/clover.dart';

void main() {
  runZonedGuarded(onStartUp, onCrashed);
}

void onStartUp() async {
  Logger.root.onRecord.listen(onLogRecord);
  hierarchicalLoggingEnabled = true;
  runApp(const BLECentralApp());
}

void onCrashed(Object error, StackTrace stackTrace) {
  Logger.root.shout('앱이 충돌했습니다.', error, stackTrace);
}

void onLogRecord(LogRecord record) {
  log(
    record.message,
    time: record.time,
    sequenceNumber: record.sequenceNumber,
    level: record.level.value,
    name: record.loggerName,
    zone: record.zone,
    error: record.error,
    stackTrace: record.stackTrace,
  );
}

class BLECentralApp extends StatelessWidget {
  const BLECentralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE 중앙 스캐너',
      theme: ThemeData.light().copyWith(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: ViewModelBinding(
        viewBuilder: () => const HomeView(),
        viewModelBuilder: () => CentralScannerViewModel(),
      ),
    );
  }
}
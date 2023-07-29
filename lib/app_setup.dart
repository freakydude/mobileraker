/*
 * Copyright (c) 2023. Patrick Schmidt.
 * All rights reserved.
 */

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobileraker/data/adapters/uri_adapter.dart';
import 'package:mobileraker/data/model/hive/gcode_macro.dart';
import 'package:mobileraker/data/model/hive/machine.dart';
import 'package:mobileraker/data/model/hive/macro_group.dart';
import 'package:mobileraker/data/model/hive/octoeverywhere.dart';
import 'package:mobileraker/data/model/hive/progress_notification_mode.dart';
import 'package:mobileraker/data/model/hive/temperature_preset.dart';
import 'package:mobileraker/data/model/hive/webcam_mode.dart';
import 'package:mobileraker/data/model/hive/webcam_rotation.dart';
import 'package:mobileraker/data/model/hive/webcam_setting.dart';
import 'package:mobileraker/service/machine_service.dart';

import 'logger.dart';

setupBoxes() async {
  await Hive.initFlutter();

  var secureStorage = const FlutterSecureStorage();

  final encryptionKey = await secureStorage.read(key: 'hive_key');
  if (encryptionKey == null) {
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: 'hive_key',
      value: base64UrlEncode(key),
    );
  }

  final key = await secureStorage.read(key: 'hive_key');

  final keyMaterial = base64Url.decode(key!);

  // Ignore old/deperecates types!
  // 2 - WebcamSetting
  // 6 - WebCamMode
  // 9 - WebCamRotation
  // Hive.ignoreTypeId(2);// WebcamSetting
  // Hive.ignoreTypeId(6);// WebCamMode
  // Hive.ignoreTypeId(9);// WebCamRotation

  var machineAdapter = MachineAdapter();
  if (!Hive.isAdapterRegistered(machineAdapter.typeId)) {
    Hive.registerAdapter(machineAdapter);
  }

  var temperaturePresetAdapter = TemperaturePresetAdapter();
  if (!Hive.isAdapterRegistered(temperaturePresetAdapter.typeId)) {
    Hive.registerAdapter(temperaturePresetAdapter);
  }
  var macroGrpAdapter = MacroGroupAdapter();
  if (!Hive.isAdapterRegistered(macroGrpAdapter.typeId)) {
    Hive.registerAdapter(macroGrpAdapter);
  }
  var macroAdapter = GCodeMacroAdapter();
  if (!Hive.isAdapterRegistered(macroAdapter.typeId)) {
    Hive.registerAdapter(macroAdapter);
  }

  var progressNotifModeAdapter = ProgressNotificationModeAdapter();
  if (!Hive.isAdapterRegistered(progressNotifModeAdapter.typeId)) {
    Hive.registerAdapter(progressNotifModeAdapter);
  }

  var octoAdapater = OctoEverywhereAdapter();
  if (!Hive.isAdapterRegistered(octoAdapater.typeId)) {
    Hive.registerAdapter(octoAdapater);
  }

  // TODO: Remove adapters and enable ignoreType again! after x months!
  final wModeAdapater = WebCamModeAdapter();
  if (!Hive.isAdapterRegistered(wModeAdapater.typeId)) {
    Hive.registerAdapter(wModeAdapater);
  }
  var webCamRotationAdapter = WebCamRotationAdapter();
  if (!Hive.isAdapterRegistered(webCamRotationAdapter.typeId)) {
    Hive.registerAdapter(webCamRotationAdapter);
  }
  var webcamSettingAdapter = WebcamSettingAdapter();
  if (!Hive.isAdapterRegistered(webcamSettingAdapter.typeId)) {
    Hive.registerAdapter(webcamSettingAdapter);
  }

  var uriAdapter = UriAdapter();
  if (!Hive.isAdapterRegistered(uriAdapter.typeId)) {
    Hive.registerAdapter(uriAdapter);
  }

  // Hive.deleteBoxFromDisk('printers');

  try {
    await openBoxes(keyMaterial);
    Hive.box<Machine>("printers").values.forEach((element) {
      logger.i('Machine in box is ${element.debugStr}#${element.hashCode}');
    });
  } catch (e) {
    await Hive.deleteBoxFromDisk('printers');
    await Hive.deleteBoxFromDisk('uuidbox');
    await Hive.deleteBoxFromDisk('settingsbox');
    await openBoxes(keyMaterial);
  }
}

Future<List<Box>> openBoxes(Uint8List keyMaterial) {
  return Future.wait([
    Hive.openBox<Machine>('printers').then(_migrateMachine),
    Hive.openBox<String>('uuidbox'),
    Hive.openBox('settingsbox'),
    Hive.openBox<OctoEverywhere>('octo', encryptionCipher: HiveAesCipher(keyMaterial))
  ]);
}

Future<Box<Machine>> _migrateMachine(Box<Machine> box) async {
  var allMigratedPrinters = box.values.toList();
  await box.clear();
  await box.putAll({
    for (var p in allMigratedPrinters) p.uuid: p,
  });
  return box;
}

setupLicenseRegistry() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
}

/// Ensure all services are setup/available/connected if they are also read just once!
initializeAvailableMachines(ProviderContainer container) async {
  logger.i('Started initializeAvailableMachines');
  List<Machine> machines = await container.read(allMachinesProvider.future);

  await Future.wait(machines.map((e) => container.read(machineProvider(e.uuid).future)));
  logger.i('initialized all machineProviders');
  // for (var machine in machines) {
  //   logger.i('Init for ${machine.name}(${machine.uuid})');
  //   container.read(klipperServiceProvider(machine.uuid));
  //   container.read(printerServiceProvider(machine.uuid));
  // }

  logger.i('Finished initializeAvailableMachines');
}

/*
 * Copyright (c) 2024. Patrick Schmidt.
 * All rights reserved.
 */

// ignore_for_file: prefer-single-widget-per-file

import 'dart:io';

import 'package:common/data/dto/machine/print_state_enum.dart';
import 'package:common/service/live_activity_service.dart';
import 'package:common/service/live_activity_service_v2.dart';
import 'package:common/service/moonraker/klipper_system_service.dart';
import 'package:common/service/selected_machine_service.dart';
import 'package:common/service/ui/bottom_sheet_service_interface.dart';
import 'package:common/service/ui/snackbar_service_interface.dart';
import 'package:common/ui/components/nav/nav_drawer_view.dart';
import 'package:common/ui/components/nav/nav_rail_view.dart';
import 'package:common/util/extensions/build_context_extension.dart';
import 'package:common/util/extensions/date_time_extension.dart';
import 'package:common/util/logger.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:live_activities/live_activities.dart';
import 'package:mobileraker/service/ui/bottom_sheet_service_impl.dart';
import 'package:mobileraker/ui/screens/dashboard/components/fans_card.dart';
import 'package:path_provider/path_provider.dart';

class DevPage extends HookConsumerWidget {
  DevPage({
    super.key,
  });

  String? _bla;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.i('REBUILIDNG DEV PAGE!');
    var selMachine = ref.watch(selectedMachineProvider).value;

    var systemInfo = ref.watch(klipperSystemInfoProvider(selMachine!.uuid));

    Widget body = ListView(
      children: [
          // PowerApiCardLoading(),

          // BedMeshCard(machineUUID: selMachine!.uuid),
          // FirmwareRetractionCard(machineUUID: selMachine!.uuid),
          // MachineStatusCardLoading(),
          // BedMeshCard(machineUUID: selMachine!.uuid),
          // SpoolmanCardLoading(),

        FansCard(machineUUID: selMachine.uuid),
        // FansCard.loading(),
        // PinsCard(machineUUID: selMachine.uuid),
        // PinsCard.loading(),
        // PowerApiCard(machineUUID: selMachine.uuid),
        // PowerApiCard.loading(),

        OutlinedButton(onPressed: () => v2Activity(ref), child: const Text('V2 activity')),
        OutlinedButton(onPressed: () => startLiveActivity(ref), child: const Text('start activity')),
        OutlinedButton(onPressed: () => updateLiveActivity(ref), child: const Text('update activity')),
          OutlinedButton(
              onPressed: () => ref
                  .read(bottomSheetServiceProvider)
                  .show(BottomSheetConfig(type: SheetType.userManagement, isScrollControlled: true)),
              child: const Text('UserMngnt')),
          ElevatedButton(
              onPressed: () {
                ref.read(snackBarServiceProvider).show(SnackBarConfig(
                    type: SnackbarType.info,
                    title: 'Purchases restored',
                    message: 'Managed to restore Supporter-Status!'));
              },
              child: const Text('SNACKBAR')),

          // TextButton(onPressed: () => test(ref), child: const Text('Copy Chart OPTIONS')),
          // OutlinedButton(onPressed: () => dummyDownload(), child: const Text('Download file!')),
          // // Expanded(child: WebRtcCam()),
          // AsyncValueWidget(
          //   value: ref.watch(printerSelectedProvider.selectAs((p) => p.bedMesh)),
          //   data: (data) => getMeshChart(data),
          // ),
        ],
    );

    if (context.isLargerThanCompact) {
      body = NavigationRailView(page: body);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev'),
      ),
      drawer: const NavigationDrawerWidget(),
      body: body,
    );
  }

  stateActivity() async {
    final liveActivitiesPlugin = LiveActivities();
    logger.i('#1');
    await liveActivitiesPlugin.init(appGroupId: 'group.mobileraker.liveactivity');
    logger.i('#2');
    var activityState = await liveActivitiesPlugin.getActivityState('123123');
    logger.i('Got state message: $activityState');
  }

  v2Activity(WidgetRef ref) async {
    ref.read(v2LiveActivityProvider).initialize();
  }

  startLiveActivity(WidgetRef ref) async {
    ref.read(liveActivityServiceProvider).disableClearing();
    var liveActivities = ref.read(liveActivityProvider);

    // _liveActivitiesPlugin.activityUpdateStream.listen((event) {
    //   logger.wtf('xxxLiveActivityUpdate: $event');
    // });

    Map<String, dynamic> data = {
      'progress': 0.2,
      'state': 'printing',
      'file': 'Benchy.gcode' ?? 'Unknown',
      'eta': DateTime.now().add(const Duration(seconds: 60 * 200)).secondsSinceEpoch ?? -1,

      // Not sure yet if I want to use this
      'printStartTime': DateTime.now().secondsSinceEpoch ?? -1,

      // Labels
      'primary_color_dark': Colors.yellow.value,
      'primary_color_light': Colors.pinkAccent.value,
      'machine_name': 'Voronator',
      'eta_label': tr('pages.dashboard.general.print_card.eta'),
      'elapsed_label': tr('pages.dashboard.general.print_card.elapsed'),
      'remaining_label': tr('pages.dashboard.general.print_card.remaining'),
      for (var state in PrintState.values) '${state.name}_label': state.displayName,
    };

    var activityId = await liveActivities.createActivity(
      data,
      removeWhenAppIsKilled: true,
    );
    logger.i('Created activity with id: $activityId');
    _bla = activityId;
    var pushToken = await liveActivities.getPushToken(activityId!);
    logger.i('LiveActivity PushToken: $pushToken');
  }

  updateLiveActivity(WidgetRef ref) async {
    if (_bla == null) return;

    var liveActivities = ref.read(liveActivityProvider);
    // _liveActivitiesPlugin.activityUpdateStream.listen((event) {
    //   logger.wtf('xxxLiveActivityUpdate: $event');
    // });

    Map<String, dynamic> data = {
      'progress': 1,
      'state': 'printing',
      'file': 'Benchy.gcode' ?? 'Unknown',
      'eta': DateTime.now().add(const Duration(seconds: 60 * 120)).secondsSinceEpoch ?? -1,

      // Not sure yet if I want to use this
      'printStartTime': DateTime.now().secondsSinceEpoch ?? -1,

      // Labels
      'primary_color_dark': Colors.red.value,
      'primary_color_light': Colors.pinkAccent.value,
      'machine_name': 'Voronator',
      'eta_label': tr('pages.dashboard.general.print_card.eta'),
      'elapsed_label': tr('pages.dashboard.general.print_card.elapsed'),
      'remaining_label': tr('pages.dashboard.general.print_card.remaining'),
      'completed_label': tr('general.completed'),
    };

    var activityId = await liveActivities.updateActivity(
      _bla!,
      data,
    );
    logger.i('UPDATED activity with id: $_bla -> $activityId');
  }

//   var test = 44.4;
//   var dowloadUri = Uri.parse('http://192.168.178.135/server/files/timelapse/file_example_MP4_1920_18MG.mp4');
//   final tmpDir = await getTemporaryDirectory();
//   final tmpFile = File('${tmpDir.path}/$filess');
//
//   workerManager.executeWithPort<File, double>((port) async {
//     await setupIsolateLogger();
//     return isolateDownloadFile(port: port, targetUri: dowloadUri, downloadPath: tmpFile.path);
//   }, onMessage: (message) {
//     logger.i('Got new message from port: $message');
//   }).then((value) => logger.i('Execute done: ${value}'));
// }
}

void dummyDownload() async {
  final tmpDir = await getTemporaryDirectory();
  final File file = File('${tmpDir.path}/dummy.zip');

  var dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  // Some file that is rather "large" and takes longer to download
  var uri = 'https://github.com/cfug/flutter.cn/archive/refs/heads/main.zip';

  var response = await dio.download(
    uri,
    file.path,
    onReceiveProgress: (received, total) {
      logger.i('Received: $received, Total: $total');
    },
  );
  print('Download is done: ${response.statusCode}');
}

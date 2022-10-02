import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobileraker/data/dto/power/power_state.dart';

part 'power_device.freezed.dart';
part 'power_device.g.dart';

enum PowerDeviceType {
  gpio,
  klipper_device,
  rf,
  tplink_smartplug,
  tasmota,
  shelly,
  homeseer,
  homeassistant,
  loxonev1,
  smartthings,
  mqtt,
  hue
}

@freezed
class PowerDevice with _$PowerDevice {
  const factory PowerDevice({
    @JsonKey(name: 'device')  required String name,
    required PowerState status,
    required PowerDeviceType type,
    @JsonKey(name: 'locked_while_printing') @Default(false) bool lockedWhilePrinting,

  }) = _PowerDevice;

  factory PowerDevice.fromJson(Map<String, dynamic> json) => _$PowerDeviceFromJson(json);

}

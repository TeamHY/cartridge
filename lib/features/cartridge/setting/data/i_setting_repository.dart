library;

import 'package:cartridge/features/cartridge/setting/domain/models/app_setting.dart';

abstract class ISettingRepository {
  Future<AppSetting> load();
  Future<void> save(AppSetting setting);
}

import 'package:cartridge/features/isaac/options/domain/models/isaac_options_schema.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class OptionPresetValidators {
  static String? validate({
    required BuildContext ctx,
    required String name,
    required bool isFullscreen,
    required String widthText,
    required String heightText,
    required String xText,
    required String yText,
  }) {
    final loc = AppLocalizations.of(ctx);
    final n = name.trim();
    if (n.isEmpty) return loc.option_window_error_name_required;
    if (isFullscreen) return null;

    final width  = int.tryParse(widthText.trim());
    final height = int.tryParse(heightText.trim());
    final posX   = int.tryParse(xText.trim());
    final posY   = int.tryParse(yText.trim());

    if (width == null || width < IsaacOptionsSchema.winMin || width > IsaacOptionsSchema.winMax) {
      return loc.option_window_error_width_range;
    }
    if (height == null || height < IsaacOptionsSchema.winMin || height > IsaacOptionsSchema.winMax) {
      return loc.option_window_error_height_range;
    }
    if (posX == null || posX < IsaacOptionsSchema.posMin || posX > IsaacOptionsSchema.posMax) {
      return loc.option_window_error_posx_range;
    }
    if (posY == null || posY < IsaacOptionsSchema.posMin || posY > IsaacOptionsSchema.posMax) {
      return loc.option_window_error_posy_range;
    }
    return null;
  }
}

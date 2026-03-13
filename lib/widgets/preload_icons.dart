import 'package:flutter/material.dart';

/// Renders all Material Icons used in the app at zero opacity inside a
/// clipped 0×0 box.  Unlike [Offstage], [Opacity] still **paints** its
/// children, which forces CanvasKit to rasterise every glyph into its
/// glyph cache.  Subsequent screens that use the same icons get an
/// instant hit — no white-square flash.
///
/// Place this widget as a [Positioned] child inside the shell's [Stack].
class PreloadIcons extends StatelessWidget {
  const PreloadIcons({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 0,
      height: 0,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxWidth: 500,
        maxHeight: 2000,
        child: Opacity(
          opacity: 0,
          child: Wrap(
            children: [
              // All icons used across the app — forces glyph rasterisation
              Icon(Icons.access_time_rounded),
              Icon(Icons.account_tree_rounded),
              Icon(Icons.add_circle_outline),
              Icon(Icons.add_circle_outline_rounded),
              Icon(Icons.add_rounded),
              Icon(Icons.arrow_back_rounded),
              Icon(Icons.arrow_forward_rounded),
              Icon(Icons.auto_awesome_rounded),
              Icon(Icons.auto_fix_high_rounded),
              Icon(Icons.bar_chart_rounded),
              Icon(Icons.bedtime_outlined),
              Icon(Icons.bolt_rounded),
              Icon(Icons.check_circle_outline_rounded),
              Icon(Icons.check_circle_rounded),
              Icon(Icons.check_rounded),
              Icon(Icons.chevron_left_rounded),
              Icon(Icons.chevron_right_rounded),
              Icon(Icons.clear_rounded),
              Icon(Icons.close_rounded),
              Icon(Icons.copy_rounded),
              Icon(Icons.delete_outline_rounded),
              Icon(Icons.download_outlined),
              Icon(Icons.drag_handle_rounded),
              Icon(Icons.edit_outlined),
              Icon(Icons.error_outline_rounded),
              Icon(Icons.favorite_border_rounded),
              Icon(Icons.favorite_rounded),
              Icon(Icons.flag_outlined),
              Icon(Icons.flag_rounded),
              Icon(Icons.flash_on_rounded),
              Icon(Icons.folder_open_rounded),
              Icon(Icons.folder_outlined),
              Icon(Icons.folder_rounded),
              Icon(Icons.format_quote_rounded),
              Icon(Icons.history_rounded),
              Icon(Icons.info_outline_rounded),
              Icon(Icons.keyboard_arrow_down_rounded),
              Icon(Icons.keyboard_arrow_up_rounded),
              Icon(Icons.language_outlined),
              Icon(Icons.layers_outlined),
              Icon(Icons.layers_rounded),
              Icon(Icons.lightbulb_outline_rounded),
              Icon(Icons.local_fire_department_rounded),
              Icon(Icons.login_rounded),
              Icon(Icons.logout_rounded),
              Icon(Icons.more_vert_rounded),
              Icon(Icons.notifications_outlined),
              Icon(Icons.open_in_new_rounded),
              Icon(Icons.open_with_rounded),
              Icon(Icons.palette_outlined),
              Icon(Icons.play_arrow_rounded),
              Icon(Icons.remove_circle_outline),
              Icon(Icons.schedule_rounded),
              Icon(Icons.school_rounded),
              Icon(Icons.search_off_rounded),
              Icon(Icons.search_rounded),
              Icon(Icons.settings_outlined),
              Icon(Icons.sort_rounded),
              Icon(Icons.swap_horiz_rounded),
              Icon(Icons.today_rounded),
              Icon(Icons.touch_app_rounded),
              Icon(Icons.translate_rounded),
              Icon(Icons.tune_outlined),
              Icon(Icons.upload_outlined),
              Icon(Icons.visibility_off_rounded),
              Icon(Icons.visibility_rounded),
              Icon(Icons.wifi_off_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

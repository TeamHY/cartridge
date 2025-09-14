import 'package:fluent_ui/fluent_ui.dart';
import 'section_card.dart';

class RecordLeftPanelGrid extends StatelessWidget {
  const RecordLeftPanelGrid({
    super.key,
    required this.topInfo,
    required this.heroes,
    required this.bottom,
  });

  final SectionCard topInfo;
  final SectionCard heroes;
  final SectionCard bottom;

  @override
  Widget build(BuildContext context) {
    return Column(children: [topInfo, heroes, bottom]);
  }
}

class RecordRightPanelCurrentGrid extends StatelessWidget {
  const RecordRightPanelCurrentGrid({
    super.key,
    required this.header,
    required this.allowedDashboard,
  });

  final SectionCard header;
  final SectionCard allowedDashboard;

  @override
  Widget build(BuildContext context) {
    return Column(children: [header, allowedDashboard]);
  }
}

class RecordRightPanelPastGrid extends StatelessWidget {
  const RecordRightPanelPastGrid({super.key, required this.rankingBoard});
  final SectionCard rankingBoard;

  @override
  Widget build(BuildContext context) => rankingBoard;
}

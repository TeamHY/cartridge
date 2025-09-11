import 'package:flutter/material.dart';

import 'package:cartridge/features/cartridge/instances/presentation/pages/instance_detail_page.dart';
import 'package:cartridge/features/cartridge/instances/presentation/pages/instance_list.dart';


class InstancePage extends StatefulWidget {
  const InstancePage({super.key});

  @override
  State<InstancePage> createState() => _InstancePageState();
}

class _InstancePageState extends State<InstancePage> {
  String? selectedInstanceId;
  String? selectedInstanceName;

  void openDetail(String instanceId, String instanceName) {
    setState(() {
      selectedInstanceId = instanceId;
      selectedInstanceName = instanceName;
    });
  }

  void goBack() {
    setState(() {
      selectedInstanceId = null;
      selectedInstanceName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: selectedInstanceId != null ?
        InstanceDetailPage(
          instanceId: selectedInstanceId!,
          instanceName: selectedInstanceName ?? '',
          onBack: goBack,
        ) : InstanceListPage(onSelect: openDetail)
    );
  }
}

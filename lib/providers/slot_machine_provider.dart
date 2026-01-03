import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

typedef SlotList = List<List<String>>;

const String groupPrefix = '__GROUP__:';

class SlotMachineNotifier extends ChangeNotifier {
  SlotMachineNotifier() {
    loadSlot();
  }

  SlotList _slots = [];

  SlotList get slots => _slots;

  void loadSlot() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}\\slot.json');

    if (!(await file.exists())) {
      return;
    }

    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    _slots = [];

    if (json['slots'] != null) {
      _slots = (json['slots'] as List)
          .map((e) => (e as List).map((e) => e as String).toList())
          .toList();
    }

    notifyListeners();
  }

  void saveSlot() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final file = File('${appSupportDir.path}\\slot.json');

    file.writeAsString(jsonEncode({'slots': slots}));
  }

  void addSlot(String defaultText, {List<String>? items}) {
    _slots.add(items ?? [defaultText]);

    saveSlot();
    notifyListeners();
  }

  void addGroupSlot(String groupName) {
    _slots.add(['$groupPrefix$groupName']);

    saveSlot();
    notifyListeners();
  }

  bool isGroupSlot(List<String> slot) {
    return slot.length == 1 && slot[0].startsWith(groupPrefix);
  }

  String? getGroupName(List<String> slot) {
    if (isGroupSlot(slot)) {
      return slot[0].substring(groupPrefix.length);
    }
    return null;
  }

  void removeSlot(int slotIndex) {
    slots.removeAt(slotIndex);

    saveSlot();
    notifyListeners();
  }

  void setSlot(int slotIndex, List<String> items) {
    slots[slotIndex] = items;

    saveSlot();
    notifyListeners();
  }
}

final slotMachineProvider = ChangeNotifierProvider<SlotMachineNotifier>((ref) {
  return SlotMachineNotifier();
});

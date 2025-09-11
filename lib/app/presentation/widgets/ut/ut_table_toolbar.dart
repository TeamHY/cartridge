import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import 'package:cartridge/theme/theme.dart';
import 'ut_table.dart';

class UTTableToolbar<T> extends StatelessWidget {
  const UTTableToolbar({
    super.key,
    required this.showSearch,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchHintText,
    required this.onQueryChanged,
    required this.onSubmit,
    required this.onClearSearch,
    required this.quickFilters,
    required this.activeFilterIds,
    required this.onToggleFilter,
    required this.compact,
    required this.onToggleCompact,
  });

  final bool showSearch;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchHintText;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSubmit;
  final VoidCallback onClearSearch;

  final List<UTQuickFilter<T>> quickFilters;
  final Set<String> activeFilterIds;
  final void Function(String id, bool enable) onToggleFilter;

  final bool compact;
  final ValueChanged<bool> onToggleCompact;

  @override
  Widget build(BuildContext context) {
    final hasFilters = quickFilters.isNotEmpty;

    final searchBox = (!showSearch)
        ? const SizedBox.shrink()
        : Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              if (searchController.text.isNotEmpty) {
                onQueryChanged('');
                searchController.clear();
              } else {
                FocusScope.of(context).unfocus();
              }
              return null;
            },
          ),
        },
        child: TextBox(
          focusNode: searchFocusNode,
          controller: searchController,
          placeholder: searchHintText,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSubmit(),
          onChanged: onQueryChanged,
          suffix: searchController.text.isEmpty
              ? null
              : IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: () {
              onQueryChanged('');
              searchController.clear();
            },
          ),
        ),
      ),
    );

    final filters = (!hasFilters)
        ? const SizedBox.shrink()
        : Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final f in quickFilters)
          activeFilterIds.contains(f.id)
              ? FilledButton(
            child: Text(f.label),
            onPressed: () => onToggleFilter(f.id, false),
          )
              : Button(
            child: Text(f.label),
            onPressed: () => onToggleFilter(f.id, true),
          ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showSearch) Expanded(child: searchBox),
        if (showSearch && hasFilters) Gaps.w8,
        if (hasFilters) filters,
        Gaps.w8,
        ToggleSwitch(
          checked: compact,
          content: const Text('Compact'),
          onChanged: onToggleCompact,
        ),
      ],
    );
  }
}

import 'package:cartridge/models/game_config.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';

class GameConfigFormView extends StatefulWidget {
  final GameConfig? config;
  final ValueChanged<GameConfig> onConfigChanged;
  final bool Function() hasUnsavedChanges;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const GameConfigFormView({
    super.key,
    required this.config,
    required this.onConfigChanged,
    required this.hasUnsavedChanges,
    required this.onSave,
    required this.onReset,
  });

  @override
  State<GameConfigFormView> createState() => _GameConfigFormViewState();
}

class _GameConfigFormViewState extends State<GameConfigFormView> {
  late TextEditingController _nameController;
  late TextEditingController _windowWidthController;
  late TextEditingController _windowHeightController;
  late TextEditingController _windowPosXController;
  late TextEditingController _windowPosYController;

  final Map<String, String?> _validationErrors = {};
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _widthFocusNode = FocusNode();
  final FocusNode _heightFocusNode = FocusNode();
  final FocusNode _posXFocusNode = FocusNode();
  final FocusNode _posYFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _addListeners();
  }

  @override
  void didUpdateWidget(covariant GameConfigFormView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != oldWidget.config) {
      _updateControllers();
    }
  }

  @override
  void dispose() {
    _removeListeners();
    _disposeControllers();
    _disposeFocusNodes();
    super.dispose();
  }

  void _initializeControllers() {
    final config = widget.config;
    _nameController = TextEditingController(text: config?.name ?? '');
    _windowWidthController =
        TextEditingController(text: config?.windowWidth.toString() ?? '960');
    _windowHeightController =
        TextEditingController(text: config?.windowHeight.toString() ?? '540');
    _windowPosXController =
        TextEditingController(text: config?.windowPosX.toString() ?? '100');
    _windowPosYController =
        TextEditingController(text: config?.windowPosY.toString() ?? '100');
  }

  void _updateControllers() {
    final config = widget.config;
    _nameController.text = config?.name ?? '';
    _windowWidthController.text = config?.windowWidth.toString() ?? '960';
    _windowHeightController.text = config?.windowHeight.toString() ?? '540';
    _windowPosXController.text = config?.windowPosX.toString() ?? '100';
    _windowPosYController.text = config?.windowPosY.toString() ?? '100';
    _clearValidationErrors();
  }

  void _addListeners() {
    _nameController.addListener(_onNameChanged);
    _windowWidthController.addListener(_onWindowWidthChanged);
    _windowHeightController.addListener(_onWindowHeightChanged);
    _windowPosXController.addListener(_onWindowPosXChanged);
    _windowPosYController.addListener(_onWindowPosYChanged);
  }

  void _removeListeners() {
    _nameController.removeListener(_onNameChanged);
    _windowWidthController.removeListener(_onWindowWidthChanged);
    _windowHeightController.removeListener(_onWindowHeightChanged);
    _windowPosXController.removeListener(_onWindowPosXChanged);
    _windowPosYController.removeListener(_onWindowPosYChanged);
  }

  void _disposeControllers() {
    _nameController.dispose();
    _windowWidthController.dispose();
    _windowHeightController.dispose();
    _windowPosXController.dispose();
    _windowPosYController.dispose();
  }

  void _disposeFocusNodes() {
    _nameFocusNode.dispose();
    _widthFocusNode.dispose();
    _heightFocusNode.dispose();
    _posXFocusNode.dispose();
    _posYFocusNode.dispose();
  }

  void _onNameChanged() => _updateConfig();
  void _onWindowWidthChanged() => _updateConfig();
  void _onWindowHeightChanged() => _updateConfig();
  void _onWindowPosXChanged() => _updateConfig();
  void _onWindowPosYChanged() => _updateConfig();

  void _updateConfig() {
    if (widget.config == null) return;

    try {
      final updatedConfig = GameConfig(
        id: widget.config!.id,
        name: _nameController.text,
        windowWidth: int.tryParse(_windowWidthController.text) ?? 960,
        windowHeight: int.tryParse(_windowHeightController.text) ?? 540,
        windowPosX: int.tryParse(_windowPosXController.text) ?? 100,
        windowPosY: int.tryParse(_windowPosYController.text) ?? 100,
      );

      widget.onConfigChanged(updatedConfig);
      _validateForm();
    } catch (e) {}
  }

  void _validateForm() {
    final errors = <String, String?>{};

    if (_nameController.text.trim().isEmpty) {
      errors['name'] = AppLocalizations.of(context).validation_name_required;
    }

    final width = int.tryParse(_windowWidthController.text);
    if (width == null || width < 320) {
      errors['windowWidth'] = AppLocalizations.of(context).validation_width_minimum;
    }

    final height = int.tryParse(_windowHeightController.text);
    if (height == null || height < 240) {
      errors['windowHeight'] = AppLocalizations.of(context).validation_height_minimum;
    }

    if (int.tryParse(_windowPosXController.text) == null) {
      errors['windowPosX'] = AppLocalizations.of(context).validation_number_required;
    }

    if (int.tryParse(_windowPosYController.text) == null) {
      errors['windowPosY'] = AppLocalizations.of(context).validation_number_required;
    }

    setState(() {
      _validationErrors.clear();
      _validationErrors.addAll(errors);
    });
  }

  void _clearValidationErrors() {
    setState(() {
      _validationErrors.clear();
    });
  }

  bool get _isFormValid => _validationErrors.isEmpty && widget.config != null;

  void _focusFirstInvalidField() {
    if (_validationErrors.containsKey('name')) {
      _nameFocusNode.requestFocus();
    } else if (_validationErrors.containsKey('windowWidth')) {
      _widthFocusNode.requestFocus();
    } else if (_validationErrors.containsKey('windowHeight')) {
      _heightFocusNode.requestFocus();
    } else if (_validationErrors.containsKey('windowPosX')) {
      _posXFocusNode.requestFocus();
    } else if (_validationErrors.containsKey('windowPosY')) {
      _posYFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    if (widget.config == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            AppLocalizations.of(context).game_config_select_or_create,
            style: FluentTheme.of(context).typography.body,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(left: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildNameField(loc),
                  const SizedBox(height: 24),
                  _buildWindowSizeSection(loc),
                  const SizedBox(height: 24),
                  _buildWindowPositionSection(loc),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButtons(context, loc),
        ],
      ),
    );
  }

  Widget _buildNameField(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoLabel(
          label: loc.game_config_name_label,
          child: TextBox(
            controller: _nameController,
            focusNode: _nameFocusNode,
            placeholder: loc.game_config_fallback_name,
            onChanged: (value) {
              if (_validationErrors.containsKey('name')) {
                _validateForm();
              }
            },
          ),
        ),
        if (_validationErrors['name'] != null) ...[
          const SizedBox(height: 4),
          Text(
            _validationErrors['name']!,
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWindowSizeSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.game_config_window_size_title,
          style: FluentTheme.of(context).typography.subtitle,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoLabel(
                    label: loc.game_config_window_width_label,
                    child: TextBox(
                      controller: _windowWidthController,
                      focusNode: _widthFocusNode,
                      placeholder: '960',
                      onChanged: (value) {
                        if (_validationErrors.containsKey('windowWidth')) {
                          _validateForm();
                        }
                      },
                    ),
                  ),
                  if (_validationErrors['windowWidth'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _validationErrors['windowWidth']!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoLabel(
                    label: loc.game_config_window_height_label,
                    child: TextBox(
                      controller: _windowHeightController,
                      focusNode: _heightFocusNode,
                      placeholder: '540',
                      onChanged: (value) {
                        if (_validationErrors.containsKey('windowHeight')) {
                          _validateForm();
                        }
                      },
                    ),
                  ),
                  if (_validationErrors['windowHeight'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _validationErrors['windowHeight']!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWindowPositionSection(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.game_config_window_position_title,
          style: FluentTheme.of(context).typography.subtitle,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoLabel(
                    label: loc.game_config_window_pos_x_label,
                    child: TextBox(
                      controller: _windowPosXController,
                      focusNode: _posXFocusNode,
                      placeholder: '100',
                      onChanged: (value) {
                        if (_validationErrors.containsKey('windowPosX')) {
                          _validateForm();
                        }
                      },
                    ),
                  ),
                  if (_validationErrors['windowPosX'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _validationErrors['windowPosX']!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoLabel(
                    label: loc.game_config_window_pos_y_label,
                    child: TextBox(
                      controller: _windowPosYController,
                      focusNode: _posYFocusNode,
                      placeholder: '100',
                      onChanged: (value) {
                        if (_validationErrors.containsKey('windowPosY')) {
                          _validateForm();
                        }
                      },
                    ),
                  ),
                  if (_validationErrors['windowPosY'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _validationErrors['windowPosY']!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations loc) {
    final hasChanges = widget.hasUnsavedChanges();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        hasChanges
            ? Button(
                onPressed: widget.onReset,
                child: Text(loc.common_cancel),
              )
            : Button(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.common_close),
              ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _isFormValid && hasChanges
              ? () {
                  _validateForm();
                  if (_isFormValid) {
                    widget.onSave();
                  } else {
                    _focusFirstInvalidField();
                  }
                }
              : null,
          child: Text(loc.common_save),
        ),
      ],
    );
  }
}

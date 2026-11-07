import 'package:cartridge/pages/home/components/sub_page_header.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/services/steam_save_service.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SaveApplyView extends ConsumerStatefulWidget {
  const SaveApplyView({super.key});

  @override
  ConsumerState<SaveApplyView> createState() => _SaveApplyViewState();
}

class _SaveApplyViewState extends ConsumerState<SaveApplyView> {
  final SteamSaveService _steamSaveService = SteamSaveService();

  late TextEditingController _steamPathController;

  List<SteamUser> _users = const [];
  String? _selectedUserId;
  int _selectedSlot = 1;

  bool _isLoadingUsers = false;
  bool _isApplying = false;
  bool _isError = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _steamPathController = TextEditingController();
    _detectSteamPathAndLoadUsers();
  }

  @override
  void dispose() {
    _steamPathController.dispose();
    super.dispose();
  }

  Future<void> _detectSteamPathAndLoadUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _statusMessage = null;
    });

    final setting = ref.read(settingProvider);
    final steamPath = await _steamSaveService.detectSteamPath(
      isaacPath: setting.isaacPath,
    );

    if (!mounted) {
      return;
    }

    if (steamPath == null) {
      setState(() {
        _isLoadingUsers = false;
        _isError = true;
        _statusMessage = '스팀 경로를 찾지 못했습니다. 경로를 직접 입력해주세요.';
      });
      return;
    }

    _steamPathController.text = steamPath;
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    final steamPath = _steamPathController.text.trim();
    if (steamPath.isEmpty) {
      setState(() {
        _users = const [];
        _selectedUserId = null;
        _isLoadingUsers = false;
        _isError = true;
        _statusMessage = '스팀 경로를 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoadingUsers = true;
      _statusMessage = null;
    });

    try {
      final users =
          await _steamSaveService.getLoggedInUsers(steamPath: steamPath);
      if (!mounted) {
        return;
      }

      setState(() {
        _users = users;
        if (_users.isEmpty) {
          _selectedUserId = null;
          _isError = true;
          _statusMessage = '로그인한 스팀 유저를 찾지 못했습니다.';
        } else {
          final isCurrentUserValid = _users.any((u) => u.id == _selectedUserId);
          _selectedUserId =
              isCurrentUserValid ? _selectedUserId : _users.first.id;
          _isError = false;
          _statusMessage = null;
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _users = const [];
        _selectedUserId = null;
        _isError = true;
        _statusMessage = '유저 목록을 불러오지 못했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  Future<void> _applySave() async {
    final steamPath = _steamPathController.text.trim();
    final userId = _selectedUserId;

    if (steamPath.isEmpty) {
      setState(() {
        _isError = true;
        _statusMessage = '스팀 경로를 입력해주세요.';
      });
      return;
    }

    if (userId == null || userId.isEmpty) {
      setState(() {
        _isError = true;
        _statusMessage = '적용할 스팀 유저를 선택해주세요.';
      });
      return;
    }

    setState(() {
      _isApplying = true;
      _statusMessage = null;
    });

    try {
      await _steamSaveService.applyAllCompletionSave(
        steamPath: steamPath,
        userId: userId,
        slot: _selectedSlot,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isError = false;
        _statusMessage = '유저 $userId 의 슬롯 $_selectedSlot 에 올클 세이브를 적용했습니다.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isError = true;
        _statusMessage = '세이브 적용에 실패했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    SteamUser? selectedUser;
    for (final user in _users) {
      if (user.id == _selectedUserId) {
        selectedUser = user;
        break;
      }
    }

    return Container(
      color: c.surface1,
      child: Column(
        children: [
          SubPageHeader(
            title: '올클 세이브 적용',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '세이브 적용 대상 선택',
                    style: AppTextStyles.bodyStrong,
                  ),
                  const SizedBox(height: 8.0),
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppLabeled(
                            label: '스팀 설치 경로',
                            child: AppTextField(
                              controller: _steamPathController,
                              mono: true,
                              placeholder: r'C:\Program Files (x86)\Steam',
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Row(
                            children: [
                              AppButton(
                                onPressed: _isLoadingUsers
                                    ? null
                                    : _detectSteamPathAndLoadUsers,
                                child: const Text('자동 탐지'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppLabeled(
                            label: '적용할 스팀 유저',
                            child: Row(
                              children: [
                                Expanded(
                                  child: AppSelect<String>(
                                    value: _selectedUserId,
                                    isExpanded: true,
                                    items: _users
                                        .map(
                                          (user) => AppSelectItem<String>(
                                            value: user.id,
                                            child: Text(
                                              '${user.displayName}${user.isMostRecent ? ' (최근 로그인)' : ''}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _isApplying
                                        ? null
                                        : (value) {
                                            if (value == null) {
                                              return;
                                            }
                                            setState(() {
                                              _selectedUserId = value;
                                            });
                                          },
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                AppIconButton(
                                  tooltip: '유저 새로고침',
                                  icon: const PhosphorIcon(
                                      PhosphorIconsRegular.arrowClockwise),
                                  onPressed:
                                      _isLoadingUsers ? null : _loadUsers,
                                ),
                              ],
                            ),
                          ),
                          if (selectedUser != null) ...[
                            const SizedBox(height: 8.0),
                            Text(
                              '선택된 유저: ${selectedUser.displayName}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                          const SizedBox(height: 16.0),
                          AppLabeled(
                            label: '덮어쓸 슬롯',
                            child: AppSelect<int>(
                              value: _selectedSlot,
                              items: const [
                                AppSelectItem(value: 1, child: Text('슬롯 1')),
                                AppSelectItem(value: 2, child: Text('슬롯 2')),
                                AppSelectItem(value: 3, child: Text('슬롯 3')),
                              ],
                              onChanged: _isApplying
                                  ? null
                                  : (value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() {
                                        _selectedSlot = value;
                                      });
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  if (_statusMessage != null) ...[
                    AppNotice(
                      severity: _isError
                          ? AppNoticeSeverity.error
                          : AppNoticeSeverity.success,
                      title: Text(_isError ? '실패' : '완료'),
                      content: Text(_statusMessage!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: c.surface1,
              boxShadow: [
                BoxShadow(
                  color: c.line,
                  blurRadius: 2,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.primary(
                    onPressed:
                        _isApplying || _isLoadingUsers ? null : _applySave,
                    child: _isApplying
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('적용 중...'),
                            ],
                          )
                        : const Text('올클 세이브 적용'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

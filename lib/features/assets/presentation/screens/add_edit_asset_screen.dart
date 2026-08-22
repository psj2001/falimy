import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:falimy/app/theme.dart';
import 'package:falimy/core/currency/app_currency.dart';
import 'package:falimy/core/widgets/app_text_field.dart';
import 'package:falimy/core/widgets/primary_button.dart';
import 'package:falimy/core/widgets/result_dialog.dart';
import 'package:falimy/features/assets/domain/asset_category.dart';
import 'package:falimy/features/assets/domain/asset_owner.dart';
import 'package:falimy/features/assets/domain/entities/family_asset.dart';
import 'package:falimy/features/assets/domain/insurance_remaining.dart';
import 'package:falimy/features/assets/presentation/providers/asset_notifier.dart';
import 'package:falimy/features/onboarding/presentation/providers/onboarding_notifier.dart';

class AddEditAssetScreen extends ConsumerStatefulWidget {
  const AddEditAssetScreen({
    super.key,
    this.existing,
    this.initialCategory,
    this.initialOwnerId,
  });

  final FamilyAsset? existing;
  final AssetCategory? initialCategory;
  final String? initialOwnerId;

  @override
  ConsumerState<AddEditAssetScreen> createState() => _AddEditAssetScreenState();
}

class _AddEditAssetScreenState extends ConsumerState<AddEditAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  final _extraControllers = <String, TextEditingController>{};

  late AssetCategory _category;
  late String _ownerId;
  late String _ownerName;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _category =
        existing?.category ?? widget.initialCategory ?? AssetCategory.vehicles;

    final profile = ref.read(onboardingNotifierProvider);
    final owners = ownersFromProfile(profile);
    final fallback = owners.isNotEmpty
        ? owners.first
        : const AssetOwnerOption(id: 'self', name: 'You', chipLabel: 'You');

    if (existing != null) {
      _ownerId = existing.ownerId;
      _ownerName = existing.ownerName;
      _nameController.text = existing.name;
      _valueController.text = existing.value == existing.value.roundToDouble()
          ? existing.value.toStringAsFixed(0)
          : existing.value.toString();
      _notesController.text = existing.notes ?? '';
    } else {
      final preferred = widget.initialOwnerId;
      final match = owners.where((o) => o.id == preferred).toList();
      final owner = match.isNotEmpty ? match.first : fallback;
      _ownerId = owner.id;
      _ownerName = owner.name;
    }

    _rebuildExtraControllers(seed: existing?.fields);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    for (final controller in _extraControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _rebuildExtraControllers({Map<String, String>? seed}) {
    final previous = List<TextEditingController>.from(_extraControllers.values);
    _extraControllers.clear();
    for (final field in _category.extraFields) {
      _extraControllers[field.key] = TextEditingController(
        text: seed?[field.key] ?? '',
      );
    }
    if (previous.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in previous) {
        controller.dispose();
      }
    });
  }

  void _selectCategory(AssetCategory category) {
    if (category == _category) return;
    final previous = {
      for (final entry in _extraControllers.entries)
        entry.key: entry.value.text,
    };
    setState(() {
      _category = category;
      _rebuildExtraControllers(seed: previous);
    });
  }

  void _selectOwner(AssetOwnerOption owner) {
    setState(() {
      _ownerId = owner.id;
      _ownerName = owner.name;
    });
  }

  Future<void> _pickDate(AssetFieldSpec field) async {
    final controller = _extraControllers[field.key];
    if (controller == null) return;
    DateTime? parsed;
    final raw = controller.text.trim();
    if (raw.isNotEmpty) {
      parsed = parseAssetDate(raw);
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      controller.text = assetDateFormat.format(picked);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    for (final field in _category.extraFields) {
      if (!field.required) continue;
      final text = _extraControllers[field.key]?.text.trim() ?? '';
      if (text.isEmpty) {
        await showResultDialog(
          context,
          kind: ResultDialogKind.failure,
          message: 'Please fill in ${field.label.toLowerCase()}.',
        );
        return;
      }
    }

    final value = double.tryParse(
      _valueController.text.trim().replaceAll(',', ''),
    );
    if (value == null || value < 0) return;

    final fields = <String, String>{};
    for (final field in _category.extraFields) {
      final text = _extraControllers[field.key]?.text.trim() ?? '';
      if (text.isNotEmpty) fields[field.key] = text;
    }

    final insuranceStart = parseAssetDate(fields['insuranceStart']);
    final insuranceEnd = parseAssetDate(fields['insuranceEnd']);
    if (insuranceStart != null &&
        insuranceEnd != null &&
        insuranceEnd.isBefore(insuranceStart)) {
      await showResultDialog(
        context,
        kind: ResultDialogKind.failure,
        message: 'Insurance end date must be after the start date.',
      );
      return;
    }

    final now = DateTime.now();
    final existing = widget.existing;
    final asset = FamilyAsset(
      id: existing?.id ?? newAssetId(),
      category: _category,
      name: _nameController.text.trim(),
      ownerId: _ownerId,
      ownerName: _ownerName,
      value: value,
      fields: fields,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final saved = await ref.read(assetNotifierProvider.notifier).upsert(asset);
    if (!mounted) return;
    if (saved == null) {
      final error = ref.read(assetNotifierProvider).error;
      await showResultDialog(
        context,
        kind: ResultDialogKind.failure,
        message: error ?? 'Something went wrong.',
      );
      return;
    }

    await showResultDialog(
      context,
      kind: ResultDialogKind.success,
      message: _isEditing
          ? 'Asset updated.'
          : '${_category.title} added to family wealth.',
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final owners = ownersFromProfile(ref.watch(onboardingNotifierProvider));
    final saving = ref.watch(assetNotifierProvider).isSaving;
    final currency = ref.watch(preferredCurrencyProvider);

    return Scaffold(
      backgroundColor: FalimyTheme.mistBlueSoft,
      body: Container(
        decoration: const BoxDecoration(gradient: FalimyTheme.screenGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: FalimyTheme.ink,
                    ),
                    Expanded(
                      child: Text(
                        _isEditing ? 'Edit asset' : 'Add asset',
                        style: const TextStyle(
                          color: FalimyTheme.ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      const _SectionLabel('Category'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final category in AssetCategory.values)
                            _ChoiceChip(
                              label: '${category.emoji}  ${category.title}',
                              selected: _category == category,
                              onTap: () => _selectCategory(category),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('Owner'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final owner in owners)
                            _ChoiceChip(
                              label: owner.chipLabel,
                              selected: _ownerId == owner.id,
                              onTap: () => _selectOwner(owner),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      for (final field in _category.extraFields.where(
                        (f) => f.type == AssetFieldType.choice,
                      )) ...[
                        _ExtraField(
                          spec: field,
                          controller: _extraControllers[field.key]!,
                          onPickDate: () => _pickDate(field),
                          currency: currency,
                          onChoice: (value) {
                            setState(() {
                              _extraControllers[field.key]!.text = value;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                      AppTextField(
                        label: _category.nameLabel,
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _valueController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Current value',
                          prefixText: AppCurrency.prefix(currency),
                        ),
                        validator: (value) {
                          final parsed = num.tryParse(
                            (value ?? '').trim().replaceAll(',', ''),
                          );
                          if (parsed == null || parsed < 0) {
                            return 'Enter the current value';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      for (final field in _category.extraFields.where(
                        (f) => f.type != AssetFieldType.choice,
                      )) ...[
                        _ExtraField(
                          spec: field,
                          controller: _extraControllers[field.key]!,
                          onPickDate: () => _pickDate(field),
                          currency: currency,
                          onChoice: (value) {
                            setState(() {
                              _extraControllers[field.key]!.text = value;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                      ],
                      AppTextField(
                        label: 'Notes',
                        controller: _notesController,
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: PrimaryButton(
                  label: _isEditing ? 'Save changes' : 'Save asset',
                  isLoading: saving,
                  onPressed: saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: FalimyTheme.ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.imagePath,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Ink(
          padding: EdgeInsets.fromLTRB(imagePath == null ? 14 : 8, 8, 14, 8),
          decoration: BoxDecoration(
            color: selected ? FalimyTheme.ink : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? FalimyTheme.ink : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imagePath != null) ...[
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Image.asset(imagePath!, fit: BoxFit.contain),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : FalimyTheme.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExtraField extends StatelessWidget {
  const _ExtraField({
    required this.spec,
    required this.controller,
    required this.onPickDate,
    required this.onChoice,
    required this.currency,
  });

  final AssetFieldSpec spec;
  final TextEditingController controller;
  final VoidCallback onPickDate;
  final ValueChanged<String> onChoice;
  final String currency;

  @override
  Widget build(BuildContext context) {
    switch (spec.type) {
      case AssetFieldType.choice:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(spec.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final choice in spec.choices)
                  _ChoiceChip(
                    label: choice,
                    selected: controller.text == choice,
                    imagePath: spec.choiceImages[choice],
                    onTap: () => onChoice(choice),
                  ),
              ],
            ),
          ],
        );
      case AssetFieldType.date:
        return AppTextField(
          label: spec.label,
          controller: controller,
          readOnly: true,
          onTap: onPickDate,
          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
        );
      case AssetFieldType.number:
        return TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            labelText: spec.label,
            suffixText: spec.suffix == 'AED' ? currency : spec.suffix,
          ),
          validator: spec.required
              ? (value) {
                  final parsed = num.tryParse(
                    (value ?? '').trim().replaceAll(',', ''),
                  );
                  if (parsed == null || parsed <= 0) {
                    return 'Enter ${spec.label.toLowerCase()}';
                  }
                  return null;
                }
              : null,
        );
      case AssetFieldType.text:
        return AppTextField(
          label: spec.label,
          controller: controller,
          textInputAction: TextInputAction.next,
          validator: spec.required
              ? (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Enter ${spec.label.toLowerCase()}';
                  }
                  return null;
                }
              : null,
        );
    }
  }
}

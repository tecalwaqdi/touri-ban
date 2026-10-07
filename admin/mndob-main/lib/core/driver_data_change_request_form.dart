import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/core/driver_data_change_request_service.dart';
import '/core/driver_dialogs.dart';
import '/core/driver_document_upload_service.dart';
import '/core/driver_license_document_fields.dart';
import '/core/driver_registration_validators.dart';
import '/design_system/design_system.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';

/// Maps change-request sections → editable field keys + optional document slots.
abstract final class DriverDataChangeFieldCatalog {
  DriverDataChangeFieldCatalog._();

  static const textFieldsBySection = <String, List<String>>{
    'personal_info': ['display_name', 'birth_date'],
    'vehicle': [
      'NameCar',
      'vehicle_make',
      'ModelCar',
      'vehicle_color',
      'seat_count',
      'text_type_car_mndob',
    ],
    'national_id': ['ID_hoyh_MNDOB'],
    'plate': ['number_lohh_car'],
    'location': ['region_display', 'city_display', 'mndob_vill_text', 'mdenh_aml'],
    'other': <String>[],
  };

  /// Document field key → upload slot id.
  static const docsBySection = <String, List<String>>{
    'personal_info': ['photo_url'],
    'national_id': ['doc_national_id'],
    'vehicle_registration': ['doc_vehicle_registration', 'img_id_car'],
    'driver_license': [
      DriverLicenseDocumentFields.front,
      DriverLicenseDocumentFields.back,
    ],
    'documents': [
      'photo_url',
      'doc_national_id',
      'doc_vehicle_registration',
      DriverLicenseDocumentFields.front,
      DriverLicenseDocumentFields.back,
    ],
  };

  static String fieldLabel(String key) {
    switch (key) {
      case 'display_name':
        return 'Full name';
      case 'birth_date':
        return 'Date of birth';
      case 'NameCar':
        return 'Vehicle name';
      case 'vehicle_make':
        return 'Vehicle make';
      case 'ModelCar':
        return 'Vehicle model';
      case 'vehicle_color':
        return 'Vehicle color';
      case 'seat_count':
        return 'Seat count';
      case 'text_type_car_mndob':
        return 'Vehicle type';
      case 'ID_hoyh_MNDOB':
        return 'National ID number';
      case 'number_lohh_car':
        return 'Plate number';
      case 'region_display':
        return 'Region';
      case 'city_display':
        return 'City';
      case 'mndob_vill_text':
        return 'Village / area';
      case 'mdenh_aml':
        return 'Work city';
      case 'photo_url':
        return 'Profile photo';
      case 'doc_national_id':
        return 'National ID document';
      case 'doc_vehicle_registration':
        return 'Vehicle registration document';
      case 'img_id_car':
        return 'Vehicle photo';
      case DriverLicenseDocumentFields.front:
        return DriverLicenseDocumentFields.frontTitleKey;
      case DriverLicenseDocumentFields.back:
        return DriverLicenseDocumentFields.backTitleKey;
      default:
        return key;
    }
  }
}

/// Expandable form for approved-driver data-change request (values + uploads).
class DriverDataChangeRequestForm extends StatefulWidget {
  const DriverDataChangeRequestForm({
    super.key,
    required this.driver,
    required this.enabled,
    required this.onSubmitted,
  });

  final UserRecord driver;
  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  State<DriverDataChangeRequestForm> createState() =>
      _DriverDataChangeRequestFormState();
}

class _DriverDataChangeRequestFormState
    extends State<DriverDataChangeRequestForm> {
  final _reasonCtrl = TextEditingController();
  final Set<String> _sections = {};
  final Map<String, TextEditingController> _fieldCtrls = {};
  final Map<String, String> _docUrls = {};
  final Map<String, String> _docPaths = {};
  bool _busy = false;
  String? _uploadingDoc;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    for (final c in _fieldCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String t(String key) => driverTr(context, key);

  TextEditingController _ctrl(String key) {
    return _fieldCtrls.putIfAbsent(key, () {
      final current = widget.driver.snapshotData[key];
      return TextEditingController(
        text: current == null ? '' : current.toString(),
      );
    });
  }

  Set<String> get _visibleTextKeys {
    final keys = <String>{};
    for (final s in _sections) {
      keys.addAll(DriverDataChangeFieldCatalog.textFieldsBySection[s] ?? const []);
    }
    return keys;
  }

  Set<String> get _visibleDocKeys {
    final keys = <String>{};
    for (final s in _sections) {
      keys.addAll(DriverDataChangeFieldCatalog.docsBySection[s] ?? const []);
    }
    return keys;
  }

  Future<void> _pickDoc(String fieldKey) async {
    if (!widget.enabled || _busy) return;
    final uid = currentUserUid;
    if (uid.isEmpty) return;
    setState(() => _uploadingDoc = fieldKey);
    try {
      final selectedMedia = await selectMediaWithSourceBottomSheet(
        context: context,
        allowPhoto: true,
        storageFolderPath:
            DriverDocumentUploadService.storageRootForUid(uid),
      );
      if (selectedMedia == null || selectedMedia.isEmpty || !mounted) return;
      final file = selectedMedia.first;
      if (!validateFileFormat(file.storagePath, context)) {
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t('Invalid file format'),
          type: DriverMessageType.warning,
        );
        return;
      }
      final result = await DriverDocumentUploadService.uploadSelectedFile(
        selected: file,
        uid: uid,
      );
      if (result == null || !mounted) return;
      setState(() {
        _docUrls[fieldKey] = result.previewUrl ?? '';
        _docPaths[fieldKey] = result.storagePath;
      });
    } catch (e) {
      if (!mounted) return;
      await DriverDialogs.showAlert(
        context,
        title: t('Error'),
        message: t('Could not upload the file. Please try again.'),
        type: DriverMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _uploadingDoc = null);
    }
  }

  Future<void> _submit() async {
    if (!widget.enabled || _busy) return;
    if (_sections.isEmpty) {
      await DriverDialogs.showAlert(
        context,
        title: t('Error'),
        message: t('Select at least one field to change.'),
        type: DriverMessageType.error,
      );
      return;
    }
    if (_reasonCtrl.text.trim().length < 3) {
      await DriverDialogs.showAlert(
        context,
        title: t('Error'),
        message: t('Please describe what you want to change.'),
        type: DriverMessageType.error,
      );
      return;
    }

    final proposed = <String, dynamic>{};
    for (final key in _visibleTextKeys) {
      final raw = _ctrl(key).text.trim();
      if (raw.isEmpty) continue;
      if (key == 'seat_count') {
        final n = int.tryParse(raw);
        if (n != null) proposed[key] = n;
      } else {
        proposed[key] = raw;
      }
    }

    final uploads = <String, dynamic>{};
    for (final key in _visibleDocKeys) {
      final url = _docUrls[key];
      final path = _docPaths[key];
      if (url == null || url.isEmpty) continue;
      uploads[key] = {
        'url': url,
        if (path != null && path.isNotEmpty) 'storagePath': path,
      };
      proposed[key] = url;
    }

    if (proposed.isEmpty) {
      await DriverDialogs.showAlert(
        context,
        title: t('Error'),
        message: t(
          'Enter the new values or upload the documents you want updated.',
        ),
        type: DriverMessageType.error,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await DriverDataChangeRequestService.submit(
        driver: widget.driver,
        sections: _sections.toList(),
        proposedValues: proposed,
        documentUploads: uploads.isEmpty ? null : uploads,
        reason: _reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      if (result.reuseExistingCorrection) {
        widget.onSubmitted();
        return;
      }
      if (!result.success) {
        await DriverDialogs.showAlert(
          context,
          title: t('Error'),
          message: t(result.errorKey ??
              'Could not submit change request. Please try again.'),
          type: DriverMessageType.error,
        );
        return;
      }
      await DriverDialogs.showAlert(
        context,
        title: t('Success'),
        message: t(
          'Your request was submitted successfully and will be updated soon after verification.',
        ),
        type: DriverMessageType.success,
      );
      widget.onSubmitted();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DsColors.of(context);
    final typography = DsTypography.of(context);
    final locked = !widget.enabled || _busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t('Request Data Change'),
          style: typography.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: DsSpacing.xs),
        Text(
          t(
            'Identity, vehicle, and documents stay locked. Request a review instead of editing them directly.',
          ),
          style: typography.bodySmall.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: DsSpacing.sm),
        ...DriverDataChangeRequestService.allowedSections.map(
          (section) => CheckboxListTile(
            value: _sections.contains(section),
            onChanged: locked
                ? null
                : (v) {
                    setState(() {
                      if (v == true) {
                        _sections.add(section);
                      } else {
                        _sections.remove(section);
                      }
                    });
                  },
            title: Text(t(_sectionLabel(section))),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (_visibleTextKeys.isNotEmpty) ...[
          const SizedBox(height: DsSpacing.md),
          Text(
            t('New values'),
            style: typography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: DsSpacing.sm),
          for (final key in _visibleTextKeys) ...[
            TextField(
              controller: _ctrl(key),
              enabled: !locked,
              keyboardType: key == 'seat_count'
                  ? TextInputType.number
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: t(DriverDataChangeFieldCatalog.fieldLabel(key)),
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
          ],
        ],
        if (_visibleDocKeys.isNotEmpty) ...[
          const SizedBox(height: DsSpacing.sm),
          Text(
            t('Attach documents'),
            style: typography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(
            t('Upload the new document or photo for each selected item.'),
            style: typography.bodySmall.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: DsSpacing.sm),
          for (final key in _visibleDocKeys)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t(DriverDataChangeFieldCatalog.fieldLabel(key))),
              subtitle: Text(
                (_docUrls[key] ?? '').isNotEmpty
                    ? t('File attached')
                    : t('No file selected'),
              ),
              trailing: _uploadingDoc == key
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      onPressed: locked ? null : () => _pickDoc(key),
                      icon: const Icon(Icons.upload_file_rounded),
                    ),
            ),
        ],
        const SizedBox(height: DsSpacing.sm),
        TextField(
          controller: _reasonCtrl,
          enabled: !locked,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: t('Reason'),
            hintText: t('Explain what should be updated'),
          ),
        ),
        const SizedBox(height: DsSpacing.sm),
        FilledButton.tonal(
          onPressed: locked ? null : _submit,
          child: Text(t('Request Data Change')),
        ),
      ],
    );
  }

  String _sectionLabel(String section) {
    switch (section) {
      case 'personal_info':
        return 'Personal information';
      case 'vehicle':
        return 'Vehicle';
      case 'national_id':
        return 'National ID';
      case 'vehicle_registration':
        return 'Vehicle registration';
      case 'driver_license':
        return 'Driver license';
      case 'plate':
        return 'Plate number';
      case 'location':
        return 'Location';
      case 'documents':
        return 'Documents';
      default:
        return 'Other';
    }
  }
}

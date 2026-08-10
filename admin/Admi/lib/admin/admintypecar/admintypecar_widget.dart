import '/backend/admin_firestore_delete.dart';
import '/backend/admin_performance.dart';
import '/backend/backend.dart';
import '/components/admin_crud_feedback.dart';
import '/components/admin_layout_widget.dart';
import '/components/admin_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/core/admin_currency.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'admintypecar_model.dart';
export 'admintypecar_model.dart';

/// Tourism Landmarks Management Page
///
/// At the top of the page, users are provided with two search
/// functionalities:
///
/// General Landmark Search: A search bar where users can quickly enter
/// keywords to find any landmark.
///
/// City-Specific Search: A separate search input that allows users to filter
/// landmarks based on the city.
/// Next to these search bars, there's a prominent "Add New Landmark" button.
/// This button directs users to a form where they can input details for a new
/// tourism landmark.
///
/// The main area of the page features a comprehensive table that displays all
/// added tourism landmarks. The table includes the following columns:
///
/// Landmark Name: The name of the tourism landmark.
/// Description: A brief overview or details about the landmark.
/// Available Services: Lists the services or facilities offered at the
/// landmark.
/// Country: The country where the landmark is located.
/// City: The city in which the landmark can be found.
/// Status: Indicates the current operational or review status of the
/// landmark.
/// Actions: Two action buttons are available:
/// Edit: Allows users to modify the landmark’s information.
/// Delete: Enables users to remove the landmark from the system.
/// This layout is designed to provide administrators with an intuitive and
/// efficient interface to manage tourism landmarks. The search features allow
/// for quick filtering, while the table organizes landmark data in a clear
/// and concise manner, ensuring ease of management and updates.
class AdmintypecarWidget extends StatefulWidget {
  const AdmintypecarWidget({super.key});

  static String routeName = 'Admintypecar';
  static String routePath = '/admintypecar';

  @override
  State<AdmintypecarWidget> createState() => _AdmintypecarWidgetState();
}

/// صورة مصغّرة لنوع المركبة داخل جدول الإدارة.
Widget _buildTypeCarThumb(BuildContext context, String? url) {
  final placeholder = Container(
    width: 72.0,
    height: 54.0,
    color: FlutterFlowTheme.of(context).alternate,
    alignment: Alignment.center,
    child: Icon(
      Icons.directions_car_rounded,
      color: FlutterFlowTheme.of(context).secondaryText,
      size: 24.0,
    ),
  );
  final clean = (url ?? '').trim();
  return ClipRRect(
    borderRadius: BorderRadius.circular(8.0),
    child: clean.isEmpty
        ? placeholder
        : CachedNetworkImage(
            imageUrl: clean,
            width: 72.0,
            height: 54.0,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (context, _) => placeholder,
            errorWidget: (context, _, __) => placeholder,
          ),
  );
}

class _AdmintypecarWidgetState extends State<AdmintypecarWidget> {
  late AdmintypecarModel _model;
  Future<List<TypeCarRecord>>? _typeCarsFuture;
  late final void Function() _listRefreshListener;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Future<List<TypeCarRecord>> _loadTypeCars() {
    return queryListCacheFirst(
      TypeCarRecord.collection,
      TypeCarRecord.fromSnapshot,
      queryBuilder: (q) => q.orderBy('sr'),
      limit: 80,
    );
  }

  Future<void> _seedVehicleCatalog() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final preset in _vehicleTypePresets) {
      final ref = TypeCarRecord.collection.doc(preset.code);
      batch.set(
        ref,
        createTypeCarRecordData(
          naim: preset.names['ar'] ?? preset.names['en'],
          namesI18n: preset.names,
          sr: preset.hourlyRate,
          actev: true,
          ishafelh: preset.isBusLike,
          aglSaat: preset.minHours,
          codeCar: preset.code,
        ),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    if (!mounted) return;
    await AdminCrudFeedback.success(
      context,
      action: AdminCrudAction.add,
      message:
          '${uiTr(context, 'تمت إضافة/تحديث')} ${_vehicleTypePresets.length} ${uiTr(context, 'نوع مركبة جاهز')}',
      refreshScope: AdminListScope.typeCars,
      invalidateStats: false,
    );
  }

  void _reloadTypeCars() {
    if (!mounted) return;
    setState(() {
      _typeCarsFuture = _loadTypeCars();
    });
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdmintypecarModel());
    _typeCarsFuture = _loadTypeCars();
    _listRefreshListener = _reloadTypeCars;
    AdminListRefresh.register(AdminListScope.typeCars, _listRefreshListener);

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    AdminListRefresh.unregister(AdminListScope.typeCars, _listRefreshListener);
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: AdminLayoutWidget(
        scaffoldKey: scaffoldKey,
        menu2Model: _model.menu2Model,
        updateCallback: () => safeSetState(() {}),
        child: AdminPageBody(
          usePadding: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                          Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ].divide(SizedBox(width: 16.0)),
                            ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                24.0, 0.0, 24.0, 0.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 0.0, 16.0, 0.0),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          FFButtonWidget(
                                            onPressed: () async {
                                              final confirmed =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text(uiTr(context, 'تأكيد باقة المركبات')),
                                                  content: Text(
                                                    '${uiTr(context, 'سيتم إضافة/تحديث')} ${_vehicleTypePresets.length} ${uiTr(context, 'نوع مركبة')} '
                                                    '${uiTr(context, 'بترجمات (عربي/إنجليزي/روسي/قيرغيزي/أوزبكي).')}\n'
                                                    '${uiTr(context, 'العملية آمنة (merge) ولن تحذف الأنواع الحالية.')}',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, false),
                                                      child: Text(uiTr(context, 'إلغاء')),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, true),
                                                      child: Text(uiTr(context, 'تأكيد')),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirmed != true) return;
                                              try {
                                                await _seedVehicleCatalog();
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                AdminCrudFeedback.error(
                                                  context,
                                                  AdminCrudFeedback.saveFailed(
                                                    context,
                                                    e,
                                                  ),
                                                );
                                              }
                                            },
                                            text:
                                                '${uiTr(context, 'إضافة باقة مركبات')} (${_vehicleTypePresets.length})',
                                            icon: const Icon(
                                              Icons.library_add_rounded,
                                              size: 15.0,
                                            ),
                                            options: FFButtonOptions(
                                              width: 220.0,
                                              height: 50.0,
                                              padding: const EdgeInsets.all(8.0),
                                              iconPadding:
                                                  const EdgeInsetsDirectional
                                                      .fromSTEB(
                                                      0.0, 0.0, 0.0, 0.0),
                                              color: FlutterFlowTheme.of(context)
                                                  .secondary,
                                              textStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .override(
                                                        fontFamily:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmallFamily,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .info,
                                                        letterSpacing: 0.0,
                                                        useGoogleFonts:
                                                            !FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmallIsCustom,
                                                      ),
                                              elevation: 0.0,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          FFButtonWidget(
                                            onPressed: () async {
                                              context.pushNamed(
                                                  CarTypeAdditionWidget
                                                      .routeName);
                                            },
                                            text: FFLocalizations.of(context)
                                                .getText(
                                              'archbmcb' /* Add car type */,
                                            ),
                                            icon: Icon(
                                              Icons.directions_car,
                                              size: 15.0,
                                            ),
                                            options: FFButtonOptions(
                                              width: 150.51,
                                              height: 50.0,
                                              padding: EdgeInsets.all(8.0),
                                              iconPadding: EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 0.0, 0.0, 0.0),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              textStyle: FlutterFlowTheme.of(
                                                      context)
                                                  .titleSmall
                                                  .override(
                                                    fontFamily:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmallFamily,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .info,
                                                    letterSpacing: 0.0,
                                                    useGoogleFonts:
                                                        !FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmallIsCustom,
                                                  ),
                                              elevation: 0.0,
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                        ].divide(SizedBox(width: 12.0)),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 0.0, 16.0, 0.0),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 16.0, 16.0, 16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            FFLocalizations.of(context).getText(
                                              'kooml6rt' /* Types of cars */,
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .headlineSmall
                                                .override(
                                                  fontFamily:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .headlineSmallFamily,
                                                  letterSpacing: 0.0,
                                                  useGoogleFonts:
                                                      !FlutterFlowTheme.of(
                                                              context)
                                                          .headlineSmallIsCustom,
                                                ),
                                          ),
                                          FutureBuilder<List<TypeCarRecord>>(
                                            future: _typeCarsFuture,
                                            builder: (context, snapshot) {
                                              if (snapshot.hasError) {
                                                return Center(
                                                  child: Text(
                                                    uiTr(context, 'تعذر تحميل أنواع السيارات'),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium,
                                                  ),
                                                );
                                              }
                                              // Customize what your widget looks like when it's loading.
                                              if (!snapshot.hasData) {
                                                return Center(
                                                  child: SizedBox(
                                                    width: 55.0,
                                                    height: 55.0,
                                                    child: SpinKitThreeBounce(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      size: 55.0,
                                                    ),
                                                  ),
                                                );
                                              }
                                              List<TypeCarRecord>
                                                  listViewTypeCarRecordList =
                                                  snapshot.data!;

                                              return ListView.builder(
                                                padding: EdgeInsets.zero,
                                                primary: false,
                                                shrinkWrap: true,
                                                scrollDirection: Axis.vertical,
                                                itemCount:
                                                    listViewTypeCarRecordList
                                                        .length,
                                                itemBuilder:
                                                    (context, listViewIndex) {
                                                  final listViewTypeCarRecord =
                                                      listViewTypeCarRecordList[
                                                          listViewIndex];
                                                  return Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 0.0),
                                                    child: Container(
                                                      width: double.infinity,
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    12.0,
                                                                    12.0,
                                                                    12.0,
                                                                    12.0),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                      0.0,
                                                                      0.0,
                                                                      12.0,
                                                                      0.0),
                                                              child:
                                                                  _buildTypeCarThumb(
                                                                context,
                                                                listViewTypeCarRecord
                                                                    .img,
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    listViewTypeCarRecord
                                                                            .namesI18n['ar']
                                                                        ??
                                                                        listViewTypeCarRecord
                                                                            .naim,
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyLarge
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).bodyLargeFamily,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).bodyLargeIsCustom,
                                                                        ),
                                                                  ),
                                                                  if (listViewTypeCarRecord
                                                                          .namesI18n['en'] !=
                                                                      null)
                                                                    Text(
                                                                      listViewTypeCarRecord
                                                                              .namesI18n['en'] ??
                                                                          '',
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodySmall,
                                                                    ),
                                                                  if (listViewTypeCarRecord
                                                                      .codeCar
                                                                      .isNotEmpty)
                                                                    Text(
                                                                      'code: ${listViewTypeCarRecord.codeCar}',
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodySmall
                                                                          .override(
                                                                            fontFamily: FlutterFlowTheme.of(context).bodySmallFamily,
                                                                            color: FlutterFlowTheme.of(context).secondaryText,
                                                                            letterSpacing: 0.0,
                                                                            useGoogleFonts: !FlutterFlowTheme.of(context).bodySmallIsCustom,
                                                                          ),
                                                                    ),
                                                                ].divide(SizedBox(
                                                                    height:
                                                                        4.0)),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    '${valueOrDefault<String>(
                                                                      formatNumber(
                                                                        listViewTypeCarRecord
                                                                            .sr,
                                                                        formatType:
                                                                            FormatType.decimal,
                                                                        decimalType:
                                                                            DecimalType.automatic,
                                                                        currency:
                                                                            AdminCurrency.asFormatPrefix(AdminCurrency.symbolForIso(listViewTypeCarRecord.countryIso2)),
                                                                      ),
                                                                      uiTr(context, 'غير معرفة'),
                                                                    )}  للساعة الواحدة',
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).bodySmallFamily,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).error,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).bodySmallIsCustom,
                                                                        ),
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    height:
                                                                        4.0)),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    '${listViewTypeCarRecord.aglSaat.toString()} ${uiTr(context, 'ساعات')}  ${uiTr(context, 'هو الحد الأدنى للطلب')}',
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodySmall
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).bodySmallFamily,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).secondaryText,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).bodySmallIsCustom,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: [
                                                                FFButtonWidget(
                                                                  onPressed:
                                                                      () async {
                                                                    final nameCtrl =
                                                                        TextEditingController(
                                                                      text: listViewTypeCarRecord
                                                                          .naim,
                                                                    );
                                                                    final nameEnCtrl =
                                                                        TextEditingController(
                                                                      text: listViewTypeCarRecord
                                                                              .namesI18n[
                                                                          'en'] ??
                                                                          '',
                                                                    );
                                                                    final nameRuCtrl =
                                                                        TextEditingController(
                                                                      text: listViewTypeCarRecord
                                                                              .namesI18n[
                                                                          'ru'] ??
                                                                          '',
                                                                    );
                                                                    final nameKyCtrl =
                                                                        TextEditingController(
                                                                      text: listViewTypeCarRecord
                                                                              .namesI18n[
                                                                          'ky'] ??
                                                                          '',
                                                                    );
                                                                    final rateCtrl =
                                                                        TextEditingController(
                                                                      text: listViewTypeCarRecord
                                                                          .sr
                                                                          .toString(),
                                                                    );
                                                                    final saved =
                                                                        await showDialog<
                                                                            bool>(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (ctx) {
                                                                        return AlertDialog(
                                                                          title: Text(uiTr(context, 'تعديل نوع السيارة')),
                                                                          content:
                                                                              SingleChildScrollView(
                                                                            child: Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            children: [
                                                                              TextField(
                                                                                controller:
                                                                                    nameCtrl,
                                                                                decoration:
                                                                                    InputDecoration(
                                                                                  labelText: uiTr(context, 'الاسم (عربي)'),
                                                                                ),
                                                                              ),
                                                                              TextField(
                                                                                controller:
                                                                                    nameEnCtrl,
                                                                                decoration:
                                                                                    InputDecoration(
                                                                                  labelText: appTr(context, 'adm_car_name_en'),
                                                                                ),
                                                                              ),
                                                                              TextField(
                                                                                controller:
                                                                                    nameRuCtrl,
                                                                                decoration:
                                                                                    InputDecoration(
                                                                                  labelText: appTr(context, 'adm_car_name_ru'),
                                                                                ),
                                                                              ),
                                                                              TextField(
                                                                                controller:
                                                                                    nameKyCtrl,
                                                                                decoration:
                                                                                    InputDecoration(
                                                                                  labelText: appTr(context, 'adm_car_name_ky'),
                                                                                ),
                                                                              ),
                                                                              TextField(
                                                                                controller:
                                                                                    rateCtrl,
                                                                                keyboardType:
                                                                                    TextInputType.number,
                                                                                decoration:
                                                                                    InputDecoration(
                                                                                  labelText:
                                                                                      uiTr(context, 'السعر للساعة'),
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          ),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed: () =>
                                                                                  Navigator.pop(
                                                                                      ctx,
                                                                                      false),
                                                                              child:
                                                                                  Text(uiTr(context, 'إلغاء')),
                                                                            ),
                                                                            TextButton(
                                                                              onPressed: () =>
                                                                                  Navigator.pop(
                                                                                      ctx,
                                                                                      true),
                                                                              child:
                                                                                  Text(uiTr(context, 'حفظ')),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    );
                                                                    if (saved !=
                                                                            true ||
                                                                        !context
                                                                            .mounted) {
                                                                      return;
                                                                    }
                                                                    try {
                                                                      final ar = nameCtrl
                                                                          .text
                                                                          .trim();
                                                                      final names =
                                                                          <String,
                                                                              String>{
                                                                        ...listViewTypeCarRecord
                                                                            .namesI18n,
                                                                        if (ar
                                                                            .isNotEmpty)
                                                                          'ar':
                                                                              ar,
                                                                      };
                                                                      final en =
                                                                          nameEnCtrl
                                                                              .text
                                                                              .trim();
                                                                      final ru =
                                                                          nameRuCtrl
                                                                              .text
                                                                              .trim();
                                                                      final ky =
                                                                          nameKyCtrl
                                                                              .text
                                                                              .trim();
                                                                      if (en
                                                                          .isNotEmpty) {
                                                                        names[
                                                                            'en'] = en;
                                                                      }
                                                                      if (ru
                                                                          .isNotEmpty) {
                                                                        names[
                                                                            'ru'] = ru;
                                                                      }
                                                                      if (ky
                                                                          .isNotEmpty) {
                                                                        names[
                                                                            'ky'] = ky;
                                                                      }
                                                                      await listViewTypeCarRecord
                                                                          .reference
                                                                          .update(
                                                                        createTypeCarRecordData(
                                                                          naim:
                                                                              ar,
                                                                          sr: int.tryParse(rateCtrl.text.trim()) ??
                                                                              listViewTypeCarRecord.sr,
                                                                          namesI18n:
                                                                              names,
                                                                        ),
                                                                      );
                                                                      if (!context
                                                                          .mounted) {
                                                                        return;
                                                                      }
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        SnackBar(
                                                                          content:
                                                                              Text(uiTr(context, 'تم حفظ التعديلات')),
                                                                        ),
                                                                      );
                                                                    } catch (e) {
                                                                      if (!context
                                                                          .mounted) {
                                                                        return;
                                                                      }
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        SnackBar(
                                                                            content:
                                                                                Text(AdminCrudFeedback.saveFailed(context, e))),
                                                                      );
                                                                    }
                                                                  },
                                                                  text: FFLocalizations.of(
                                                                          context)
                                                                      .getText(
                                                                    'i8wvudcy' /* Edit */,
                                                                  ),
                                                                  options:
                                                                      FFButtonOptions(
                                                                    width: 80.0,
                                                                    height:
                                                                        36.0,
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            8.0),
                                                                    iconPadding:
                                                                        EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                            0.0),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .success,
                                                                    textStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmall
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).labelSmallFamily,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).info,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).labelSmallIsCustom,
                                                                        ),
                                                                    elevation:
                                                                        0.0,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                  ),
                                                                ),
                                                                FFButtonWidget(
                                                                  onPressed:
                                                                      () async {
                                                                    final confirm =
                                                                        await showDialog<
                                                                            bool>(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (ctx) {
                                                                        return AlertDialog(
                                                                          title: Text(uiTr(context, 'حذف نوع السيارة')),
                                                                          content: Text(uiTr(context, 'هل أنت متأكد من حذف هذا النوع؟ لا يمكن التراجع.')),
                                                                          actions: [
                                                                            TextButton(
                                                                              onPressed: () =>
                                                                                  Navigator.pop(
                                                                                      ctx,
                                                                                      false),
                                                                              child:
                                                                                  Text(uiTr(context, 'إلغاء')),
                                                                            ),
                                                                            TextButton(
                                                                              onPressed: () =>
                                                                                  Navigator.pop(
                                                                                      ctx,
                                                                                      true),
                                                                              child:
                                                                                  Text(uiTr(context, 'حذف')),
                                                                            ),
                                                                          ],
                                                                        );
                                                                      },
                                                                    );
                                                                    if (confirm !=
                                                                            true ||
                                                                        !context
                                                                            .mounted) {
                                                                      return;
                                                                    }
                                                                    try {
                                                                      final docId =
                                                                          listViewTypeCarRecord
                                                                              .reference
                                                                              .id;
                                                                      await AdminFirestoreDelete
                                                                          .deleteDocument(
                                                                        listViewTypeCarRecord
                                                                            .reference,
                                                                      );
                                                                      if (!context
                                                                          .mounted) {
                                                                        return;
                                                                      }
                                                                      await AdminCrudFeedback
                                                                          .success(
                                                                        context,
                                                                        action:
                                                                            AdminCrudAction
                                                                                .delete,
                                                                        message:
                                                                            uiTr(context, 'تم حذف نوع السيارة بنجاح'),
                                                                        refreshScope:
                                                                            AdminListScope
                                                                                .typeCars,
                                                                        removedDocumentId:
                                                                            docId,
                                                                        invalidateStats:
                                                                            false,
                                                                      );
                                                                    } catch (e) {
                                                                      if (!context
                                                                          .mounted) {
                                                                        return;
                                                                      }
                                                                      AdminCrudFeedback
                                                                          .error(
                                                                        context,
                                                                        AdminCrudFeedback.deleteFailed(context, e),
                                                                      );
                                                                    }
                                                                  },
                                                                  text: uiTr(context, 'حذف'),
                                                                  icon: const Icon(
                                                                    Icons
                                                                        .delete_outline,
                                                                    size: 16.0,
                                                                  ),
                                                                  options:
                                                                      FFButtonOptions(
                                                                    width: 80.0,
                                                                    height:
                                                                        36.0,
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            8.0),
                                                                    iconPadding:
                                                                        EdgeInsetsDirectional.fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            0.0,
                                                                            0.0),
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    textStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmall
                                                                        .override(
                                                                          fontFamily:
                                                                              FlutterFlowTheme.of(context).labelSmallFamily,
                                                                          color:
                                                                              FlutterFlowTheme.of(context).info,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          useGoogleFonts:
                                                                              !FlutterFlowTheme.of(context).labelSmallIsCustom,
                                                                        ),
                                                                    elevation:
                                                                        0.0,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                  ),
                                                                ),
                                                                if (listViewTypeCarRecord
                                                                        .actev ==
                                                                    true)
                                                                  FFButtonWidget(
                                                                    onPressed:
                                                                        () async {
                                                                      await listViewTypeCarRecord
                                                                          .reference
                                                                          .update(
                                                                              createTypeCarRecordData(
                                                                        actev:
                                                                            false,
                                                                      ));
                                                                    },
                                                                    text: FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      'oxfcbiec' /* Parking  */,
                                                                    ),
                                                                    options:
                                                                        FFButtonOptions(
                                                                      width:
                                                                          80.0,
                                                                      height:
                                                                          36.0,
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              8.0),
                                                                      iconPadding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .error,
                                                                      textStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .override(
                                                                            fontFamily:
                                                                                FlutterFlowTheme.of(context).labelSmallFamily,
                                                                            color:
                                                                                FlutterFlowTheme.of(context).info,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            useGoogleFonts:
                                                                                !FlutterFlowTheme.of(context).labelSmallIsCustom,
                                                                          ),
                                                                      elevation:
                                                                          0.0,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                    ),
                                                                  ),
                                                                if (listViewTypeCarRecord
                                                                        .actev ==
                                                                    false)
                                                                  FFButtonWidget(
                                                                    onPressed:
                                                                        () async {
                                                                      await listViewTypeCarRecord
                                                                          .reference
                                                                          .update(
                                                                              createTypeCarRecordData(
                                                                        actev:
                                                                            true,
                                                                      ));
                                                                    },
                                                                    text: FFLocalizations.of(
                                                                            context)
                                                                        .getText(
                                                                      '4tbswp3v' /* Activation  */,
                                                                    ),
                                                                    options:
                                                                        FFButtonOptions(
                                                                      width:
                                                                          80.0,
                                                                      height:
                                                                          36.0,
                                                                      padding:
                                                                          EdgeInsets.all(
                                                                              8.0),
                                                                      iconPadding: EdgeInsetsDirectional.fromSTEB(
                                                                          0.0,
                                                                          0.0,
                                                                          0.0,
                                                                          0.0),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .tertiary,
                                                                      textStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .override(
                                                                            fontFamily:
                                                                                FlutterFlowTheme.of(context).labelSmallFamily,
                                                                            color:
                                                                                FlutterFlowTheme.of(context).info,
                                                                            letterSpacing:
                                                                                0.0,
                                                                            useGoogleFonts:
                                                                                !FlutterFlowTheme.of(context).labelSmallIsCustom,
                                                                          ),
                                                                      elevation:
                                                                          0.0,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                    ),
                                                                  ),
                                                              ].divide(SizedBox(
                                                                  width: 8.0)),
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 16.0)),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ].divide(SizedBox(height: 24.0)),
                            ),
                          ),
                        ].divide(SizedBox(height: 24.0)),
          ),
        ),
      ),
    );
  }
}

class _VehicleTypePreset {
  const _VehicleTypePreset({
    required this.code,
    required this.names,
    required this.hourlyRate,
    required this.minHours,
    this.isBusLike = false,
  });

  final String code;
  final Map<String, String> names;
  final int hourlyRate;
  final int minHours;
  final bool isBusLike;
}

const List<_VehicleTypePreset> _vehicleTypePresets = [
  _VehicleTypePreset(
    code: 'economy',
    names: {'ar': 'اقتصادية', 'en': 'Economy', 'ru': 'Эконом', 'ky': 'Эконом', 'uz': 'Ekonom'},
    hourlyRate: 160,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'compact',
    names: {'ar': 'مدمجة', 'en': 'Compact', 'ru': 'Компакт', 'ky': 'Компакт', 'uz': 'Kompakt'},
    hourlyRate: 170,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'sedan_standard',
    names: {'ar': 'سيدان قياسية', 'en': 'Standard Sedan', 'ru': 'Стандартный седан', 'ky': 'Стандарт седан', 'uz': 'Standart sedan'},
    hourlyRate: 180,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'comfort',
    names: {'ar': 'مريحة', 'en': 'Comfort', 'ru': 'Комфорт', 'ky': 'Комфорт', 'uz': 'Komfort'},
    hourlyRate: 210,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'sedan_business',
    names: {'ar': 'سيدان أعمال', 'en': 'Business Sedan', 'ru': 'Бизнес седан', 'ky': 'Бизнес седан', 'uz': 'Biznes sedan'},
    hourlyRate: 240,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'business',
    names: {'ar': 'أعمال', 'en': 'Business', 'ru': 'Бизнес', 'ky': 'Бизнес', 'uz': 'Biznes'},
    hourlyRate: 280,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'premium',
    names: {'ar': 'ممتازة', 'en': 'Premium', 'ru': 'Премиум', 'ky': 'Премиум', 'uz': 'Premium'},
    hourlyRate: 320,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'premium_sedan',
    names: {'ar': 'سيدان فاخرة', 'en': 'Premium Sedan', 'ru': 'Премиум седан', 'ky': 'Премиум седан', 'uz': 'Premium sedan'},
    hourlyRate: 420,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'luxury',
    names: {'ar': 'فاخرة', 'en': 'Luxury', 'ru': 'Люкс', 'ky': 'Люкс', 'uz': 'Lyuks'},
    hourlyRate: 480,
    minHours: 5,
  ),
  _VehicleTypePreset(
    code: 'suv_compact',
    names: {'ar': 'SUV مدمجة', 'en': 'Compact SUV', 'ru': 'Компактный SUV', 'ky': 'Ыкчам SUV', 'uz': 'Kompakt SUV'},
    hourlyRate: 260,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'suv_standard',
    names: {'ar': 'SUV قياسية', 'en': 'SUV Standard', 'ru': 'Стандартный SUV', 'ky': 'Стандарт SUV', 'uz': 'Standart SUV'},
    hourlyRate: 300,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'suv_family',
    names: {'ar': 'SUV عائلية', 'en': 'Family SUV', 'ru': 'Семейный SUV', 'ky': 'Үй-бүлөлүк SUV', 'uz': 'Oilaviy SUV'},
    hourlyRate: 320,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'suv_large',
    names: {'ar': 'SUV كبيرة', 'en': 'SUV Large', 'ru': 'Большой SUV', 'ky': 'Чоң SUV', 'uz': 'Katta SUV'},
    hourlyRate: 380,
    minHours: 5,
  ),
  _VehicleTypePreset(
    code: 'luxury_suv',
    names: {'ar': 'SUV فاخرة', 'en': 'Luxury SUV', 'ru': 'Премиум SUV', 'ky': 'Люкс SUV', 'uz': 'Lyuks SUV'},
    hourlyRate: 520,
    minHours: 5,
  ),
  _VehicleTypePreset(
    code: 'offroad_4x4',
    names: {'ar': 'دفع رباعي', 'en': '4x4', 'ru': 'Полный привод 4x4', 'ky': '4x4', 'uz': '4x4'},
    hourlyRate: 340,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'pickup_4x4',
    names: {'ar': 'بيك أب 4x4', 'en': '4x4 Pickup', 'ru': 'Пикап 4x4', 'ky': '4x4 пикап', 'uz': '4x4 pikap'},
    hourlyRate: 300,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'minivan',
    names: {'ar': 'ميني فان', 'en': 'Minivan', 'ru': 'Минивэн', 'ky': 'Минивэн', 'uz': 'Miniven'},
    hourlyRate: 340,
    minHours: 5,
  ),
  _VehicleTypePreset(
    code: 'van_family',
    names: {'ar': 'فان عائلي', 'en': 'Family Van', 'ru': 'Семейный минивэн', 'ky': 'Үй-бүлөлүк минивэн', 'uz': 'Oilaviy miniven'},
    hourlyRate: 360,
    minHours: 5,
  ),
  _VehicleTypePreset(
    code: 'van_vip',
    names: {'ar': 'فان VIP', 'en': 'VIP Van', 'ru': 'VIP минивэн', 'ky': 'VIP минивэн', 'uz': 'VIP miniven'},
    hourlyRate: 450,
    minHours: 5,
  ),
  _VehicleTypePreset(
    code: 'coach_mini',
    names: {'ar': 'ميني باص', 'en': 'Minibus', 'ru': 'Мини-автобус', 'ky': 'Кичи автобус', 'uz': 'Miniavtobus'},
    hourlyRate: 600,
    minHours: 6,
    isBusLike: true,
  ),
  _VehicleTypePreset(
    code: 'coach_tour',
    names: {'ar': 'باص سياحي', 'en': 'Tour Coach', 'ru': 'Туристический автобус', 'ky': 'Туристтик автобус', 'uz': 'Turistik avtobus'},
    hourlyRate: 900,
    minHours: 6,
    isBusLike: true,
  ),
  _VehicleTypePreset(
    code: 'executive_shuttle',
    names: {'ar': 'شاتل تنفيذي', 'en': 'Executive Shuttle', 'ru': 'Представительский шаттл', 'ky': 'Аткаруучу шаттл', 'uz': 'Ijro shattli'},
    hourlyRate: 700,
    minHours: 6,
    isBusLike: true,
  ),
  _VehicleTypePreset(
    code: 'electric',
    names: {'ar': 'كهربائية', 'en': 'Electric', 'ru': 'Электромобиль', 'ky': 'Электромобиль', 'uz': 'Elektromobil'},
    hourlyRate: 250,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'hybrid',
    names: {'ar': 'هجينة', 'en': 'Hybrid', 'ru': 'Гибрид', 'ky': 'Гибрид', 'uz': 'Gibrid'},
    hourlyRate: 230,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'wheelchair',
    names: {'ar': 'مجهزة لكرسي متحرك', 'en': 'Wheelchair Accessible', 'ru': 'Для инвалидных колясок', 'ky': 'Майыптар үчүн', 'uz': 'Nogironlar aravachasi uchun'},
    hourlyRate: 280,
    minHours: 4,
  ),
  _VehicleTypePreset(
    code: 'airport_transfer',
    names: {'ar': 'نقل مطار', 'en': 'Airport Transfer', 'ru': 'Трансфер в аэропорт', 'ky': 'Аэропорт трансфери', 'uz': 'Aeroport transferi'},
    hourlyRate: 220,
    minHours: 3,
  ),
  _VehicleTypePreset(
    code: 'tourist_vehicle',
    names: {'ar': 'مركبة سياحية', 'en': 'Tourist Vehicle', 'ru': 'Туристический транспорт', 'ky': 'Туристтик унаа', 'uz': 'Turistik transport'},
    hourlyRate: 350,
    minHours: 5,
  ),
];

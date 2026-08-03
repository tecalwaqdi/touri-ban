import '/flutter_flow/flutter_flow_calendar.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'schedulethe_trip_widget.dart' show ScheduletheTripWidget;
import 'package:flutter/material.dart';

class ScheduletheTripModel extends FlutterFlowModel<ScheduletheTripWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Calendar widget.
  DateTimeRange? calendarSelectedDay;
  // State field(s) for ho widget.
  String? hoValue;
  FormFieldController<String>? hoValueController;
  // State field(s) for mi widget.
  String? miValue;
  FormFieldController<String>? miValueController;
  // State field(s) for ftrh widget.
  String? ftrhValue;
  FormFieldController<String>? ftrhValueController;

  @override
  void initState(BuildContext context) {
    calendarSelectedDay = DateTimeRange(
      start: DateTime.now().startOfDay,
      end: DateTime.now().endOfDay,
    );
  }

  @override
  void dispose() {}
}

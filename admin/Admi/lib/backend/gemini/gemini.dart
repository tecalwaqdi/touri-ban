import 'package:flutter/material.dart';

import '/core/cloud_functions/cloud_functions_client.dart';
import '/flutter_flow/flutter_flow_util.dart';

Future<String?> geminiGenerateText(
  BuildContext context,
  String prompt,
) async {
  try {
    return await CloudFunctionsClient.geminiGenerateText(prompt);
  } catch (e) {
    showSnackbar(context, e.toString());
    return null;
  }
}

Future<String?> geminiCountTokens(
  BuildContext context,
  String prompt,
) async {
  try {
    final text = await CloudFunctionsClient.geminiGenerateText(
      'Count tokens for: $prompt',
    );
    return text;
  } catch (e) {
    showSnackbar(context, e.toString());
    return null;
  }
}

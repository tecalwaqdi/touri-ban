import 'package:flutter/material.dart';

/// Production-safe placeholder when QA fixtures are disabled.
class AdminQaFixtureUnavailableWidget extends StatelessWidget {
  const AdminQaFixtureUnavailableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Semantics(
        identifier: 'qa-fixture-denied',
        label: 'qa-fixture-denied',
        child: const Center(
          child: Text('Not available'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '/core/app_design_system.dart';

/// هيكل تحميل خفيف للمعالم — يظهر فوراً بدل spinner ملء الشاشة.
class TouryLandmarkSkeletonList extends StatelessWidget {
  const TouryLandmarkSkeletonList({
    super.key,
    this.itemCount = 6,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
          child: Container(
            height: 118,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 96,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: TouryBrand.teal.withValues(alpha: 0.12),
                    borderRadius: const BorderRadiusDirectional.only(
                      topStart: Radius.circular(12),
                      bottomStart: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 10,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

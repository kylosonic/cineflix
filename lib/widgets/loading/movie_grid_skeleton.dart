import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/cine_theme.dart';

class MovieGridSkeleton extends StatelessWidget {
  final int itemCount;

  const MovieGridSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 1450
            ? 7
            : width > 1200
            ? 6
            : width > 980
            ? 5
            : width > 740
            ? 4
            : 2;

        return Shimmer.fromColors(
          baseColor: CinePalette.surface,
          highlightColor: CinePalette.surfaceAlt,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            shrinkWrap: true,
            itemCount: itemCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 0.57,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: CinePalette.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

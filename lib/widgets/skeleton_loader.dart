import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros
          Row(
            children: [
              Expanded(child: SkeletonLoader(width: double.infinity, height: 50)),
              const SizedBox(width: 16),
              Expanded(child: SkeletonLoader(width: double.infinity, height: 50)),
            ],
          ),
          const SizedBox(height: 24),
          
          // KPI Cards
          Row(
            children: [
              Expanded(child: SkeletonLoader(width: double.infinity, height: 100)),
              const SizedBox(width: 12),
              Expanded(child: SkeletonLoader(width: double.infinity, height: 100)),
              const SizedBox(width: 12),
              Expanded(child: SkeletonLoader(width: double.infinity, height: 100)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Charts
          SkeletonLoader(width: double.infinity, height: 300),
          const SizedBox(height: 24),
          SkeletonLoader(width: double.infinity, height: 300),
          const SizedBox(height: 24),
          SkeletonLoader(width: double.infinity, height: 300),
        ],
      ),
    );
  }
}

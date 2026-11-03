import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';
import 'home_featured_placeholder.dart';


class HomeLoadingShimmer extends StatelessWidget {
  const HomeLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Banner Shimmer
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ShimmerWidget.rectangular(
              isBorder: true,
              height: isTablet(context) ? 450 : 220.h,
            ),
          ),

          // 2. SubCategory Shimmer (Shop by categories)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
            child: ShimmerWidget.rectangular(
              isBorder: true,
              height: 18,
              width: 200,
              borderRadius: 15,
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet(context) ? 8 : 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.65,
            ),
            itemCount: isTablet(context) ? 8 : 4,
            itemBuilder: (context, index) {
              return const ResponsiveSubCategoryCardShimmer();
            },
          ),
          const SizedBox(height: 15),

          // 3. Brands Shimmer (Top Brands)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
            child: ShimmerWidget.rectangular(
              isBorder: true,
              height: 18,
              width: 200,
              borderRadius: 15,
            ),
          ),
          SizedBox(
            height: 105.h,
            width: double.infinity,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 20, right: 5, top: 4, bottom: 4),
              scrollDirection: Axis.horizontal,
              itemCount: 8,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 15.0),
                  child: Column(
                    children: [
                      ShimmerWidget.rectangular(
                        isBorder: true,
                        height: 95,
                        width: 90.w,
                        borderRadius: 15,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),

          // 4. Featured Product Section Shimmer
          const HomeFeaturedPlaceholder(),
        ],
      ),
    );
  }
}

class ResponsiveSubCategoryCardShimmer extends StatelessWidget {
  const ResponsiveSubCategoryCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;
        final borderRadius = cardWidth * 0.12;

        return SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: Column(
            children: [
              Expanded(
                flex: 7,
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: cardHeight * 0.05),
                  child: ShimmerWidget.rectangular(
                    isBorder: true,
                    height: double.infinity,
                    width: double.infinity,
                    borderRadius: borderRadius,
                  ),
                ),
              ),
              // Text Shimmer
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerWidget.rectangular(
                        isBorder: true,
                        height: 8,
                        width: double.infinity,
                        borderRadius: 4,
                      ),
                      SizedBox(height: cardHeight * 0.02),
                      ShimmerWidget.rectangular(
                        isBorder: true,
                        height: 8,
                        width: cardWidth * 0.6,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

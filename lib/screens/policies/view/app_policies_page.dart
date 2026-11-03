import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import '../../../config/settings_data_instance.dart';
/// Enum that represents every policy you need.
enum PolicyType {
  aboutUs,
  privacyPolicy,
  termsAndConditions,
  refundPolicy,
  shippingPolicy,
  // add more here if needed
}

/// Extension to get a human-readable title for the AppBar.
extension PolicyTitle on PolicyType {
  String getLocalizedTitle(BuildContext context) {
    switch (this) {
      case PolicyType.aboutUs:
        return context.tr('aboutUs', fallback: 'About Us');
      case PolicyType.privacyPolicy:
        return context.tr('privacyPolicy', fallback: 'Privacy Policy');
      case PolicyType.termsAndConditions:
        return context.tr('termsAndConditions', fallback: context.tr('termsCondition', fallback: 'Terms & Conditions'));
      case PolicyType.refundPolicy:
        return context.tr('refundPolicy', fallback: 'Refund Policy');
      case PolicyType.shippingPolicy:
        return context.tr('shippingPolicy', fallback: 'Shipping Policy');
    }
  }

  String get title {
    switch (this) {
      case PolicyType.aboutUs:
        return 'About Us';
      case PolicyType.privacyPolicy:
        return 'Privacy Policy';
      case PolicyType.termsAndConditions:
        return 'Terms & Conditions';
      case PolicyType.refundPolicy:
        return 'Refund Policy';
      case PolicyType.shippingPolicy:
        return 'Shipping Policy';
    }
  }

  /// Returns the HTML string from SettingsData (or an empty string if missing).
  String get htmlContent {
    final web = SettingsData.instance.web;
    switch (this) {
      case PolicyType.aboutUs:
        return web?.aboutUs ?? '';
      case PolicyType.privacyPolicy:
        return web?.privacyPolicy ?? '';
      case PolicyType.termsAndConditions:
        return web?.termsCondition ?? '';
      case PolicyType.refundPolicy:
        return web?.returnRefundPolicy ?? '';
      case PolicyType.shippingPolicy:
        return web?.shippingPolicy ?? '';
    }
  }
}

/// Reusable policy page.
class PolicyPage extends StatelessWidget {
  final PolicyType policyType;

  const PolicyPage({super.key, required this.policyType});

  @override
  Widget build(BuildContext context) {
    final String html = policyType.htmlContent;
    final String title = policyType.getLocalizedTitle(context);

    return CustomScaffold(
      showViewCart: false,
      showAppBar: true,
      title: title,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: SingleChildScrollView(
          child: Html(
            shrinkWrap: true,
            data: html,
          ),
        ),
      ),
    );
  }
}

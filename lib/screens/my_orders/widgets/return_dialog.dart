import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/utils/widgets/custom_dropdown.dart';
import 'package:hyper_local/utils/widgets/custom_textfield.dart';
import 'package:hyper_local/utils/widgets/money_display.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/helper.dart';
import '../../../config/theme.dart';
import '../../../utils/widgets/dashed_container.dart';
import '../bloc/return_order_item/return_order_item_bloc.dart';
import '../model/order_detail_model.dart';
import '../model/return_reason_model.dart';

const Set<String> _inTransitOrderStatuses = {
  'ready_for_pickup',
  'assigned',
  'out_for_delivery',
};

bool _isOrderInTransit(String? status) => status != null && _inTransitOrderStatuses.contains(status);

class ReturnItemsDialog extends StatefulWidget {
  final List<OrderItems> items;
  final String orderSlug;
  final bool isDelivered;
  final String? orderStatus;
  final String? currencyCode;

  const ReturnItemsDialog({
    super.key,
    required this.items,
    required this.orderSlug,
    required this.isDelivered,
    this.orderStatus,
    this.currencyCode,
  });

  @override
  State<ReturnItemsDialog> createState() => _ReturnItemsDialogState();
}

class _ReturnItemsDialogState extends State<ReturnItemsDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  OrderItems? _selectedItem;
  ReturnReason? _selectedReason;
  List<ReturnReason> _reasonsList = [];
  bool _loadingReasons = false;
  String? _reasonsError;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReturnOrderItemBloc, ReturnOrderItemState>(
      listener: (context, state) {
        if (state is ReturnReasonsLoading) {
          setState(() {
            _loadingReasons = true;
            _reasonsError = null;
          });
        } else if (state is ReturnReasonsLoaded) {
          setState(() {
            _loadingReasons = false;
            _reasonsList = List<ReturnReason>.from(state.reasons)
              ..add(ReturnReason(
                id: -1,
                title: context.tr('other', fallback: 'Other'),
                proofRequired: false,
                otpRequired: false,
              ));
            _selectedReason = null;
          });
        } else if (state is ReturnReasonsFailed) {
          setState(() {
            _loadingReasons = false;
            _reasonsError = state.error;
          });
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        insetPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 50.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context),
            Expanded(
              child: _selectedItem == null ? _buildListView() : returnForm(),
            ),
            if (_selectedItem != null) _footerActions()
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final title = _selectedItem == null ? context.tr('myOrders') : context.tr('cancelReturnRequest');
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          const Icon(TablerIcons.package_export, color: AppTheme.primaryColor),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: isTablet(context) ? 24 : 16.sp, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  Widget _buildListView() {
    final items = widget.items;
    if (items.isEmpty) {
      return const Center();
    }
    return ListView.builder(
      padding: EdgeInsets.all(12.sp),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _ProductReturnCard(
          item: item,
          onReturn: () {
            setState(() {
              _selectedItem = item;
              _selectedReason = null;
              _images.clear();
            });
            context.read<ReturnOrderItemBloc>().add(FetchReturnReasons(orderItemId: item.id!));
          },
          onCancelItem: () => _confirmCancelItem(item),
          onCancelReturnRequest: () => _confirmCancelReturnRequest(item),
          isDelivered: widget.isDelivered,
          orderStatus: item.status,
          currencyCode: widget.currencyCode,
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  final TextEditingController _reasonCtrl = TextEditingController();
  final List<XFile> _images = [];
  bool _submitting = false;

  Future<void> _pickImages() async {
    const int maxImages = 5;
    final remaining = maxImages - _images.length;

    if (remaining <= 0) {
      ToastManager.show(
        context: context,
        message: context.tr('youCanUploadUpToImagesOnly', positionalArgs: [maxImages]),
        type: ToastType.warning,
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> selected = await picker.pickMultiImage(imageQuality: 85);

    if (selected.isNotEmpty) {
      final toAdd = selected.take(remaining).toList();
      setState(() {
        _images.addAll(toAdd);
      });

      if (selected.length > remaining) {
        if (mounted) {
          ToastManager.show(
            context: context,
            message: context.tr('onlyMoreImagesAddedMaxLimit', positionalArgs: [remaining, maxImages]),
            type: ToastType.info,
          );
        }
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedReason == null) {
        ToastManager.show(
          context: context,
          message: context.tr('pleaseProvideAReason'),
          type: ToastType.warning,
        );
        return;
      }
      if (_images.isEmpty) {
        ToastManager.show(
          context: context,
          message: context.tr('pleaseUploadProofImage'),
          type: ToastType.warning,
        );
        return;
      }
      setState(() => _submitting = true);
      try {
        context.read<ReturnOrderItemBloc>().add(ReturnOrderItemRequest(
            orderItemId: _selectedItem!.id!,
            returnReasonId: _selectedReason!.id == -1 ? null : _selectedReason!.id,
            reason: _selectedReason!.id == -1 ? _reasonCtrl.text.trim() : _selectedReason!.title,
            images: _images));
        if (mounted) Navigator.pop(context);
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }
  }

  Future<void> _confirmCancelItem(OrderItems item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(ctx.tr('cancelItem')),
          content: Text(ctx.tr('areYouSureYouWantToCancelThisItem')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                ctx.tr('no'),
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                ctx.tr('yes'),
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      if (mounted) {
        context.read<ReturnOrderItemBloc>().add(CancelOrderItem(orderItemId: item.id!));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _confirmCancelReturnRequest(OrderItems item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(ctx.tr('cancelReturnRequest')),
          content: Text(ctx.tr('areYouSureYouWantToCancelThisReturnRequest')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                ctx.tr('no'),
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                ctx.tr('yes'),
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      if (mounted) {
        context.read<ReturnOrderItemBloc>().add(CancelReturnRequest(orderItemId: item.id!));
        Navigator.pop(context);
      }
    }
  }

  Widget returnForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(12.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _productHeader(_selectedItem!),
            SizedBox(height: 12.h),
            _reasonField(),
            SizedBox(height: 12.h),
            _imagesSection(),
          ],
        ),
      ),
    );
  }

  Widget _productHeader(OrderItems item) {
    final String? imageUrl = item.product?.image;
    final String title = item.title ?? context.tr('product');
    final String qty = item.quantity.toString();
    final String price = item.subtotal.toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomImageContainer(
          imagePath: imageUrl ?? '',
          width: 72.w,
          height: 72.w,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(8.r),
          errorWidget: Container(
            color: Colors.grey[200],
            child: Icon(Icons.image, color: Colors.grey[500]),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 4.h),
              Text('${context.tr('quantity')}: $qty', style: TextStyle(fontSize: 12.sp)),
              Text('${context.tr('price')}: ${MoneyDisplay.format(price, currencyCode: widget.currencyCode)}',
                  style: TextStyle(fontSize: 12.sp)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reasonField() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              context.tr('reasonForReturn'),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingReasons)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_reasonsError != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('failedToLoadReturnReasons'),
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12.sp,
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<ReturnOrderItemBloc>().add(
                        FetchReturnReasons(orderItemId: _selectedItem!.id!),
                      );
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(context.tr('retry')),
              ),
            ],
          )
        else if (_reasonsList.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('noReturnReasonsAvailable'),
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12.sp,
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<ReturnOrderItemBloc>().add(
                        FetchReturnReasons(orderItemId: _selectedItem!.id!),
                      );
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(context.tr('refresh')),
              ),
            ],
          )
        else
          CustomDropdown<ReturnReason>(
            value: _selectedReason,
            hintText: context.tr('pleaseProvideAReason'),
            items: _reasonsList.map((reason) {
              return DropdownMenuItem<ReturnReason>(
                value: reason,
                child: Text(
                  reason.title,
                  style: TextStyle(
                    fontSize: isTablet(context) ? 20 : 14,
                  ),
                ),
              );
            }).toList(),
            validator: (value) {
              if (value == null) {
                return context.tr('pleaseProvideAReason');
              }
              return null;
            },
            onChanged: (reason) {
              setState(() {
                _selectedReason = reason;
                if (reason?.id != -1) {
                  _reasonCtrl.clear();
                }
              });
            },
          ),
        if (_selectedReason?.id == -1) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                context.tr('description'),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomTextFormField(
            controller: _reasonCtrl,
            hintText: context.tr('pleaseEnterADescription'),
            maxLines: 3,
            minLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.tr('pleaseEnterADescription');
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _imagesSection() {
    const int maxImages = 5;
    const String allowedExtensions = 'JPG, JPEG, PNG';
    const String maxSizePerImage = '5 MB';

    final int selectedCount = _images.length;
    final bool canAddMore = selectedCount < maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + Counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  context.tr('uploadImages'),
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                ),
                Text(
                  ' *',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.red),
                ),
              ],
            ),
            Text(
              '$selectedCount / $maxImages',
              style: TextStyle(
                fontSize: 11.sp,
                color: selectedCount == maxImages ? Colors.red.shade600 : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),

        // Dashed Container
        DashedContainer(
          radius: 10.r,
          strokeWidth: 1.5,
          dashWidth: 6,
          dashGap: 4,
          color: AppTheme.primaryColor.withValues(alpha: 0.6),
          padding: EdgeInsets.all(12.w),
          child: _images.isEmpty ? _buildEmptyState() : _buildImageGridWithAddButton(canAddMore),
        ),

        // File restrictions note (always visible)
        Padding(
          padding: EdgeInsets.only(top: 6.h, left: 2.w),
          child: Text(
            context.tr('maxImagesAllowedExtensions', positionalArgs: [maxImages, allowedExtensions, maxSizePerImage]),
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

// Empty State
  Widget _buildEmptyState() {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 22.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.6),
              size: 32.sp,
            ),
            SizedBox(height: 10.h),
            Text(
              context.tr('tapToUploadPhotos'),
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              context.tr('helpUsUnderstandYourExperience'),
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

// Grid with Images + Add Button
  Widget _buildImageGridWithAddButton(bool canAddMore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: [
            // Selected Images
            for (int i = 0; i < _images.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Image.file(
                      File(_images[i].path),
                      width: 76.w,
                      height: 76.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: InkWell(
                      onTap: () => _removeImage(i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8.r),
                            bottomLeft: Radius.circular(8.r),
                          ),
                        ),
                        padding: EdgeInsets.all(4.w),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

            // Add More Button (only if limit not reached)
            if (canAddMore)
              SizedBox(
                width: 76.w,
                height: 76.w,
                child: OutlinedButton(
                  onPressed: _pickImages,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.6), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Icon(Icons.add, size: 28.sp, color: AppTheme.primaryColor),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _footerActions() {
    return Container(
      padding: EdgeInsets.all(10.sp),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _submitting
                  ? null
                  : () {
                      setState(() {
                        _selectedItem = null;
                        _reasonCtrl.clear();
                        _images.clear();
                        _selectedReason = null;
                        _reasonsList = [];
                        _reasonsError = null;
                        _loadingReasons = false;
                      });
                    },
              child: Text(
                context.tr('cancel'),
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: CustomButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? SizedBox(
                      height: 18.h,
                      width: 18.h,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(context.tr('submitReturn'), style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ProductReturnCard extends StatelessWidget {
  final OrderItems item;
  final VoidCallback onReturn;
  final VoidCallback onCancelItem;
  final VoidCallback onCancelReturnRequest;
  final bool isDelivered;
  final String? orderStatus;
  final String? currencyCode;

  const _ProductReturnCard({
    required this.item,
    required this.onReturn,
    required this.onCancelItem,
    required this.onCancelReturnRequest,
    required this.isDelivered,
    required this.orderStatus,
    this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    // Get status message and color
    final status = getItemStatus(item, currencyCode: currencyCode);
    final isCancelable = item.product?.isCancelable;
    final isReturnable = item.returnEligible;
    final returnEligibilityMessage = _getReturnEligibilityMessage(context);
    final bool cancelDeadlineCrossed = !isDelivered && _isCancelDeadlineCrossed();
    final bool orderCancelWindowClosed = !isDelivered && _isOrderInTransit(orderStatus);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(isTablet(context) ? 8.h : 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _image(context),
              SizedBox(width: 12.w),
              Expanded(child: _details(context)),
              SizedBox(width: 12.w),
              _actionButton(context),
            ],
          ),

          SizedBox(height: 12.h),

          // 1. Non-cancellable / Non-returnable warnings
          if (orderCancelWindowClosed)
            _warningText(context.tr('cancellationPeriodPassed'), context)
          else if (item.status != 'delivered' && item.status != 'refunded' && isCancelable == false)
            _warningText(context.tr('thisProductIsNotCancelable'), context)
          else if (cancelDeadlineCrossed)
            _warningText(context.tr('productCanNoLongerBeCancelled'), context)
          else if (isDelivered && item.status != 'refunded' && returnEligibilityMessage != null)
            _warningText(returnEligibilityMessage, context)
          else if (isDelivered && isReturnable == false)
            _warningText(context.tr('thisProductIsNotReturnable'), context),

          // 2. Dynamic status message (cancelled, return in progress, refunded, etc.)
          if (status.message != null) ...[
            if (isCancelable == false || isReturnable == false) SizedBox(height: 8.h),
            _statusMessage(status, context),
          ],

          // 3. Cancel Return Request button (only when applicable)
          if (_canCancelReturnRequest())
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancelReturnRequest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                  child: Text(context.tr('cancelReturnRequest')),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context) {
    final isReturnable = item.returnEligible;
    final isCancelable = item.product?.isCancelable;

    if (isDelivered &&
        _isReturnEligible() &&
        !_isReturnDeadlineCrossed() &&
        isReturnable != false &&
        (item.returns.isEmpty)) {
      return CustomButton(
        onPressed: onReturn,
        child: Text(context.tr('returnButton'), style: const TextStyle(color: Colors.white)),
      );
    }

    if (!isDelivered &&
        !_isOrderInTransit(orderStatus) &&
        isCancelable != false &&
        !_isCancelDeadlineCrossed() &&
        item.status != 'cancelled') {
      return CustomButton(
        onPressed: onCancelItem,
        child: Text(context.tr('cancelItem')),
      );
    }

    return const SizedBox.shrink();
  }

  bool _canCancelReturnRequest() {
    if (item.returns.isEmpty) return false;
    final r = item.returns.first;
    return r.returnStatus == 'requested' ||
        (r.returnStatus != 'seller_approved' &&
            r.returnStatus != 'cancelled' &&
            (r.pickupStatus == null || r.pickupStatus == 'pending'));
  }

  bool _isReturnEligible() => item.returnEligible == true;

  DateTime? _getParsedReturnDeadline() {
    final rawDeadline = item.returnDeadline;
    if (rawDeadline == null || rawDeadline.isEmpty) return null;
    return DateTime.tryParse(rawDeadline);
  }

  bool _isReturnDeadlineCrossed() {
    final deadline = _getParsedReturnDeadline();
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline);
  }

  static const List<String> _orderItemStatusFlow = [
    'pending',
    'awaiting_store_response',
    'accepted',
    'preparing',
    // 'ready_for_pickup',
  ];

  bool _isCancelDeadlineCrossed() {
    final cancelableTill = item.product?.cancelableTill;
    if (cancelableTill == null || cancelableTill.isEmpty) return true;

    final currentStatus = orderStatus;
    if (currentStatus == null || currentStatus.isEmpty) return true;

    final cancelableIdx = _orderItemStatusFlow.indexOf(cancelableTill);
    final currentIdx = _orderItemStatusFlow.indexOf(currentStatus);
    if (cancelableIdx < 0 || currentIdx < 0) return true;

    return currentIdx > cancelableIdx;
  }

  String? _getReturnEligibilityMessage(BuildContext context) {
    if (!_isReturnEligible()) {
      return context.tr('thisProductIsNotReturnable');
    }

    if (_isReturnDeadlineCrossed()) {
      final rawDeadline = item.returnDeadline;
      if (rawDeadline == null || rawDeadline.isEmpty) {
        return context.tr('returnDeadlinePassed');
      }
      final formattedDeadline = formatIsoDateToCustomFormat(rawDeadline);
      return context.tr('returnDeadlineCrossed', positionalArgs: [formattedDeadline]);
    }

    return null;
  }

  Widget _warningText(String text, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8.r)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: isTablet(context) ? 10.sp : 16.sp, color: AppTheme.errorColor),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: isTablet(context) ? 18 : 13.sp,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis),
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusMessage(ItemStatus status, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(status.icon, size: isTablet(context) ? 11.sp : 18.sp, color: status.color),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              status.message!,
              style: TextStyle(
                color: status.color,
                fontSize: isTablet(context) ? 18.5 : 13.5.sp,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _image(BuildContext context) {
    final url = item.product?.image;
    final double size = isTablet(context) ? 50.h : 60.h;
    return CustomImageContainer(
      imagePath: url ?? '',
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(8.r),
      errorWidget: Container(
        color: Colors.grey[200],
        child: Icon(Icons.image, color: Colors.grey[500]),
      ),
    );
  }

  Widget _details(BuildContext context) {
    final title = item.title ?? 'Product';
    final qty = item.quantity ?? 1;
    final price = item.subtotal ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: isTablet(context) ? 18 : 12.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 4.h),
        Text('${context.tr('qty')}: $qty', style: TextStyle(fontSize: isTablet(context) ? 16 : 10.sp)),
        Text(MoneyDisplay.format(price, currencyCode: currencyCode), style: TextStyle(fontSize: isTablet(context) ? 16 : 10.sp)),
      ],
    );
  }
}

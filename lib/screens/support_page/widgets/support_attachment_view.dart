import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/dependency_injection_container.dart';
import '../model/support_models.dart';
import '../repo/support_repository.dart';
import 'support_feedback.dart';
import 'support_image_preview.dart';

void showSupportLocalAttachment(
    BuildContext context, SupportLocalAttachment attachment) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => attachment.isImage
        ? SupportImagePreview(
            image: FileImage(File(attachment.path)), name: attachment.name)
        : Scaffold(
            appBar: AppBar(title: Text(attachment.name)),
            body: PdfViewer.file(attachment.path),
          ),
  ));
}

class SupportAttachmentView extends StatefulWidget {
  const SupportAttachmentView({super.key, required this.attachment});

  final SupportAttachment attachment;

  @override
  State<SupportAttachmentView> createState() => _SupportAttachmentViewState();
}

class _SupportAttachmentViewState extends State<SupportAttachmentView> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  @override
  void didUpdateWidget(covariant SupportAttachmentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.id != widget.attachment.id ||
        oldWidget.attachment.downloadUrl != widget.attachment.downloadUrl) {
      _loadBytes();
    }
  }

  void _loadBytes() {
    _bytes =
        getIt<SupportRepository>().getAttachment(widget.attachment.downloadUrl);
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        final ready = snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            !snapshot.hasError;
        final bytes = ready ? snapshot.data : null;
        void preview() {
          if (bytes == null) return;
          if (attachment.isImage) {
            _showImage(context, bytes);
          } else if (attachment.isPdf) {
            _showPdf(context, bytes);
          }
        }

        return Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .65),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Icon(
                    attachment.isImage
                        ? Icons.image_outlined
                        : Icons.picture_as_pdf_outlined,
                    size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(attachment.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12)),
                      Text(_fileSize(attachment.size),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ]),
              if (bytes != null && attachment.isImage) ...[
                const SizedBox(height: 8),
                Semantics(
                  button: true,
                  label: context.tr('preview', fallback: 'Preview'),
                  child: InkWell(
                    onTap: preview,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(bytes,
                          width: 176,
                          height: 128,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 40)),
                    ),
                  ),
                ),
              ],
              if (snapshot.hasError) ...[
                const SizedBox(height: 8),
                Text(context.tr('actionFailed', fallback: 'Action failed'),
                    style: Theme.of(context).textTheme.bodySmall),
                TextButton.icon(
                  onPressed: () => setState(_loadBytes),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(context.tr('retry', fallback: 'Retry')),
                ),
              ] else if (!ready) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2),
              ],
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: [
                  if (attachment.isImage || attachment.isPdf)
                    TextButton.icon(
                      onPressed: bytes == null ? null : preview,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: Text(context.tr('preview', fallback: 'Preview')),
                    ),
                  TextButton.icon(
                    onPressed:
                        bytes == null ? null : () => _download(context, bytes),
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: Text(context.tr('download', fallback: 'Download')),
                  ),
                  IconButton(
                    tooltip: context.tr('share', fallback: 'Share'),
                    onPressed:
                        bytes == null ? null : () => _share(context, bytes),
                    icon: const Icon(Icons.ios_share_outlined, size: 18),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImage(BuildContext context, Uint8List bytes) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => SupportImagePreview(
        image: MemoryImage(bytes),
        name: widget.attachment.name,
        actions: [
          IconButton(
              onPressed: () => _share(context, bytes),
              tooltip: context.tr('share', fallback: 'Share'),
              icon: const Icon(Icons.ios_share_outlined)),
          IconButton(
              onPressed: () => _download(context, bytes),
              tooltip: context.tr('download', fallback: 'Download'),
              icon: const Icon(Icons.download_outlined)),
        ],
      ),
    ));
  }

  void _showPdf(BuildContext context, Uint8List bytes) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text(widget.attachment.name, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              onPressed: () => _share(context, bytes),
              icon: const Icon(Icons.ios_share_outlined),
            ),
            IconButton(
              onPressed: () => _download(context, bytes),
              icon: const Icon(Icons.download_outlined),
            ),
          ],
        ),
        body: PdfViewer.data(bytes, sourceName: widget.attachment.name),
      ),
    ));
  }

  Future<void> _download(BuildContext context, Uint8List bytes) async {
    try {
      await FileSaver.instance.saveFile(
        name: widget.attachment.name,
        bytes: bytes,
        includeExtension: false,
        mimeType: MimeType.custom,
        customMimeType: widget.attachment.mimeType,
      );
      if (!context.mounted) return;
      showSupportFeedback(
        context,
        message: context.tr('fileDownloadedSuccessfully', fallback: 'File downloaded successfully.'),
        type: SupportFeedbackType.success,
      );
    } catch (_) {
      if (!context.mounted) return;
      showSupportFeedback(
        context,
        message: context.tr('downloadFailed', fallback: 'Download failed.'),
        type: SupportFeedbackType.error,
      );
    }
  }

  Future<void> _share(BuildContext context, Uint8List bytes) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: widget.attachment.name,
              mimeType: widget.attachment.mimeType,
            ),
          ],
          fileNameOverrides: [widget.attachment.name],
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      showSupportFeedback(
        context,
        message: context.tr('sharingFailed', fallback: 'Sharing failed.'),
        type: SupportFeedbackType.error,
      );
    }
  }

  String _fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

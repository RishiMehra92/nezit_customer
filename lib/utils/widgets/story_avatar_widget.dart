import 'package:flutter/material.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

class StoryAvatarWidget extends StatelessWidget {
  final double avatarSize;
  final String imageUrl;
  final String username;
  final bool hasUnseen;
  final double textOpacity;
  final VoidCallback? onTap;
  final Color? ringColor;
  final bool showProfileName;

  const StoryAvatarWidget({
    super.key,
    required this.avatarSize,
    required this.imageUrl,
    required this.username,
    required this.hasUnseen,
    this.onTap,
    this.textOpacity = 1.0,
    this.ringColor,
    this.showProfileName = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Story outer ring
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasUnseen && ringColor == null
                  ? const LinearGradient(
                      colors: [Color(0xFFF91880), Color(0xFFFF8A00)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    )
                  : null,
              border: hasUnseen && ringColor != null
                  ? Border.all(color: ringColor!, width: 2.5)
                  : !hasUnseen
                      ? Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                          width: 1.5,
                        )
                      : null,
            ),
            padding: const EdgeInsets.all(2.2),
            duration: const Duration(milliseconds: 100),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: CustomImageContainer(
                  imagePath: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showProfileName && textOpacity > 0.0)
          Opacity(
            opacity: textOpacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                SizedBox(
                  width: avatarSize + 10,
                  child: Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../shared/theme/app_theme.dart';
import '../coach_ws_provider.dart';

class MessageBubble extends StatefulWidget {
  final CoachMessage message;
  const MessageBubble({super.key, required this.message});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    final isUser = widget.message.role == 'user';
    _slide = Tween<Offset>(
      begin: Offset(isUser ? 0.08 : -0.08, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == 'user';

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: .15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🤖', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.brand.withValues(alpha: .2)
                        : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? AppColors.brand.withValues(alpha: .3)
                          : AppColors.outline,
                    ),
                  ),
                  child: isUser
                      ? Text(
                          widget.message.content,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.brand,
                            height: 1.5,
                          ),
                        )
                      : MarkdownBody(
                          data: widget.message.content,
                          shrinkWrap: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                                fontSize: 14,
                                color: AppColors.onBg,
                                height: 1.5),
                            strong: const TextStyle(
                                fontSize: 14,
                                color: AppColors.onBg,
                                fontWeight: FontWeight.w700),
                            em: const TextStyle(
                                fontSize: 14,
                                color: AppColors.onBg,
                                fontStyle: FontStyle.italic),
                            code: TextStyle(
                                fontSize: 13,
                                color: AppColors.brand,
                                backgroundColor:
                                    AppColors.brand.withValues(alpha: .08),
                                fontFamily: 'monospace'),
                            codeblockDecoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            h1: const TextStyle(
                                fontSize: 17,
                                color: AppColors.onBg,
                                fontWeight: FontWeight.w700),
                            h2: const TextStyle(
                                fontSize: 15,
                                color: AppColors.onBg,
                                fontWeight: FontWeight.w700),
                            h3: const TextStyle(
                                fontSize: 14,
                                color: AppColors.onBg,
                                fontWeight: FontWeight.w600),
                            listBullet: const TextStyle(
                                fontSize: 14, color: AppColors.brand),
                            blockquoteDecoration: BoxDecoration(
                              border: const Border(
                                  left: BorderSide(
                                      color: AppColors.brand, width: 3)),
                              color: AppColors.brand.withValues(alpha: .05),
                            ),
                            blockquotePadding:
                                const EdgeInsets.fromLTRB(12, 4, 8, 4),
                          ),
                        ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

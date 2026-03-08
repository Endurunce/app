import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shimmer.dart';
import 'coach_provider.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _suggestions = [
    'Hoe herstel ik sneller?',
    'Pas mijn plan aan',
    'Wat is mijn focuspunt deze week?',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(coachProvider.notifier).load());
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    await ref.read(coachProvider.notifier).send(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachProvider);

    if (state.messages.isNotEmpty || state.sending) _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach'),
        actions: [
          if (state.loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: state.loading && state.messages.isEmpty
                ? const _LoadingSkeleton()
                : state.error != null && state.messages.isEmpty
                    ? _ErrorState(
                        message: state.error!,
                        onRetry: () => ref.read(coachProvider.notifier).load(),
                      )
                    : state.messages.isEmpty && !state.sending
                        ? const _EmptyState()
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            // +1 for typing bubble when sending
                            itemCount: state.messages.length + (state.sending ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i == state.messages.length) {
                                // Typing indicator at the end
                                return const _TypingBubble();
                              }
                              return _MessageBubble(message: state.messages[i]);
                            },
                          ),
          ),

          // Quick suggestions when < 3 messages
          if (state.messages.length < 3 && !state.loading)
            _SuggestionBar(suggestions: _suggestions, onTap: _send),

          // Error banner when sending fails but there are already messages
          if (state.error != null && state.messages.isNotEmpty)
            Container(
              width: double.infinity,
              color: AppColors.errorDim,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                state.error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          // Input bar
          _InputBar(
            controller: _inputCtrl,
            sending: state.sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── Typing indicator bubble ────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(16),
                topRight:    Radius.circular(16),
                bottomLeft:  Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _Dot(controller: _ctrl, index: i)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final AnimationController controller;
  final int index;
  const _Dot({required this.controller, required this.index});

  @override
  Widget build(BuildContext context) {
    // Each dot starts its bounce at a different offset
    final delay = index / 3.0;
    final animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 25),
      TweenSequenceItem(tween: ConstantTween(0.0),            weight: 50),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(delay, delay + 0.6, curve: Curves.easeInOut),
    ));

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 7, height: 7,
        transform: Matrix4.translationValues(0, animation.value, 0),
        decoration: const BoxDecoration(
          color: AppColors.muted,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Message bubble ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  final CoachMessage message;
  const _MessageBubble({required this.message});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
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
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(.15),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.brand.withOpacity(.2)
                        : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(16),
                      topRight:    const Radius.circular(16),
                      bottomLeft:  Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? AppColors.brand.withOpacity(.3)
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
                            p:          const TextStyle(fontSize: 14, color: AppColors.onBg, height: 1.5),
                            strong:     const TextStyle(fontSize: 14, color: AppColors.onBg, fontWeight: FontWeight.w700),
                            em:         const TextStyle(fontSize: 14, color: AppColors.onBg, fontStyle: FontStyle.italic),
                            code:       TextStyle(fontSize: 13, color: AppColors.brand, backgroundColor: AppColors.brand.withOpacity(.08), fontFamily: 'monospace'),
                            codeblockDecoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            h1:         const TextStyle(fontSize: 17, color: AppColors.onBg, fontWeight: FontWeight.w700),
                            h2:         const TextStyle(fontSize: 15, color: AppColors.onBg, fontWeight: FontWeight.w700),
                            h3:         const TextStyle(fontSize: 14, color: AppColors.onBg, fontWeight: FontWeight.w600),
                            listBullet: const TextStyle(fontSize: 14, color: AppColors.brand),
                            blockquoteDecoration: BoxDecoration(
                              border: Border(left: BorderSide(color: AppColors.brand, width: 3)),
                              color: AppColors.brand.withOpacity(.05),
                            ),
                            blockquotePadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
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

// ── Suggestion bar ─────────────────────────────────────────────────────────────

class _SuggestionBar extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  const _SuggestionBar({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onTap(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineHigh),
                ),
                child: Text(s, style: const TextStyle(
                  fontSize: 13, color: AppColors.onSurface, fontWeight: FontWeight.w500)),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }
}

// ── Input bar ──────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool sending;
  final void Function(String) onSend;
  const _InputBar({required this.controller, required this.sending, required this.onSend});

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  static const _maxChars = 1000;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() => _charCount = widget.controller.text.length);

  @override
  Widget build(BuildContext context) {
    final nearLimit = _charCount > (_maxChars * 0.8).round();
    final overLimit = _charCount > _maxChars;
    final canSend   = !widget.sending && !overLimit && _charCount > 0;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
        padding: EdgeInsets.fromLTRB(
          12, 10, 12,
          MediaQuery.of(context).viewInsets.bottom + 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    style: const TextStyle(color: AppColors.onBg, fontSize: 14),
                    maxLines: 4,
                    minLines: 1,
                    maxLength: _maxChars,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: canSend ? widget.onSend : null,
                    decoration: const InputDecoration(
                      hintText: 'Stel een vraag aan je coach...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: canSend ? AppColors.brand : AppColors.muted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: canSend ? () => widget.onSend(widget.controller.text) : null,
                    child: Center(
                      child: widget.sending
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            if (nearLimit)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 52),
                child: Text(
                  '$_charCount / $_maxChars',
                  style: TextStyle(
                    fontSize: 11,
                    color: overLimit ? AppColors.error : AppColors.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Loading skeleton ───────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        _SkeletonBubble(isUser: false, width: 240),
        const SizedBox(height: 12),
        _SkeletonBubble(isUser: true, width: 160),
        const SizedBox(height: 12),
        _SkeletonBubble(isUser: false, width: 280),
        const SizedBox(height: 12),
        _SkeletonBubble(isUser: false, width: 200),
      ],
    );
  }
}

class _SkeletonBubble extends StatelessWidget {
  final bool isUser;
  final double width;
  const _SkeletonBubble({required this.isUser, required this.width});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [Shimmer(width: width, height: 40, borderRadius: 14)],
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            Text('Hoi! Ik ben je AI-coach.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Stel me vragen over je training, herstel of race-strategie. Ik gebruik je profiel en trainingsdata als context.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.muted, size: 48),
            const SizedBox(height: 16),
            Text(message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'speech_bubble.dart';

/// Coarse emotional register driving [InteractiveMascot]'s idle motion and
/// tap response — distinct from [InteractiveMascot.moodLabel], which only
/// tints the speech bubble and keeps the dashboard's finer 5-way mood set
/// (Happy/Okay/Sad/Angry/Anxious).
enum MascotMood { neutral, peaceful, anxious, heavy }

/// A breathing, tappable, "watching" Kai mascot.
///
/// Idles in a slow vertical breathing loop (see [MascotMood] for how that
/// loop's pace/amplitude changes), tilts toward screen touches via [lookAt]
/// to simulate watching the user, bounces with a floating heart on tap, and
/// every so often "sneaks" a thought bubble up on its own.
///
/// Set [draggable] to place it anywhere on screen as a roaming companion —
/// drop it directly in a [Stack] (typically `Positioned.fill(child:
/// InteractiveMascot())` layered over a screen's existing content) and it
/// sizes its own drag bounds to whatever space it's given. Leave it `false`
/// (the default) to use it inline instead, e.g. beside a card in a [Row].
///
/// Give it a `GlobalKey<InteractiveMascotState>` to drive it imperatively
/// from a parent — [InteractiveMascotState.playSuccessAnimation],
/// [InteractiveMascotState.startBreathingExercise], and
/// [InteractiveMascotState.lookAt] are all public for that reason.
class InteractiveMascot extends StatefulWidget {
  const InteractiveMascot({
    super.key,
    this.size = 110,
    this.draggable = false,
    this.moodLabel,
    this.moodState = MascotMood.neutral,
    this.enableSpeechBubble = true,
  });

  final double size;
  final bool draggable;

  /// One of the dashboard mood labels — tints the speech bubble to match.
  final String? moodLabel;

  /// Drives idle motion pace/amplitude and tap response — see [MascotMood].
  final MascotMood moodState;

  /// Set false when a parent already shows its own persistent bubble next
  /// to the mascot (e.g. the dashboard's quote-of-the-day card) — suppresses
  /// the random tap/sneaky thought-bubble popup so the two don't compete.
  /// Tapping still bounces and shows the floating heart either way.
  final bool enableSpeechBubble;

  @override
  State<InteractiveMascot> createState() => InteractiveMascotState();
}

/// Public so callers can reach it via a `GlobalKey<InteractiveMascotState>`
/// for the imperative triggers ([playSuccessAnimation],
/// [startBreathingExercise], [lookAt]) — [MascotMood] stays a plain
/// constructor parameter since it's naturally driven by whatever mood state
/// the parent already watches.
class InteractiveMascotState extends State<InteractiveMascot>
    with TickerProviderStateMixin {
  static const _quotes = [
    "You're doing great!",
    'Remember to breathe.',
    "I'm here for you.",
    'One step at a time.',
    'You matter.',
    "It's okay to rest.",
  ];

  static const _sneakyQuotes = [
    "*peeks in* ...just checking on you.",
    'Psst. Still here if you need me.',
    "Sneaking in a reminder to breathe.",
    "*tiptoes by* Doing okay?",
    "Shh, just a little hello.",
    "Boo! ...okay, gentle boo.",
  ];

  // Grounding-idle breathing loop: one controller, re-tuned per MascotMood
  // (duration/scale/bob — see _MascotMotionProfile) rather than one
  // controller per mood, since only one is ever active at a time.
  late final AnimationController _idleController;
  late Animation<double> _idleScale;
  late Animation<double> _idleBob;

  // Explicit inhale/hold/exhale pacing guide — overrides the idle loop
  // while active (see startBreathingExercise/stopBreathingExercise).
  late final AnimationController _exerciseController;
  late final Animation<double> _exerciseScale;
  bool _isBreathingExercise = false;

  // Tap squash-and-stretch plus the trailing wiggle.
  late final AnimationController _squishController;
  late Animation<double> _squishAnimation;
  late final AnimationController _wiggleController;
  late final Animation<double> _wiggleAnimation;

  // "Watching" tilt toward the last screen touch (see lookAt).
  late final AnimationController _tiltController;
  Animation<double>? _tiltAnimation;
  Timer? _tiltResetTimer;

  // Floating heart shown on direct tap.
  late final AnimationController _heartController;

  // Calm blink-and-nod for playSuccessAnimation.
  late final AnimationController _successController;
  late final Animation<double> _successScale;
  late final Animation<double> _successOpacity;

  final _random = Random();
  Offset? _position;
  String? _bubbleText;
  Timer? _bubbleTimer;
  Timer? _idleTimer;

  _MascotMotionProfile get _profile =>
      _MascotMotionProfile.forMood(widget.moodState);

  /// Picks which pose art to show for the current instant: a brief success
  /// nod or tap-happy flash takes priority over the breathing-exercise
  /// inhale/exhale swap, which takes priority over the resting per-[MascotMood]
  /// pose. Checked every animated frame (see [_buildMascot]'s AnimatedBuilder)
  /// so it reverts automatically once the triggering animation finishes.
  String _currentPoseAsset() {
    if (_successController.isAnimating) return 'assets/mascot/success.png';
    if (_heartController.isAnimating) return 'assets/mascot/tap.png';
    if (_isBreathingExercise) {
      return _exerciseController.value < 2 / 3
          ? 'assets/mascot/breathe_in.png'
          : 'assets/mascot/breathe_out.png';
    }
    switch (widget.moodState) {
      case MascotMood.neutral:
        return 'assets/mascot/neutral.png';
      case MascotMood.peaceful:
        return 'assets/mascot/peaceful.png';
      case MascotMood.anxious:
        return 'assets/mascot/anxious.png';
      case MascotMood.heavy:
        return 'assets/mascot/heavy.png';
    }
  }

  @override
  void initState() {
    super.initState();

    _idleController = AnimationController(vsync: this);
    _applyIdleProfile(startAnimating: true);

    _exerciseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12), // 4s inhale + 4s hold + 4s exhale
    );
    _exerciseScale = TweenSequence<double>([
      TweenSequenceItem(
        weight: 1,
        tween: Tween(
          begin: 1.0,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      ),
      TweenSequenceItem(weight: 1, tween: ConstantTween(1.12)),
      TweenSequenceItem(
        weight: 1,
        tween: Tween(
          begin: 1.12,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
      ),
    ]).animate(_exerciseController);

    _squishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _squishAnimation = _buildSquishAnimation();

    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _wiggleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(weight: 1, tween: Tween(begin: 0.0, end: -0.06)),
          TweenSequenceItem(weight: 1, tween: Tween(begin: -0.06, end: 0.05)),
          TweenSequenceItem(weight: 1, tween: Tween(begin: 0.05, end: -0.025)),
          TweenSequenceItem(weight: 1, tween: Tween(begin: -0.025, end: 0.0)),
        ]).animate(
          CurvedAnimation(parent: _wiggleController, curve: Curves.easeOut),
        );

    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _successScale = TweenSequence<double>([
      TweenSequenceItem(
        weight: 1,
        tween: Tween(
          begin: 1.0,
          end: 0.86,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
      ),
      TweenSequenceItem(
        weight: 1,
        tween: Tween(
          begin: 0.86,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
      ),
    ]).animate(_successController);
    _successOpacity = TweenSequence<double>([
      TweenSequenceItem(weight: 1, tween: ConstantTween(1.0)),
      TweenSequenceItem(weight: 1, tween: Tween(begin: 1.0, end: 0.45)),
      TweenSequenceItem(weight: 1, tween: Tween(begin: 0.45, end: 1.0)),
    ]).animate(_successController);

    if (widget.enableSpeechBubble) _scheduleNextSneak();
  }

  @override
  void didUpdateWidget(covariant InteractiveMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moodState != widget.moodState) _applyIdleProfile();
  }

  void _applyIdleProfile({bool startAnimating = false}) {
    final profile = _profile;
    _idleController.duration = profile.cycleDuration;
    _idleScale = Tween<double>(begin: profile.scaleMin, end: profile.scaleMax)
        .animate(
          CurvedAnimation(
            parent: _idleController,
            curve: Curves.easeInOutCubic,
          ),
        );
    _idleBob = Tween<double>(begin: profile.bobRange, end: -profile.bobRange)
        .animate(
          CurvedAnimation(
            parent: _idleController,
            curve: Curves.easeInOutCubic,
          ),
        );
    if (startAnimating || _idleController.isAnimating) {
      _idleController.repeat(reverse: true);
    }
  }

  Animation<double> _buildSquishAnimation() {
    final squash = _profile.squashScale;
    final stretch = _profile.stretchScale;
    return TweenSequence<double>([
      TweenSequenceItem(
        weight: 40,
        tween: Tween(
          begin: 1.0,
          end: squash,
        ).chain(CurveTween(curve: Curves.easeOut)),
      ),
      TweenSequenceItem(
        weight: 35,
        tween: Tween(
          begin: squash,
          end: stretch,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
      ),
      TweenSequenceItem(
        weight: 25,
        tween: Tween(
          begin: stretch,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
      ),
    ]).animate(_squishController);
  }

  void _scheduleNextSneak() {
    _idleTimer?.cancel();
    _idleTimer = Timer(Duration(seconds: 10 + _random.nextInt(10)), () {
      if (!mounted || _bubbleText != null) {
        _scheduleNextSneak();
        return;
      }
      _bounce();
      setState(
        () =>
            _bubbleText = _sneakyQuotes[_random.nextInt(_sneakyQuotes.length)],
      );
      _bubbleTimer?.cancel();
      _bubbleTimer = Timer(const Duration(milliseconds: 2800), () {
        if (mounted) setState(() => _bubbleText = null);
        _scheduleNextSneak();
      });
    });
  }

  @override
  void dispose() {
    _idleController.dispose();
    _exerciseController.dispose();
    _squishController.dispose();
    _wiggleController.dispose();
    _tiltController.dispose();
    _heartController.dispose();
    _successController.dispose();
    _bubbleTimer?.cancel();
    _idleTimer?.cancel();
    _tiltResetTimer?.cancel();
    super.dispose();
  }

  /// "Heavy"/sad mood sits still rather than bouncing — every other mood
  /// gets the squash-and-stretch plus trailing wiggle.
  void _bounce() {
    _squishAnimation = _buildSquishAnimation();
    if (widget.moodState == MascotMood.heavy) return;
    _squishController.forward(from: 0);
    _wiggleController.forward(from: 0);
  }

  void _handleTap() {
    _bounce();
    _heartController.forward(from: 0);
    if (!widget.enableSpeechBubble) return;
    _bubbleTimer?.cancel();
    setState(() => _bubbleText = _quotes[_random.nextInt(_quotes.length)]);
    _bubbleTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _bubbleText = null);
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints bounds) {
    final next = _position! + details.delta;
    setState(() {
      _position = Offset(
        next.dx.clamp(0.0, bounds.maxWidth - widget.size),
        next.dy.clamp(0.0, bounds.maxHeight - widget.size),
      );
    });
  }

  /// Smoothly tilts the mascot's body toward [globalPosition] — call this
  /// from an ancestor `Listener(onPointerDown: ...)` (or `onPointerMove`
  /// for swipes) covering the whole screen, so the mascot reads as
  /// "watching" wherever the user touches, not just when it's tapped
  /// directly. See the dashboard wiring note on [InteractiveMascot].
  void lookAt(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    final dx = (globalPosition.dx - center.dx) / 240;
    final target = dx.clamp(-0.22, 0.22);

    _tiltAnimation =
        Tween<double>(begin: _tiltAnimation?.value ?? 0, end: target).animate(
          CurvedAnimation(parent: _tiltController, curve: Curves.easeOutCubic),
        );
    _tiltController.forward(from: 0);

    _tiltResetTimer?.cancel();
    _tiltResetTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      _tiltAnimation =
          Tween<double>(begin: _tiltAnimation?.value ?? 0, end: 0.0).animate(
            CurvedAnimation(
              parent: _tiltController,
              curve: Curves.easeOutCubic,
            ),
          );
      _tiltController.forward(from: 0);
    });
  }

  /// Quick scale-down "nod" plus a brief opacity "blink" — call after a
  /// positive action completes, e.g. once a journal entry finishes saving.
  void playSuccessAnimation() {
    _successController.forward(from: 0);
  }

  /// Overrides the idle breathing loop with an explicit 4s-inhale /
  /// 4s-hold / 4s-exhale pacing guide, looping until [stopBreathingExercise]
  /// is called.
  void startBreathingExercise() {
    if (_isBreathingExercise) return;
    setState(() => _isBreathingExercise = true);
    _idleController.stop();
    _exerciseController.repeat();
  }

  void stopBreathingExercise() {
    if (!_isBreathingExercise) return;
    _exerciseController.stop();
    setState(() => _isBreathingExercise = false);
    _idleController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.draggable) return _buildMascot(onPanUpdate: null);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Lazily seeds the starting corner using the first known layout size
        // — safe to mutate here since it only ever runs once per mascot.
        _position ??= Offset(
          constraints.maxWidth - widget.size - 16,
          constraints.maxHeight - widget.size - 120,
        );

        return Stack(
          children: [
            Positioned(
              left: _position!.dx,
              top: _position!.dy,
              child: _buildMascot(
                onPanUpdate: (details) =>
                    _handlePanUpdate(details, constraints),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMascot({required GestureDragUpdateCallback? onPanUpdate}) {
    final profile = _profile;
    return GestureDetector(
      onTap: _handleTap,
      onPanUpdate: onPanUpdate,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _idleController,
          _exerciseController,
          _squishController,
          _wiggleController,
          _tiltController,
          _heartController,
          _successController,
        ]),
        builder: (context, child) {
          final breathScale = _isBreathingExercise
              ? _exerciseScale.value
              : _idleScale.value * _successScale.value;
          final bob = _isBreathingExercise ? 0.0 : _idleBob.value;
          final tilt = _tiltAnimation?.value ?? 0.0;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Transform.translate(
                offset: Offset(0, bob + profile.baseOffsetY),
                child: Transform.rotate(
                  angle: tilt + _wiggleAnimation.value,
                  alignment: Alignment.bottomCenter,
                  child: Transform.scale(
                    scale: breathScale * _squishAnimation.value,
                    alignment: Alignment.bottomCenter,
                    child: Opacity(
                      opacity: _successOpacity.value,
                      child: child,
                    ),
                  ),
                ),
              ),
              if (_heartController.value > 0)
                Positioned(
                  top: -10 - 28 * _heartController.value,
                  child: Opacity(
                    opacity: (1 - _heartController.value).clamp(0.0, 1.0),
                    child: const Text('💜', style: TextStyle(fontSize: 18)),
                  ),
                ),
            ],
          );
        },
        // A Stack, not a Column: the speech bubble is a Positioned overlay
        // to the image's left — tail pointing right, toward its mouth —
        // rather than stacking in flow, so the bubble popping in/out never
        // changes this widget's reported size. It used to be a Column,
        // which meant every "sneaky" bubble (or a tap) grew the mascot's
        // box by the bubble's width/height — and since the mascot sits in
        // the quote card's Row, that reflowed the quote text and everything
        // below it on the dashboard each time.
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Image.asset(
                _currentPoseAsset(),
                key: ValueKey(_currentPoseAsset()),
                width: widget.size,
                height: widget.size,
              ),
            ),
            Positioned(
              right: widget.size + 6,
              // Roughly mouth height on the source art (the capybara's
              // face sits in the image's upper third).
              top: widget.size * 0.22,
              child: UnconstrainedBox(
                alignment: Alignment.centerRight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      alignment: Alignment.centerRight,
                      child: child,
                    ),
                  ),
                  child: _bubbleText == null
                      ? const SizedBox.shrink(key: ValueKey('empty'))
                      : SpeechBubble(
                          key: ValueKey(_bubbleText),
                          text: _bubbleText!,
                          moodLabel: widget.moodLabel,
                          tailSide: BubbleTailSide.right,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tunable idle-motion numbers per [MascotMood]. Kept as one small value
/// type (rather than a switch sprinkled through the state class) so the
/// per-mood feel reads as a table: pace, amplitude, posture.
class _MascotMotionProfile {
  const _MascotMotionProfile({
    required this.cycleDuration,
    required this.scaleMin,
    required this.scaleMax,
    required this.bobRange,
    required this.baseOffsetY,
    required this.squashScale,
    required this.stretchScale,
  });

  /// Full up-down breathing cycle length.
  final Duration cycleDuration;
  final double scaleMin;
  final double scaleMax;

  /// Idle vertical float, +/- pixels.
  final double bobRange;

  /// Constant vertical offset — "sitting lower" for a heavy/sad mood.
  final double baseOffsetY;

  /// Tap squash-and-stretch extremes (1.0 = resting scale).
  final double squashScale;
  final double stretchScale;

  factory _MascotMotionProfile.forMood(MascotMood mood) {
    switch (mood) {
      case MascotMood.neutral:
        return const _MascotMotionProfile(
          cycleDuration: Duration(milliseconds: 3600),
          scaleMin: 0.93,
          scaleMax: 1.05,
          bobRange: 8,
          baseOffsetY: 0,
          squashScale: 0.92,
          stretchScale: 1.06,
        );
      case MascotMood.peaceful:
        return const _MascotMotionProfile(
          cycleDuration: Duration(milliseconds: 2600),
          scaleMin: 0.96,
          scaleMax: 1.06,
          bobRange: 10,
          baseOffsetY: 0,
          squashScale: 0.95,
          stretchScale: 1.04,
        );
      case MascotMood.anxious:
        // Curled up (smaller baseline) and paced to exactly 4s in / 4s out.
        return const _MascotMotionProfile(
          cycleDuration: Duration(seconds: 8),
          scaleMin: 0.86,
          scaleMax: 0.93,
          bobRange: 3,
          baseOffsetY: 4,
          squashScale: 0.9,
          stretchScale: 1.0,
        );
      case MascotMood.heavy:
        return const _MascotMotionProfile(
          cycleDuration: Duration(milliseconds: 5500),
          scaleMin: 0.97,
          scaleMax: 1.0,
          bobRange: 0,
          baseOffsetY: 18,
          squashScale: 1.0,
          stretchScale: 1.0,
        );
    }
  }
}

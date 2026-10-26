
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class AnimationScreen extends StatefulWidget {
  final String motherName;
  final bool isTwins;
  final DateTime lmpDate;
  final int bpm;

  const AnimationScreen({
    super.key,
    required this.motherName,
    required this.isTwins,
    required this.lmpDate,
    required this.bpm,
  });

  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late final AnimationController _backgroundController;
  late final AnimationController _ecgController;

  bool _videoReady = false;
  bool _isPlaying = false;
  bool _isLoadingVideo = false;
  String? _videoError;

  int _selectedWeek = 1;
  int _loadedRange = -1;

  static const Color bg = Color(0xFF08020F);
  static const Color cardBg = Color(0xFF1A0A20);
  static const Color purple = Color(0xFFB75AF5);
  static const Color pink = Color(0xFFFF69B4);

  int get _currentWeek {
    final days = DateTime.now().difference(widget.lmpDate).inDays;
    final safeDays = days < 0 ? 0 : days;
    return ((safeDays ~/ 7) + 1).clamp(1, 40);
  }

  int _rangeIndexForWeek(int week) {
    if (week <= 4) return 0;
    if (week <= 14) return 1;
    if (week <= 24) return 2;
    if (week <= 32) return 3;
    return 4;
  }

  String _videoPathForWeek(int week) {
    const ranges = [
      '01_04',
      '05_14',
      '15_24',
      '25_32',
      '33_40',
    ];

    final babyType = widget.isTwins ? 'twins' : 'single';
    return 'assets/videos/${babyType}_${ranges[_rangeIndexForWeek(week)]}.mp4';
  }

  @override
  void initState() {
    super.initState();

    _selectedWeek = _currentWeek;

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _loadVideoForWeek(_selectedWeek);
  }

  Future<void> _loadVideoForWeek(int week) async {
    final rangeIndex = _rangeIndexForWeek(week);

    if (_loadedRange == rangeIndex &&
        _videoController != null &&
        _videoReady) {
      return;
    }

    setState(() {
      _isLoadingVideo = true;
      _videoReady = false;
      _videoError = null;
    });

    final oldController = _videoController;
    _videoController = null;

    if (oldController != null) {
      oldController.removeListener(_videoListener);
      await oldController.dispose();
    }

    final controller = VideoPlayerController.asset(
      _videoPathForWeek(week),
    );

    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();

      if (!mounted || _videoController != controller) {
        await controller.dispose();
        return;
      }

      controller.addListener(_videoListener);

      setState(() {
        _loadedRange = rangeIndex;
        _videoReady = true;
        _isLoadingVideo = false;
        _isPlaying = controller.value.isPlaying;
      });
    } catch (error) {
      if (!mounted || _videoController != controller) return;

      setState(() {
        _videoError =
            'Video load aagala. assets/videos filenames check pannu.';
        _isLoadingVideo = false;
        _videoReady = false;
      });
    }
  }

  void _videoListener() {
    final controller = _videoController;

    if (!mounted ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    if (_isPlaying != controller.value.isPlaying) {
      setState(() {
        _isPlaying = controller.value.isPlaying;
      });
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _videoController;

    if (controller == null || !_videoReady) return;

    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.play();
      }
    } catch (_) {
      if (mounted) {
        _message('Video playback change panna mudiyala.');
      }
    }
  }

  Future<void> _selectWeek(int week) async {
    if (week < 1 || week > _currentWeek) {
      _message('Current week varaikkum weeks select pannalam.');
      return;
    }

    setState(() {
      _selectedWeek = week;
    });

    await _loadVideoForWeek(week);
  }

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'ashicklabs@gmail.com',
      queryParameters: {
        'subject': 'My Fetal app enquiry',
      },
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _message('Email app device-la available illa.');
      }
    } catch (_) {
      if (mounted) {
        _message('Email app open panna mudiyala.');
      }
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _ecgController.dispose();

    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentWeek = _currentWeek;
    final weeksToGo = 40 - currentWeek;

    final motherName = widget.motherName.trim().isEmpty
        ? 'Mama'
        : widget.motherName.trim();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF16051F),
        foregroundColor: Colors.white,
        title: const Text("My Baby's Journey"),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _FloatingGlowPainter(
                      _backgroundController.value,
                    ),
                  );
                },
              ),
            ),

            // Baby video fixed-ah top-la irukkum.
            // Keela irukkura sections mattum scroll aagum.
            Column(
              children: [
                _buildFixedBabySection(
                  motherName,
                  currentWeek,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      14,
                      8,
                      14,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _eyebrow('YOUR JOURNEY'),
                              const SizedBox(height: 8),
                              Text(
                                '$currentWeek Weeks Pregnant',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: currentWeek / 40,
                                  minHeight: 8,
                                  backgroundColor: Colors.white12,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    pink,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                weeksToGo == 0
                                    ? 'You have reached week 40.'
                                    : '$weeksToGo weeks to go',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        _sectionTitle(
                          "Baby's Heartbeat",
                          'A simulated visual heartbeat',
                          Icons.favorite_rounded,
                        ),

                        const SizedBox(height: 12),

                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.favorite_rounded,
                                    color: pink,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${widget.bpm} BPM',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          'Illustrative value only',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 86,
                                width: double.infinity,
                                child: AnimatedBuilder(
                                  animation: _ecgController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: _EcgPainter(
                                        _ecgController.value,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

                        _sectionTitle(
                          'Pregnancy Timeline',
                          'Tap a week to explore your journey',
                          Icons.timeline_rounded,
                        ),

                        const SizedBox(height: 12),

                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _eyebrow('WEEK-BY-WEEK ROADMAP'),
                              const SizedBox(height: 8),
                              Text(
                                'Week $_selectedWeek',
                                style: const TextStyle(
                                  color: pink,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _weekDescription(_selectedWeek),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Horizontal timeline.
                              SizedBox(
                                height: 62,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: currentWeek,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final week = index + 1;
                                    final selected =
                                        week == _selectedWeek;
                                    final isCurrent =
                                        week == currentWeek;

                                    return GestureDetector(
                                      onTap: () => _selectWeek(week),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        width: 48,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? pink
                                              : isCurrent
                                                  ? purple.withValues(
                                                      alpha: .35,
                                                    )
                                                  : Colors.white.withValues(
                                                      alpha: .06,
                                                    ),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          border: Border.all(
                                            color: selected
                                                ? Colors.white
                                                : purple.withValues(
                                                    alpha: .35,
                                                  ),
                                            width: selected ? 1.6 : .8,
                                          ),
                                          boxShadow: selected
                                              ? [
                                                  BoxShadow(
                                                    color: pink.withValues(
                                                      alpha: .3,
                                                    ),
                                                    blurRadius: 14,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '$week',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (isCurrent)
                                              const Text(
                                                'NOW',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              const Text(
                                'Weeks within the same video range use '
                                'the same illustrative video clip.',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 16),

                              _milestone(
                                'First trimester',
                                'Weeks 1–13',
                                currentWeek <= 13,
                              ),
                              _milestone(
                                'Second trimester',
                                'Weeks 14–27',
                                currentWeek >= 14 && currentWeek <= 27,
                              ),
                              _milestone(
                                'Third trimester',
                                'Weeks 28–40',
                                currentWeek >= 28,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

                        _sectionTitle(
                          'Medical Disclaimer',
                          'Please read this important information',
                          Icons.health_and_safety_outlined,
                        ),

                        const SizedBox(height: 12),

                        _sectionCard(
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: pink,
                                size: 30,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'For educational purposes only',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'My Fetal provides general pregnancy information '
                                'and illustrative baby-development videos. Videos '
                                'do not show your actual baby in real time. The '
                                'displayed BPM is illustrative, not a measurement '
                                'of your baby’s heartbeat.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.7,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'This app does not replace medical care, diagnosis, '
                                'or advice from a qualified healthcare professional. '
                                'Please consult your gynecologist for personal guidance.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

                        _sectionTitle(
                          'About My Fetal',
                          'A little app for your pregnancy journey',
                          Icons.favorite_outline_rounded,
                        ),

                        const SizedBox(height: 12),

                        _sectionCard(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/logo_transparent.png',
                                height: 105,
                                width: 105,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) {
                                  return const Icon(
                                    Icons.child_friendly_rounded,
                                    color: purple,
                                    size: 75,
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'My Fetal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'VERSION 1.0.0',
                                style: TextStyle(
                                  color: purple,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'My Fetal helps expecting mothers explore '
                                'pregnancy stages through an educational '
                                'week-by-week journey and general milestones.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

                        _sectionTitle(
                          'Ashick Labs',
                          'Made with care',
                          Icons.business_outlined,
                        ),

                        const SizedBox(height: 12),

                        _sectionCard(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/ashick_lab_logo.jpg',
                                height: 115,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) {
                                  return const Icon(
                                    Icons.science_outlined,
                                    color: Colors.lightBlueAccent,
                                    size: 70,
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'ASHICK LABS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'SMART APPS. BETTER LIVES.',
                                style: TextStyle(
                                  color: Colors.lightBlueAccent,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 8),

                              InkWell(
                                onTap: _openEmail,
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.mail_outline_rounded,
                                        color: purple,
                                        size: 21,
                                      ),
                                      SizedBox(width: 9),
                                      Flexible(
                                        child: Text(
                                          'ashicklabs@gmail.com',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: pink,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.open_in_new_rounded,
                                        color: pink,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),
                              const Text(
                                'Thank you for being part of the My Fetal journey.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Center(
                          child: Text(
                            'MY FETAL  •  MADE WITH ♥',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedBabySection(
    String motherName,
    int currentWeek,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: pink,
                size: 25,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "You're doing amazing, $motherName!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = MediaQuery.sizeOf(context).height;
              final videoHeight =
                  (screenHeight * .32).clamp(180.0, 290.0);

              return Container(
                width: double.infinity,
                height: videoHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFF210D2C),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: purple.withValues(alpha: .8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withValues(alpha: .12),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: pink.withValues(alpha: .07),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const _VideoSideDecoration(),

                    if (_videoError != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _videoError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      )
                    else if (_isLoadingVideo || !_videoReady)
                      const Center(
                        child: CircularProgressIndicator(
                          color: pink,
                        ),
                      )
                    else if (_videoController != null)
                      Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _videoController!.value.size.width,
                            height: _videoController!.value.size.height,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      ),

                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .42),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'WEEK $_selectedWeek',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          onPressed: _togglePlayback,
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 29,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          Text(
            'Week $_selectedWeek of 40  •  Current week: $currentWeek',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: pink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: purple.withValues(alpha: .28),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x221B052A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _eyebrow(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: purple,
        letterSpacing: 2,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: purple.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: purple,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _milestone(
    String title,
    String weeks,
    bool isCurrent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? purple.withValues(alpha: .14)
            : Colors.white.withValues(alpha: .035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? purple.withValues(alpha: .7)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCurrent
                ? Icons.radio_button_checked
                : Icons.circle_outlined,
            color: isCurrent ? pink : Colors.white38,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isCurrent ? Colors.white : Colors.white70,
                fontWeight:
                    isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            weeks,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _weekDescription(int week) {
    if (week <= 4) {
      return 'Early pregnancy stage. Development is beginning, and changes may be too small to see.';
    } else if (week <= 13) {
      return 'First trimester: early structures and organs begin developing. Each pregnancy progresses differently.';
    } else if (week <= 27) {
      return 'Second trimester: growth continues, and body structures continue developing.';
    }

    return 'Third trimester: the baby continues growing and preparing for birth.';
  }
}

class _VideoSideDecoration extends StatelessWidget {
  const _VideoSideDecoration();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 5,
            top: 32,
            child: Icon(
              Icons.auto_awesome,
              color: Color(0x88DBA4FF),
              size: 17,
            ),
          ),
          Positioned(
            left: 15,
            bottom: 54,
            child: Icon(
              Icons.favorite,
              color: Color(0x77FF69B4),
              size: 13,
            ),
          ),
          Positioned(
            right: 12,
            top: 66,
            child: Icon(
              Icons.star_rounded,
              color: Color(0x88FFB6DF),
              size: 17,
            ),
          ),
          Positioned(
            right: 8,
            bottom: 62,
            child: Icon(
              Icons.auto_awesome,
              color: Color(0x77DBA4FF),
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingGlowPainter extends CustomPainter {
  final double progress;

  _FloatingGlowPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        34,
      );

    glowPaint.color = const Color(0xFF9B4DCC).withValues(alpha: .08);

    canvas.drawCircle(
      Offset(
        size.width * .1,
        size.height *
            (.2 + .05 * math.sin(progress * math.pi * 2)),
      ),
      85,
      glowPaint,
    );

    glowPaint.color = const Color(0xFFFF69B4).withValues(alpha: .045);

    canvas.drawCircle(
      Offset(
        size.width * .92,
        size.height *
            (.58 + .06 * math.cos(progress * math.pi * 2)),
      ),
      90,
      glowPaint,
    );

    final dotPaint = Paint();

    for (int i = 0; i < 22; i++) {
      final x = (i * 73.0 + 19) % size.width;
      final baseY = (i * 97.0 + 31) % size.height;

      final y = (baseY -
              progress * (size.height * .22) +
              size.height) %
          size.height;

      final radius = 1.0 + (i % 3) * .45;

      dotPaint.color =
          (i % 4 == 0
                  ? const Color(0xFFFF9CD2)
                  : const Color(0xFFD5A3FF))
              .withValues(alpha: .22 + (i % 3) * .08);

      canvas.drawCircle(
        Offset(x, y),
        radius,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingGlowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _EcgPainter extends CustomPainter {
  final double progress;

  _EcgPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;

    final glow = Paint()
      ..color = const Color(0xFFFF69B4).withValues(alpha: .28)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        5,
      );

    final line = Paint()
      ..color = const Color(0xFFFF83C2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    const cycle = 110.0;

    for (double x = 0; x <= size.width; x += 1) {
      final shifted = (x + progress * cycle) % cycle;
      double y = mid;

      if (shifted >= 30 && shifted < 42) {
        y = mid - 5 * math.sin((shifted - 30) / 12 * math.pi);
      } else if (shifted >= 48 && shifted < 54) {
        y = mid + (shifted - 48) / 6 * (size.height * .34);
      } else if (shifted >= 54 && shifted < 61) {
        y = mid +
            size.height * .34 -
            (shifted - 54) / 7 * (size.height * .78);
      } else if (shifted >= 61 && shifted < 68) {
        y = mid -
            size.height * .44 +
            (shifted - 61) / 7 * (size.height * .44 + 5);
      } else if (shifted >= 78 && shifted < 96) {
        y = mid - 7 * math.sin((shifted - 78) / 18 * math.pi);
      }

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _EcgPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

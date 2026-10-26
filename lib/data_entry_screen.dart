
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'animation_screen.dart';

class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final _nameController = TextEditingController();
  final _bpmController = TextEditingController();

  bool _isTwins = false;
  DateTime? _lmpDate;
  bool _isLoading = true;
  bool _isSaving = false;

  static const Color purple = Color(0xFFB75AF5);
  static const Color fieldColor = Color(0xFF21102D);

  static const String _nameKey = 'saved_mother_name';
  static const String _bpmKey = 'saved_bpm';
  static const String _twinsKey = 'saved_is_twins';
  static const String _lmpKey = 'saved_lmp_date';

  @override
  void initState() {
    super.initState();
    _loadSavedDetails();
  }

  Future<void> _loadSavedDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedName = prefs.getString(_nameKey);
      final savedBpm = prefs.getInt(_bpmKey);
      final savedTwins = prefs.getBool(_twinsKey);
      final savedLmp = prefs.getString(_lmpKey);

      DateTime? parsedDate;
      if (savedLmp != null) {
        parsedDate = DateTime.tryParse(savedLmp);
      }

      if (!mounted) return;

      setState(() {
        _nameController.text = savedName ?? '';
        _bpmController.text = savedBpm == null ? '' : '$savedBpm';
        _isTwins = savedTwins ?? false;
        _lmpDate = parsedDate;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _message('Could not load saved details.');
    }
  }

  Future<bool> _saveDetails({
    required String name,
    required int bpm,
    required bool isTwins,
    required DateTime lmpDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_nameKey, name);
      await prefs.setInt(_bpmKey, bpm);
      await prefs.setBool(_twinsKey, isTwins);
      await prefs.setString(_lmpKey, lmpDate.toIso8601String());

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bpmController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _lmpDate ?? now,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: purple,
              surface: fieldColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _lmpDate = picked);
    }
  }

  Widget _label(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        '$emoji  $text',
        style: const TextStyle(
          color: Color(0xFFC18BE8),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 25,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFF42234F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: purple, width: 1.5),
        ),
      ),
    );
  }

  Widget _babyOption({
    required String emoji,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 130,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF351348) : fieldColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: selected ? purple : const Color(0xFF42234F),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 15),
              Text(
                selected ? '$title ✓' : title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    if (_isLoading || _isSaving) return;

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _message('Please enter mother name.');
      return;
    }

    if (_lmpDate == null) {
      _message('Please select your LMP date.');
      return;
    }

    final bpmText = _bpmController.text.trim();
    final bpm = bpmText.isEmpty ? 0 : int.tryParse(bpmText);

    if (bpm == null || bpm < 0) {
      _message('Please enter a valid BPM.');
      return;
    }

    setState(() => _isSaving = true);

    final saved = await _saveDetails(
      name: name,
      bpm: bpm,
      isTwins: _isTwins,
      lmpDate: _lmpDate!,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (!saved) {
      _message('Could not save details. Please try again.');
      return;
    }

    _message('Details saved successfully! 💜');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimationScreen(
          motherName: name,
          isTwins: _isTwins,
          lmpDate: _lmpDate!,
          bpm: bpm,
        ),
      ),
    );
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0014),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF170321),
                    Color(0xFF0A0014),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: FloatingBabyBackground(),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: purple),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 24,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 600),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        icon: const Icon(
                                          Icons.chevron_left,
                                          color: Color(0xFFDDA6F5),
                                          size: 32,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: fieldColor,
                                          fixedSize: const Size(54, 54),
                                        ),
                                      ),
                                      const Spacer(),
                                      const Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            "Mom's Details",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 27,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      const SizedBox(width: 54),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Center(
                                    child: Text(
                                      'Enter your pregnancy information below.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF9279A7),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _label('👤', 'MOTHER NAME'),
                                  _field(
                                    controller: _nameController,
                                    hint: 'Enter your name',
                                  ),
                                  const SizedBox(height: 22),
                                  _label('🤱', 'PREGNANCY TYPE'),
                                  Row(
                                    children: [
                                      _babyOption(
                                        emoji: '👶',
                                        title: 'Single Baby',
                                        selected: !_isTwins,
                                        onTap: () {
                                          setState(() => _isTwins = false);
                                        },
                                      ),
                                      const SizedBox(width: 18),
                                      _babyOption(
                                        emoji: '👶👶',
                                        title: 'Twins',
                                        selected: _isTwins,
                                        onTap: () {
                                          setState(() => _isTwins = true);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),
                                  _label('📅', 'LMP DATE'),
                                  InkWell(
                                    onTap: _pickDate,
                                    borderRadius: BorderRadius.circular(28),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: fieldColor,
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color: const Color(0xFF42234F),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _lmpDate == null
                                                  ? 'dd/mm/yyyy'
                                                  : '${_lmpDate!.day.toString().padLeft(2, '0')}/'
                                                      '${_lmpDate!.month.toString().padLeft(2, '0')}/'
                                                      '${_lmpDate!.year}',
                                              style: TextStyle(
                                                color: _lmpDate == null
                                                    ? Colors.white70
                                                    : Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.calendar_month,
                                            color: Colors.white70,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  _label('💗', 'HEARTBEAT BPM'),
                                  _field(
                                    controller: _bpmController,
                                    hint: 'Enter BPM (e.g. 140)',
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 64,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFC94FD8),
                                            Color(0xFFFF4D9D),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(40),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x22E040FB),
                                            blurRadius: 14,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isSaving ? null : _continue,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          disabledBackgroundColor:
                                              Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                          ),
                                        ),
                                        child: Text(
                                          _isSaving
                                              ? 'Saving...'
                                              : 'Continue  ›',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class FloatingBabyBackground extends StatefulWidget {
  const FloatingBabyBackground({super.key});

  @override
  State<FloatingBabyBackground> createState() =>
      _FloatingBabyBackgroundState();
}

class _FloatingBabyBackgroundState extends State<FloatingBabyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: _BabyBackgroundPainter(_controller.value),
          );
        },
      ),
    );
  }
}

class _BabyBackgroundPainter extends CustomPainter {
  final double progress;

  _BabyBackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final time = progress * 2 * math.pi;

    for (int i = 0; i < 45; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final phase = i * 0.7;
      final y =
          (baseY + math.sin(time + phase) * 12 + size.height) %
              size.height;

      final opacity = 0.10 +
          0.20 * ((math.sin(time * 1.5 + phase) + 1) / 2);

      final starPaint = Paint()
        ..color = const Color(0xFFE8C8FF).withValues(alpha: opacity);

      final radius = i % 5 == 0 ? 1.8 : 1.1;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }

    _drawSymbol(canvas, size, '✦', 0.12, 0.18, time, 0.0, 23);
    _drawSymbol(canvas, size, '✧', 0.84, 0.16, time, 1.2, 25);
    _drawSymbol(canvas, size, '🍼', 0.07, 0.42, time, 2.0, 19);
    _drawSymbol(canvas, size, '♡', 0.87, 0.37, time, 2.8, 25);
    _drawSymbol(canvas, size, '✦', 0.83, 0.72, time, 3.4, 21);
    _drawSymbol(canvas, size, '🍼', 0.84, 0.84, time, 4.1, 19);
    _drawSymbol(canvas, size, '♡', 0.10, 0.79, time, 4.8, 25);
    _drawSymbol(canvas, size, '✧', 0.55, 0.25, time, 5.5, 18);
  }

  void _drawSymbol(
    Canvas canvas,
    Size size,
    String symbol,
    double x,
    double y,
    double time,
    double phase,
    double fontSize,
  ) {
    final floatY = size.height * y + math.sin(time + phase) * 13;

    final opacity =
        0.12 + 0.08 * ((math.sin(time + phase) + 1) / 2);

    final painter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: fontSize,
          color: const Color(0xFFDDBBFF).withValues(alpha: opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    painter.layout();
    painter.paint(canvas, Offset(size.width * x, floatY));
  }

  @override
  bool shouldRepaint(covariant _BabyBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

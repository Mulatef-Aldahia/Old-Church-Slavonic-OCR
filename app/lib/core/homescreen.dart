import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'modelservice.dart';
import 'oko_colors.dart';
import 'aboutscreen.dart';

// ثوابت وظيفية
const String _kGlyphFont = 'OkoGlyph';
const double _kMaxZoom = 4;
const double _kLabelFontSize = 10;

/// الشاشة الرئيسية لتطبيق oko:
/// مربع الصورة بإطار هندسي، تحته النص المخرج، ثم تفاصيل الحروف
/// على شكل جدول صفوف متحركة، وزر «ابدأ» مثبّت أسفل الشاشة.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// بايتات الصورة المختارة (null = لم تُختر صورة بعد).
  Uint8List? _imageBytes;

  /// أبعاد الصورة الأصلية بالبكسل (لضبط مواضع المربعات عند الرسم).
  ui.Size? _imageSize;

  /// الحروف المكتشفة من آخر تنفيذ.
  List<Detection> _detections = const [];

  /// تقرير آخر تشغيل (المقاس المعتمد وعدد الحروف عند كل مقاس).
  String _report = '';

  /// هل التشغيل جارٍ الآن؟ (لإظهار مؤشر الانتظار ومنع الضغط المتكرر)
  bool _isRunning = false;

  /// متحكم تكبير الصورة (يُصفَّر عند اختيار صورة جديدة).
  final TransformationController _zoomController = TransformationController();

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  /// يفتح معرض الصور، ويعرض المختارة داخل المربع.
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final size = await _decodeSize(bytes);
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageSize = size;
      _detections = const [];
      _zoomController.value = Matrix4.identity();
    });
  }

  /// يقرأ أبعاد الصورة من بايتاتها.
  static Future<ui.Size> _decodeSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = ui.Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    frame.image.dispose();
    return size;
  }

  /// النص المخرج: الحروف المكتشفة مركّبة بترتيب القراءة.
  String get _outputText {
    final buffer = StringBuffer();
    int? currentLine;
    for (final det in _detections) {
      // سطر جديد عند الانتقال إلى سطر آخر من الصورة
      if (currentLine != null && det.line != currentLine) buffer.write('\n');
      currentLine = det.line;
      buffer.write(det.label);
    }
    return buffer.toString().trim();
  }

  /// زر النسخ: ينسخ النص المخرج إلى الحافظة ويُعلم المستخدم.
  Future<void> _copyOutput() async {
    final text = _outputText;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم نسخ النص')));
  }

  /// زر «ابدأ»: يشغّل الموديل على الصورة المختارة ويرسم النتائج.
  Future<void> _onStartPressed() async {
    if (_isRunning) return;
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر صورة أولاً من المربع أعلاه')),
      );
      return;
    }
    setState(() {
      _isRunning = true;
      _detections = const [];
    });
    try {
      final results = await ModelService.instance.detect(_imageBytes!);
      if (!mounted) return;
      setState(() {
        _detections = results;
        _report = ModelService.instance.lastReport;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            results.isEmpty
                ? 'لم يتم العثور على أي حرف'
                : 'تم العثور على ${results.length} حرفاً '
                    '(${ModelService.instance.lastRunLabel})',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('حدث خطأ أثناء التنفيذ: $e')));
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // الشريط العلوي: عنوان التطبيق «oko»، لون واحد، بلا أي صورة
      appBar: AppBar(
        title: const Text(
          'oko',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        // أيقونة «عني» في الجانب الأيسر من الهيدر — تفتح صفحة العنتر
        actions: [
          IconButton(
            tooltip: 'عني',
            icon: const Icon(Icons.person_outline, size: 24),
            color: OkoColors.buttonText,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // شبكة مربعات صغيرة هندسية خلف المحتوى
          const Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageCard(),
                const SizedBox(height: 16),
                _buildOutputCard(),
                if (_report.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _report,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: OkoColors.muted,
                    ),
                  ),
                ],
                if (_detections.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildDetailsTable(),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
      // زر «ابدأ» مثبّت أسفل الشاشة دائماً
      bottomNavigationBar: _buildStartBar(),
    );
  }

  /// مربع الصورة: بطاقة بإطار خطي متقطع وعلامات زوايا مربعة،
  /// الضغط عليها يفتح المعرض، وبعد الاختيار تُعرض الصورة
  /// مع مربعات الحروف المكتشفة.
  Widget _buildImageCard() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: OkoColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: OkoColors.primary, width: 2),
          boxShadow: const [
            BoxShadow(
              color: OkoColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_imageBytes == null)
              Stack(
                fit: StackFit.expand,
                children: [
                  // خطوط أفقية هندسية خلفية داخل المربع الفارغ
                  const CustomPaint(painter: _EmptyStripesPainter()),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: OkoColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 38,
                          color: OkoColors.buttonText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'اضغط لاختيار صورة',
                        style: TextStyle(fontSize: 15, color: OkoColors.muted),
                      ),
                    ],
                  ),
                ],
              )
            else
              InteractiveViewer(
                transformationController: _zoomController,
                minScale: 1,
                maxScale: _kMaxZoom,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      _imageBytes!,
                      fit: BoxFit.contain,
                    ),
                    CustomPaint(
                      painter: _DetectionsPainter(
                        detections: _detections,
                        imageSize: _imageSize!,
                      ),
                    ),
                  ],
                ),
              ),
            // علامات زوايا مربعة فوق المحتوى
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _CornerMarksPainter()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// خانة النص المخرج: بطاقة بشريط علوي عنبري وأيقونة نسخ.
  Widget _buildOutputCard() {
    final hasText = _outputText.isNotEmpty;
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      decoration: BoxDecoration(
        color: OkoColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: OkoColors.line, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: OkoColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // شريط علوي عنبري رفيع
          Container(height: 4, color: OkoColors.accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'النص المستخرج',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: OkoColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasText ? _outputText : 'سيظهر النص هنا بعد التنفيذ',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.6,
                          fontFamily: hasText ? _kGlyphFont : null,
                          color: hasText ? OkoColors.ink : OkoColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  color: OkoColors.primary,
                  tooltip: 'نسخ النص',
                  onPressed: hasText ? _copyOutput : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// قسم تفاصيل الحروف: جدول صفوف له رأس وأعمدة، يظهر كل صف
  /// بحركة انزلاق أفقية متدرجة حسب ترتيب الحرف.
  Widget _buildDetailsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: OkoColors.accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'تفاصيل الحروف',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: OkoColors.ink,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: OkoColors.primary,
                borderRadius: const BorderRadius.all(Radius.circular(999)),
              ),
              child: Text(
                '${_detections.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: OkoColors.buttonText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: OkoColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: OkoColors.line, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: OkoColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // رأس الجدول
              Container(
                color: OkoColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '#',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: OkoColors.buttonText,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 48,
                      child: Text(
                        'الحرف',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: OkoColors.buttonText,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'الثقة',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: OkoColors.buttonText,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'البدائل',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: OkoColors.buttonText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < _detections.length; i++)
                _LetterRow(
                  key: ValueKey(_detections[i]),
                  index: i,
                  det: _detections[i],
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// شريط زر «ابدأ» المثبّت أسفل الشاشة.
  Widget _buildStartBar() {
    return Container(
      decoration: const BoxDecoration(
        color: OkoColors.surface,
        border: Border(top: BorderSide(color: OkoColors.line, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: OkoColors.shadow,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: OkoColors.button,
                foregroundColor: OkoColors.buttonText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: _isRunning ? null : _onStartPressed,
              child: _isRunning
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: OkoColors.buttonText,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.play_arrow_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'ابدأ',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// صف واحد في جدول تفاصيل الحروف، يظهر بحركة انزلاق أفقية
/// متدرجة (من جهة البداية) مع شريط ثقة يمتلئ تدريجياً.
class _LetterRow extends StatefulWidget {
  const _LetterRow({
    super.key,
    required this.index,
    required this.det,
  });

  final int index;
  final Detection det;

  @override
  State<_LetterRow> createState() => _LetterRowState();
}

class _LetterRowState extends State<_LetterRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    // ظهور متدرج: كل صف بعد سابقه بقليل (مع سقف للتأخير)
    Future.delayed(
      Duration(milliseconds: math.min(widget.index * 55, 450)),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// هل تُعرض هذه النسبة على الشاشة كـ 0%؟
  /// (صفر تماماً، أو أقل من نصف بالمئة فتُقرَّب إلى صفر)
  static bool _showsAsZeroPercent(double value) {
    if (value <= 0) return true;
    final rounded = (value * 100).toStringAsFixed(0);
    return rounded == '0';
  }

  /// نسبة مئوية صحيحة من قيمة بين 0 و1.
  static String _percentText(double value) =>
      '${(value * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    final det = widget.det;
    final alternatives = det.topCandidates
        .skip(1)
        .take(ModelService.topCandidatesCount)
        .where((alt) => !_showsAsZeroPercent(alt.score))
        .toList();

    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        // انزلاق أفقي من جهة البداية (RTL → من اليمين)
        position: Tween<Offset>(
          begin: const Offset(0.25, 0),
          end: Offset.zero,
        ).animate(_animation),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: widget.index == 0
                    ? Colors.transparent
                    : OkoColors.line,
              ),
            ),
          ),
          child: Row(
            children: [
              // رقم الترتيب في مربع صغير
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: OkoColors.background,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: OkoColors.line),
                ),
                child: Text(
                  '${widget.index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: OkoColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // الحرف
              SizedBox(
                width: 48,
                child: Text(
                  det.label,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.15,
                    fontFamily: _kGlyphFont,
                    color: OkoColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // شريط الثقة + النسبة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 7,
                        color: OkoColors.background,
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, _) => Align(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor:
                                _animation.value * det.confidence.clamp(0, 1),
                            child: Container(
                              height: 7,
                              color: OkoColors.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _percentText(det.confidence),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: OkoColors.detect,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // البدائل
              Expanded(
                child: alternatives.isNotEmpty
                    ? Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final alt in alternatives) _buildAltChip(alt),
                        ],
                      )
                    : const Text(
                        'لا توجد تنبؤات أخرى',
                        style: TextStyle(fontSize: 11, color: OkoColors.muted),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// خانة بديل واحد: الحرف ونسبته داخل خلفية فاتحة.
  Widget _buildAltChip(Candidate alt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: OkoColors.background,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: OkoColors.line),
      ),
      child: Text(
        '${alt.label} ${_percentText(alt.score)}',
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          fontSize: 11,
          fontFamily: _kGlyphFont,
          color: OkoColors.ink,
        ),
      ),
    );
  }
}

/// يرسم مربعات الحروف المكتشفة فوق الصورة، مع نص صغير
/// فوق كل مربع فيه الحرف ونسبة التأكد داخل خلفية صلبة.
class _DetectionsPainter extends CustomPainter {
  const _DetectionsPainter({
    required this.detections,
    required this.imageSize,
  });

  final List<Detection> detections;
  final ui.Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    // نفس حساب BoxFit.contain: تصغير الصورة لتناسب المربع مع التوسيط
    final scale = math.min(
      size.width / imageSize.width,
      size.height / imageSize.height,
    );
    final offsetX = (size.width - imageSize.width * scale) / 2;
    final offsetY = (size.height - imageSize.height * scale) / 2;

    final boxPaint = Paint()
      ..color = OkoColors.detect
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final bgPaint = Paint()..color = OkoColors.detect;

    for (final det in detections) {
      final rect = Rect.fromLTWH(
        offsetX + det.rect.left * scale,
        offsetY + det.rect.top * scale,
        det.rect.width * scale,
        det.rect.height * scale,
      );
      canvas.drawRect(rect, boxPaint);

      // النص: الحرف + نسبة التأكد — من اليمين لليسار
      final percent = (det.confidence * 100).toStringAsFixed(0);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${det.label} $percent%',
          style: TextStyle(
            color: OkoColors.buttonText,
            fontSize: _kLabelFontSize,
            fontWeight: FontWeight.bold,
            fontFamily: _kGlyphFont,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // خلفية النص: مستطيل صلب فوق المربع
      const pad = 3.0;
      final bgRect = Rect.fromLTWH(
        rect.left,
        (rect.top - textPainter.height - pad * 2).clamp(
          0,
          math.max(0, size.height - textPainter.height - pad * 2),
        ),
        textPainter.width + pad * 2,
        textPainter.height + pad * 2,
      );
      canvas.drawRect(bgRect, bgPaint);
      textPainter.paint(canvas, Offset(bgRect.left + pad, bgRect.top + pad));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionsPainter oldDelegate) =>
      oldDelegate.detections != detections ||
      oldDelegate.imageSize != imageSize;
}

/// علامات زوايا مربعة حول مربع الصورة (بدل الأقواس المائلة).
class _CornerMarksPainter extends CustomPainter {
  const _CornerMarksPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OkoColors.accent
      ..style = PaintingStyle.fill;

    const inset = 0.0;
    const mark = 14.0;
    final w = size.width;
    final h = size.height;

    // أربعة مربعات صغيرة في الزوايا
    canvas.drawRect(
      Rect.fromLTWH(inset, inset, mark, mark),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(w - mark - inset, inset, mark, mark),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(inset, h - mark - inset, mark, mark),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(w - mark - inset, h - mark - inset, mark, mark),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerMarksPainter oldDelegate) => false;
}

/// شبكة مربعات صغيرة خلف محتوى الشاشة (طابع هندسي).
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = OkoColors.pattern;
    const step = 30.0;
    for (double y = step; y < size.height; y += step) {
      for (double x = step; x < size.width; x += step) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: 2, height: 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

/// خطوط أفقية رفيعة داخل مربع الصورة الفارغ.
class _EmptyStripesPainter extends CustomPainter {
  const _EmptyStripesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = OkoColors.line;
    const step = 26.0;
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmptyStripesPainter oldDelegate) => false;
}

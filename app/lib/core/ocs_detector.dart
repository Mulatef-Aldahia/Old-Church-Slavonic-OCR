import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

/// مرشح واحد لحرف: الصنف ونسبة تأكده (تُستخدم في بطاقات التفاصيل).
class Candidate {
  const Candidate({
    required this.classIndex,
    required this.label,
    required this.score,
  });

  final int classIndex;

  /// الحرف المقابل.
  final String label;
  final double score;
}

/// حرف مكتشف على الصورة.
class Detection {
  const Detection({
    required this.rect,
    required this.classIndex,
    required this.label,
    required this.confidence,
    required this.topCandidates,
    this.line = 0,
  });

  /// موضع الحرف بإحداثيات الصورة الأصلية (بالبكسل).
  final ui.Rect rect;
  final int classIndex;

  /// الحرف الأعلى احتمالاً.
  final String label;

  /// نسبة التأكد في [label] (من 0 إلى 1).
  final double confidence;

  /// أعلى البدائل مرتبة تنازلياً.
  final List<Candidate> topCandidates;

  /// رقم السطر (يبدأ من 0) — يُستخدم لفصل الأسطر في النص المخرج.
  final int line;
}

/// وضع التشغيل:
/// - [auto]: يشغّل موديل القصاصات وموديل الصفحات ويعتمد الأكثر حروفاً
///   (هذا ما فعله الدفتر في كولاب).
/// - [page]: موديل الصفحات فقط.
/// - [crop]: موديل القصاصات فقط.
enum InferenceMode { auto, page, crop }

/// وصف موديل واحد من الموديلين.
class _EngineSpec {
  const _EngineSpec(this.name, this.asset, this.defaultSize);

  /// الاسم المعروض في التقرير.
  final String name;

  /// مسار ملف ONNX داخل الأصول.
  final String asset;

  /// المقاس المستعمل إن كان الموديل ديناميكي الأبعاد.
  final int defaultSize;
}

/// موديل محمّل جاهز للتشغيل.
class _Engine {
  _Engine({
    required this.spec,
    required this.session,
    required this.inputName,
    required this.fixedWidth,
    required this.fixedHeight,
    required this.names,
  });

  final _EngineSpec spec;
  final OrtSession session;
  final String inputName;

  /// مقاس الدخل الثابت، أو null إن كان الموديل ديناميكي الأبعاد.
  final int? fixedWidth;
  final int? fixedHeight;
  final List<String> names;

  bool get isDynamic => fixedWidth == null || fixedHeight == null;
}

/// تمريرة مطلوبة: موديل + مقاس (0 = المقاس الثابت للموديل).
class _Plan {
  const _Plan(this.engine, this.size);

  final _Engine engine;
  final int size;

  /// المقاس الفعلي الذي سيراه الموديل (ضلعه الأطول).
  int get effectiveSize => engine.isDynamic
      ? size
      : math.max(engine.fixedWidth!, engine.fixedHeight!);
}

/// خدمة تشغيل الموديل — مطابقة لما نُفِّذ في كولاب:
///
/// الدفتر صدّر نفس الموديل (v6) إلى ملفَّي ONNX:
///   1) `yolov8n_ocs_FINAL_v6_page_1280.onnx` للصفحات الكاملة
///   2) `yolov8n_ocs_FINAL_v6_crop_320.onnx` للقصاصات الصغيرة
/// ثم شغّل المقاسين على الصورة نفسها وأخذ نتيجة الأكثر حروفاً، بعد
/// حذف الصنف 0 (المسافة الميتة)، بثقة 0.25 وتداخل 0.7.
/// هذا ما تفعله هذه الخدمة بالضبط.
///
/// الأصول المطلوبة (انسخها من مجلد models في Drive):
///   assets/models/oko_model_1.onnx  ← yolov8n_ocs_FINAL_v6_crop_320.onnx
///   assets/models/oko_model.onnx     ← yolov8n_ocs_FINAL_v6_page_1280.onnx
/// وإن وُجد الموديل الديناميكي فقط (في أحد المكانين) فتُجرَّب منه
/// المقاسات 320 و1280 تلقائياً.
class ModelService {
  ModelService._();

  /// النسخة الوحيدة المستخدمة في كل التطبيق.
  static final ModelService instance = ModelService._();

  // ===== ثوابت التشغيل =====

  /// موديل القصاصات (مقاس 320).
  static const String cropAssetPath = 'assets/models/oko_model_1.onnx';

  /// موديل الصفحات (مقاس 1280) — الاسم القديم محفوظ ليبقى التطبيق يعمل.
  static const String pageAssetPath = 'assets/models/oko_model.onnx';

  static const int cropImgSize = 320;
  static const int pageImgSize = 1280;

  /// خريطة الأصناف الرسمية (v6_names.json من الدفتر): 47 اسماً بالترتيب
  /// نفسه الذي دُرّب به الموديل. هي المرجع الأول للحروف، وإن غابت
  /// نرجع إلى أسماء الميتاداتا داخل ملف ONNX.
  static const String namesAssetPath = 'assets/models/v6_names.json';

  static const List<_EngineSpec> _specs = [
    _EngineSpec('قصاصة', cropAssetPath, cropImgSize),
    _EngineSpec('صفحة', pageAssetPath, pageImgSize),
  ];

  /// مقاسات تُجرَّب إن كان لدينا موديل ديناميكي واحد فقط.
  static const List<int> singleDynamicSizes = [cropImgSize, pageImgSize];

  /// حد الثقة الأدنى لقبول حرف مكتشف (من 0 إلى 1).
  static const double confidenceThreshold = 0.25;

  /// حد التداخل (IoU) لحذف المربعات المكررة للحرف نفسه (من 0 إلى 1)،
  /// ويُطبَّق لكل صنف على حدة — نفس iou في الدفتر.
  static const double iouThreshold = 0.7;

  /// عدد البدائل المحفوظة لكل حرف (تُعرض منها الأولى في بطاقات التفاصيل).
  static const int topCandidatesCount = 5;

  /// أقصى عدد حروف تُرجع للصورة الواحدة (نفس max_det وقت التدريب).
  static const int maxDetections = 1000;

  /// الأصناف المهملة: الصنف 0 هو «المسافة الميتة» ويُحذف دائماً.
  static const Set<int> ignoredClassIndices = {0};

  List<_Engine> _engines = const [];
  List<String> _missing = const [];
  Future<void>? _loading;
  List<String> _classNames = const [];

  /// تحذيرات التشغيل الحالي (مثل اختلاف عدد الأصناف) تظهر في التقرير.
  final Set<String> _warnings = <String>{};

  // معلومات آخر تشغيل (لإظهارها للمستخدم وللتحقق).
  String _lastName = '';
  int _lastSize = 0;

  /// تقرير آخر تشغيل: عدد الحروف عند كل موديل والمعتمد.
  /// يُعرض في الشاشة ليظهر الواقع الفعلي بدل التخمين.
  String lastReport = '';

  /// هل الموديل محمّل وجاهز؟
  bool get isLoaded => _engines.isNotEmpty;

  /// هل لدينا أكثر من خيار فعلي (موديلان أو موديل ديناميكي)؟
  bool get supportsHybrid =>
      _engines.length > 1 || _engines.any((e) => e.isDynamic);

  /// وصف مختصر لآخر تشغيل، مثل: «وضع القصاصة 320».
  String get lastRunLabel =>
      _lastName.isEmpty ? '' : 'وضع $_lastName $_lastSize';

  /// الحرف المقابل لفهرس الصنف، كما ورد في البيانات الوصفية
  /// للموديل نفسه (أسماء الأصناف هي الحروف المكتشفة).
  String labelFor(int classIndex) =>
      classIndex < _classNames.length
          ? _classNames[classIndex]
          : '$classIndex';

  /// يحمّل الموديلين مرة واحدة فقط (الناقص منهما يُتخطى مع تسجيله).
  Future<void> load() async {
    if (_engines.isNotEmpty) return;
    final pending = _loading ??= _loadImpl();
    try {
      await pending;
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  static int? _positiveDim(Object? v) => (v is num && v > 0) ? v.toInt() : null;

  Future<void> _loadImpl() async {
    final loaded = <_Engine>[];
    final missing = <String>[];
    for (final spec in _specs) {
      try {
        loaded.add(await _loadEngine(spec));
      } catch (e) {
        missing.add(spec.asset);
        debugPrint('تعذّر تحميل ${spec.asset}: $e');
      }
    }
    if (loaded.isEmpty) {
      throw StateError('لم يُحمَّل أي موديل. تأكد من وجود الملفات في '
          'assets/models وتسجيلها في pubspec.yaml: '
          '${_specs.map((s) => s.asset).join(' ، ')}');
    }
    _engines = loaded;
    _missing = missing;
    final metaNames = loaded
        .map((e) => e.names)
        .firstWhere((n) => n.isNotEmpty, orElse: () => const []);
    final fileNames = await _loadNamesFile();
    if (fileNames.isNotEmpty) {
      _classNames = fileNames;
      if (metaNames.isNotEmpty) {
        final same = listEquals(
          [for (final n in metaNames) n.trim()],
          [for (final n in fileNames) n.trim()],
        );
        debugPrint(same
            ? 'أسماء الأصناف: الملف يطابق ميتاداتا الموديل ✅'
            : '⚠️ أسماء الأصناف في $namesAssetPath (${fileNames.length}) '
                'تختلف عن ميتاداتا الموديل (${metaNames.length}) — '
                'يُعتمد الملف.');
      }
    } else {
      _classNames = metaNames;
      debugPrint('تنبيه: $namesAssetPath غير موجود، اعتُمدت ميتاداتا الموديل.');
    }
    debugPrint('أسماء الحروف (${_classNames.length}): $_classNames');
    debugPrint('الموديلات المحمّلة: '
        '${loaded.map((e) => e.spec.asset).join(' ، ')}'
        '${missing.isEmpty ? '' : ' | الناقصة: ${missing.join(' ، ')}'}');
  }

  /// يقرأ خريطة الأصناف من الأصول (قائمة JSON من النصوص). فارغة إن غابت.
  Future<List<String>> _loadNamesFile() async {
    try {
      final decoded = jsonDecode(await rootBundle.loadString(namesAssetPath));
      if (decoded is List) return [for (final e in decoded) e.toString()];
    } catch (e) {
      debugPrint('تعذّر قراءة $namesAssetPath: $e');
    }
    return const [];
  }

  Future<_Engine> _loadEngine(_EngineSpec spec) async {
    final session = await OnnxRuntime().createSessionFromAsset(spec.asset);
    final inputName = session.inputNames.first;

    debugPrint('=== ${spec.asset} ===');
    debugPrint('أسماء الدخل: ${session.inputNames}');
    debugPrint('أسماء الخرج: ${session.outputNames}');
    final inputInfo = await session.getInputInfo();
    for (final info in inputInfo) {
      debugPrint('دخل: $info');
    }
    for (final info in await session.getOutputInfo()) {
      debugPrint('خرج: $info');
    }

    final metadata = await session.getMetadata();
    final names = _parseClassNames(metadata.customMetadataMap['names']);

    // مقاس الدخل: ثابت إن كانت الأبعاد أرقاماً موجبة، وديناميكي إن كانت
    // -1 أو 0 أو نصاً (مثل "height").
    var readable = false;
    int? h;
    int? w;
    if (inputInfo.isNotEmpty) {
      final shape = inputInfo.first['shape'];
      if (shape is List && shape.length == 4) {
        readable = true;
        h = _positiveDim(shape[2]);
        w = _positiveDim(shape[3]);
      }
    }
    int? fixedH = h;
    int? fixedW = w;
    if (!readable) {
      // لم نستطع قراءة الشكل: نعامله كثابت بمقاس التدريب من الميتاداتا
      final imgsz = _parseImgSz(metadata.customMetadataMap['imgsz']);
      fixedH = imgsz?[0] ?? spec.defaultSize;
      fixedW = imgsz?[1] ?? spec.defaultSize;
    }
    if (fixedH == null || fixedW == null) {
      fixedH = null;
      fixedW = null;
    }
    debugPrint(fixedW == null
        ? 'الموديل ديناميكي الأبعاد'
        : 'الموديل ثابت المقاس $fixedW×$fixedH');

    return _Engine(
      spec: spec,
      session: session,
      inputName: inputName,
      fixedWidth: fixedW,
      fixedHeight: fixedH,
      names: names,
    );
  }

  /// يفك مقاس التدريب من نص الميتاداتا مثل ‎[1280, 1280]‎
  /// (Ultralytics تحفظه بالترتيب: الارتفاع ثم العرض).
  static List<int>? _parseImgSz(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final nums = RegExp(r'\d+')
        .allMatches(raw)
        .map((m) => int.parse(m.group(0)!))
        .where((n) => n > 0)
        .toList();
    if (nums.isEmpty) return null;
    if (nums.length == 1) return [nums[0], nums[0]];
    return [nums[0], nums[1]];
  }

  /// يفك صيغة أسماء الأصناف كما تحفظها أدوات التدريب:
  /// ‎{0: '', 1: 'а'}‎ أو ‎['', 'а']‎
  static List<String> _parseClassNames(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final byIndex = <int, String>{};
    for (final m in RegExp(r'''(\d+)\s*:\s*['"]([^'"]*)['"]''')
        .allMatches(raw)) {
      byIndex[int.parse(m.group(1)!)] = m.group(2)!;
    }
    if (byIndex.isNotEmpty) {
      final maxIndex = byIndex.keys.reduce(math.max);
      return List.generate(maxIndex + 1, (i) => byIndex[i] ?? '$i');
    }
    return RegExp(r'''['"]([^'"]*)['"]''')
        .allMatches(raw)
        .map((m) => m.group(1)!)
        .toList();
  }

  /// التمريرات المطلوبة لهذه الصورة حسب الوضع، الأصغر مقاساً أولاً.
  List<_Plan> _plansFor(InferenceMode mode) {
    final onlyOne = _engines.length == 1;
    final plans = <_Plan>[];
    for (final e in _engines) {
      if (!e.isDynamic) {
        plans.add(_Plan(e, 0));
      } else if (onlyOne) {
        // موديل ديناميكي وحيد: نجرّب منه مقاس القصاصة ومقاس الصفحة
        for (final s in singleDynamicSizes) {
          plans.add(_Plan(e, s));
        }
      } else {
        plans.add(_Plan(e, e.spec.defaultSize));
      }
    }
    var chosen = plans;
    if (mode == InferenceMode.crop) {
      chosen = plans.where((p) => p.effectiveSize <= 640).toList();
    } else if (mode == InferenceMode.page) {
      chosen = plans.where((p) => p.effectiveSize > 640).toList();
    }
    if (chosen.isEmpty) chosen = plans;
    chosen.sort((a, b) => a.effectiveSize.compareTo(b.effectiveSize));
    return chosen;
  }

  /// هندسة تغيير الحجم (Letterbox).
  _Geometry _geometry(_Engine e, int imgW, int imgH, int target) {
    if (!e.isDynamic) {
      final fw = e.fixedWidth!;
      final fh = e.fixedHeight!;
      final scale = math.min(fw / imgW, fh / imgH);
      final newW = math.max(1, (imgW * scale).round());
      final newH = math.max(1, (imgH * scale).round());
      return _Geometry(
        scale: scale,
        newW: newW,
        newH: newH,
        inW: fw,
        inH: fh,
        padX: (fw - newW) ~/ 2,
        padY: (fh - newH) ~/ 2,
      );
    }
    // ديناميكي: الضلع الأطول = المقاس المستهدف، والحشو لأقرب مضاعف لـ 32.
    final scale = math.min(target / imgW, target / imgH);
    final newW = math.max(1, (imgW * scale).round());
    final newH = math.max(1, (imgH * scale).round());
    final inW = ((newW + 31) ~/ 32) * 32;
    final inH = ((newH + 31) ~/ 32) * 32;
    return _Geometry(
      scale: scale,
      newW: newW,
      newH: newH,
      inW: inW,
      inH: inH,
      padX: (inW - newW) ~/ 2,
      padY: (inH - newH) ~/ 2,
    );
  }

  /// يشغّل الموديلين على الصورة ويرجع حروف الأكثر عدداً (كما في الدفتر)
  /// بترتيب القراءة: سطراً بعد سطر، وفي السطر من اليسار لليمين.
  Future<List<Detection>> detect(
    Uint8List imageBytes, {
    InferenceMode mode = InferenceMode.auto,
  }) async {
    await load();

    // فك ترميز الصورة إلى بكسلات RGBA (مرة واحدة لكل التمريرات)
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final imgW = image.width;
    final imgH = image.height;
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    final rgba = byteData!.buffer.asUint8List();

    _warnings.clear();
    final passes = <_Pass>[];
    final failed = <String>[];
    for (final plan in _plansFor(mode)) {
      try {
        final pass = await _runPass(plan, rgba, imgW, imgH);
        passes.add(pass);
        debugPrint('${pass.name} ${pass.size}: ${pass.boxes.length} حرف');
      } catch (e) {
        failed.add('${plan.engine.spec.name} ${plan.effectiveSize}');
        debugPrint('تعذّر التشغيل (${plan.engine.spec.asset}): $e');
      }
    }
    if (passes.isEmpty) {
      throw StateError('فشل تشغيل كل الموديلات: ${failed.join('، ')}');
    }

    // الاختيار كما في الدفتر: الأكثر حروفاً؛ وعند التساوي الأعلى ثقة.
    var chosen = passes.first;
    for (final p in passes.skip(1)) {
      if (p.boxes.length > chosen.boxes.length ||
          (p.boxes.length == chosen.boxes.length && p.score > chosen.score)) {
        chosen = p;
      }
    }
    _lastName = chosen.name;
    _lastSize = chosen.size;

    final counts =
        passes.map((p) => '${p.name} ${p.size}: ${p.boxes.length}').join(' · ');
    final notes = <String>[
      if (_missing.isNotEmpty) 'ملف غير موجود: ${_missing.join(' ، ')}',
      if (failed.isNotEmpty) 'تعذّر: ${failed.join('، ')}',
      ..._warnings,
    ];
    lastReport = 'الحروف عند كل موديل — $counts ← المعتمد $lastRunLabel'
        '${notes.isEmpty ? '' : '\n${notes.join(' | ')}'}';
    debugPrint('✅ $lastReport');

    final lines = _groupIntoLines(chosen.boxes);
    final result = <Detection>[];
    for (var li = 0; li < lines.length; li++) {
      for (final b in lines[li]) {
        result.add(Detection(
          rect: b.rect,
          classIndex: b.classIndex,
          label: labelFor(b.classIndex),
          confidence: b.confidence,
          topCandidates: b.scores,
          line: li,
        ));
      }
    }
    return result;
  }

  /// تمريرة واحدة: تجهيز الدخل، التشغيل، فك الخرج، حذف المكرر.
  Future<_Pass> _runPass(_Plan plan, Uint8List rgba, int imgW, int imgH) async {
    final e = plan.engine;
    final g = _geometry(e, imgW, imgH, plan.size);
    final inW = g.inW;
    final inH = g.inH;
    final name = e.spec.name;
    final size = plan.effectiveSize;

    // تجهيز الدخل في isolate منفصل حتى لا تتجمد الواجهة
    final input = await compute(
      _buildInput,
      _PrepArgs(
        rgba: rgba,
        imgW: imgW,
        imgH: imgH,
        newW: g.newW,
        newH: g.newH,
        padX: g.padX,
        padY: g.padY,
        inW: inW,
        inH: inH,
        scale: g.scale,
      ),
    );

    // تشغيل الموديل
    final inputValue = await OrtValue.fromList(input, [1, 3, inH, inW]);
    final outputs = await e.session
        .run({e.inputName: inputValue}).whenComplete(() => inputValue.dispose());
    final outValue = outputs.values.first;
    final shape = outValue.shape;
    final data = await outValue.asFlattenedList();
    await outValue.dispose();
    double valueAt(int i) => (data[i] as num).toDouble();

    // تحويل صندوق من إحداثيات الدخل إلى إحداثيات الصورة الأصلية
    ui.Rect toOriginal(double x1, double y1, double x2, double y2) {
      return ui.Rect.fromLTRB(
        ((x1 - g.padX) / g.scale).clamp(0.0, imgW.toDouble()),
        ((y1 - g.padY) / g.scale).clamp(0.0, imgH.toDouble()),
        ((x2 - g.padX) / g.scale).clamp(0.0, imgW.toDouble()),
        ((y2 - g.padY) / g.scale).clamp(0.0, imgH.toDouble()),
      );
    }

    final raw = <_RawBox>[];

    if (shape.length == 3 && shape[2] == 6) {
      // صيغة النتائج النهائية الجاهزة: [1، عدد، 6]
      final count = shape[1];
      for (var i = 0; i < count; i++) {
        final o = i * 6;
        final conf = valueAt(o + 4);
        if (conf < confidenceThreshold) continue;
        final cls = valueAt(o + 5).round();
        if (ignoredClassIndices.contains(cls)) continue;
        raw.add(_RawBox(
          rect: toOriginal(
              valueAt(o), valueAt(o + 1), valueAt(o + 2), valueAt(o + 3)),
          classIndex: cls,
          confidence: conf,
          scores: [
            Candidate(classIndex: cls, label: labelFor(cls), score: conf),
          ],
        ));
      }
    } else if (shape.length == 3) {
      // صيغة YOLO الخام: [1، 4+أصناف، نقاط] أو [1، نقاط، 4+أصناف]
      final channelsFirst = shape[1] < shape[2];
      final channels = channelsFirst ? shape[1] : shape[2];
      final anchors = channelsFirst ? shape[2] : shape[1];
      final numClasses = channels - 4;
      if (numClasses <= 0) {
        return _Pass(name: name, size: size, boxes: const []);
      }
      if (_classNames.isNotEmpty && numClasses != _classNames.length) {
        _warnings.add('⚠️ عدد أصناف ${e.spec.name} ($numClasses) '
            'لا يطابق خريطة الحروف (${_classNames.length})');
      }
      double at(int c, int n) =>
          channelsFirst ? valueAt(c * anchors + n) : valueAt(n * channels + c);

      for (var n = 0; n < anchors; n++) {
        var bestClass = 0;
        var bestScore = -1.0;
        for (var c = 0; c < numClasses; c++) {
          final s = at(4 + c, n);
          if (s > bestScore) {
            bestScore = s;
            bestClass = c;
          }
        }
        if (bestScore < confidenceThreshold) continue;
        // الصنف 0 (المسافة الميتة): يُهمل
        if (ignoredClassIndices.contains(bestClass)) continue;

        // كل بدائل هذا الحرف مرتبة تنازلياً (بدون الأصناف المهملة)
        final scores = List.generate(numClasses, (c) => at(4 + c, n));
        final order = List.generate(numClasses, (c) => c)
            .where((c) => !ignoredClassIndices.contains(c))
            .toList()
          ..sort((a, b) => scores[b].compareTo(scores[a]));
        final candidates = order
            .take(topCandidatesCount + 1)
            .map((c) =>
                Candidate(classIndex: c, label: labelFor(c), score: scores[c]))
            .toList();

        final cx = at(0, n);
        final cy = at(1, n);
        final w = at(2, n);
        final h = at(3, n);
        raw.add(_RawBox(
          rect: toOriginal(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2),
          classIndex: bestClass,
          confidence: bestScore,
          scores: candidates,
        ));
      }

      // حذف المربعات المكررة (NMS) لكل صنف على حدة — مطابق لـ Ultralytics.
      raw.sort((a, b) => b.confidence.compareTo(a.confidence));
      final kept = <_RawBox>[];
      for (final box in raw) {
        final duplicated = kept.any(
          (k) =>
              k.classIndex == box.classIndex &&
              _iou(k.rect, box.rect) > iouThreshold,
        );
        if (!duplicated) kept.add(box);
      }
      raw
        ..clear()
        ..addAll(kept);
    }

    // سقف عدد الحروف (الأعلى ثقة أولاً)
    raw.sort((a, b) => b.confidence.compareTo(a.confidence));
    if (raw.length > maxDetections) {
      raw.removeRange(maxDetections, raw.length);
    }
    return _Pass(name: name, size: size, boxes: raw);
  }

  /// يجمّع الصناديق في أسطر: صناديق متقاربة رأسياً تُعدّ سطراً واحداً،
  /// وكل سطر يُرتَّب من اليسار لليمين (OCS يُقرأ يساراً-يميناً).
  static List<List<_RawBox>> _groupIntoLines(List<_RawBox> boxes) {
    if (boxes.isEmpty) return const [];
    final byY = [...boxes]
      ..sort((a, b) => a.rect.center.dy.compareTo(b.rect.center.dy));

    final lines = <List<_RawBox>>[];
    var sumY = 0.0;
    var sumH = 0.0;
    for (final box in byY) {
      if (lines.isNotEmpty) {
        final count = lines.last.length;
        final meanY = sumY / count;
        final meanH = sumH / count;
        if ((box.rect.center.dy - meanY).abs() <= meanH * 0.6) {
          lines.last.add(box);
          sumY += box.rect.center.dy;
          sumH += box.rect.height;
          continue;
        }
      }
      lines.add([box]);
      sumY = box.rect.center.dy;
      sumH = box.rect.height;
    }
    for (final line in lines) {
      line.sort((a, b) => a.rect.center.dx.compareTo(b.rect.center.dx));
    }
    return lines;
  }

  /// نسبة تداخل صندوقين (IoU).
  static double _iou(ui.Rect a, ui.Rect b) {
    final inter = a.intersect(b);
    if (inter.width <= 0 || inter.height <= 0) return 0;
    final interArea = inter.width * inter.height;
    final unionArea = a.width * a.height + b.width * b.height - interArea;
    return unionArea <= 0 ? 0 : interArea / unionArea;
  }
}

/// نتيجة تمريرة واحدة.
class _Pass {
  _Pass({required this.name, required this.size, required this.boxes})
      : score = boxes.fold<double>(
          0,
          (sum, b) => sum + b.confidence * b.confidence,
        );

  final String name;
  final int size;
  final List<_RawBox> boxes;

  /// مجموع مربعات الثقة (للفصل عند تساوي عدد الحروف فقط).
  final double score;
}

/// هندسة تغيير الحجم.
class _Geometry {
  const _Geometry({
    required this.scale,
    required this.newW,
    required this.newH,
    required this.inW,
    required this.inH,
    required this.padX,
    required this.padY,
  });

  final double scale;
  final int newW;
  final int newH;
  final int inW;
  final int inH;
  final int padX;
  final int padY;
}

/// معطيات تجهيز الدخل (تُرسل إلى isolate).
class _PrepArgs {
  const _PrepArgs({
    required this.rgba,
    required this.imgW,
    required this.imgH,
    required this.newW,
    required this.newH,
    required this.padX,
    required this.padY,
    required this.inW,
    required this.inH,
    required this.scale,
  });

  final Uint8List rgba;
  final int imgW;
  final int imgH;
  final int newW;
  final int newH;
  final int padX;
  final int padY;
  final int inW;
  final int inH;
  final double scale;
}

/// تجهيز الدخل: تغيير الحجم (Bilinear) مع الحفاظ على النسبة وحشو الفراغ
/// بلون رمادي (طريقة YOLO المعتادة: Letterbox). دالة عليا ليعمل `compute`.
Float32List _buildInput(_PrepArgs a) {
  final plane = a.inW * a.inH;
  final out = Float32List(3 * plane);
  out.fillRange(0, out.length, 114 / 255);

  // إحداثيات الأعمدة تُحسب مرة واحدة
  final x0s = List<int>.filled(a.newW, 0);
  final x1s = List<int>.filled(a.newW, 0);
  final fxs = List<double>.filled(a.newW, 0);
  for (var dx = 0; dx < a.newW; dx++) {
    final srcX =
        ((dx + 0.5) / a.scale - 0.5).clamp(0.0, a.imgW - 1.0).toDouble();
    final x0 = srcX.floor();
    x0s[dx] = x0;
    x1s[dx] = math.min(x0 + 1, a.imgW - 1);
    fxs[dx] = srcX - x0;
  }

  final rgba = a.rgba;
  for (var dy = 0; dy < a.newH; dy++) {
    final srcY =
        ((dy + 0.5) / a.scale - 0.5).clamp(0.0, a.imgH - 1.0).toDouble();
    final y0 = srcY.floor();
    final y1 = math.min(y0 + 1, a.imgH - 1);
    final fy = srcY - y0;
    final rowTop = y0 * a.imgW;
    final rowBottom = y1 * a.imgW;
    final outRow = (a.padY + dy) * a.inW + a.padX;

    for (var dx = 0; dx < a.newW; dx++) {
      final fx = fxs[dx];
      final i00 = (rowTop + x0s[dx]) * 4;
      final i10 = (rowTop + x1s[dx]) * 4;
      final i01 = (rowBottom + x0s[dx]) * 4;
      final i11 = (rowBottom + x1s[dx]) * 4;
      final pos = outRow + dx;
      for (var c = 0; c < 3; c++) {
        final top = rgba[i00 + c] * (1 - fx) + rgba[i10 + c] * fx;
        final bottom = rgba[i01 + c] * (1 - fx) + rgba[i11 + c] * fx;
        out[c * plane + pos] = (top * (1 - fy) + bottom * fy) / 255;
      }
    }
  }
  return out;
}

/// صندوق خام قبل التحويل إلى [Detection].
class _RawBox {
  const _RawBox({
    required this.rect,
    required this.classIndex,
    required this.confidence,
    required this.scores,
  });

  final ui.Rect rect;
  final int classIndex;
  final double confidence;
  final List<Candidate> scores;
}

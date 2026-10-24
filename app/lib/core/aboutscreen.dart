import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'oko_colors.dart';

/// صفحة «عني» لتطبيق oko — نبذة عن مطوّر التطبيق وروابط التواصل.
///
/// مبنية بنفس هوية تطبيق oko (OkoColors، بطاقات ذات حواف مستديرة رفيعة،
/// وشريط علوي بنفس شريط الشاشة الرئيسية) حتى تكون متناسقة مع بقية
/// الشاشات في هذا المشروع.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _isArabic = false;
  static const String _headlineTarget =
      'Mulatef Aldahia\nFull Stack Developer';
  String _typedHeadline = '';
  Timer? _typingTimer;

  String _text(String english, String arabic) => _isArabic ? arabic : english;

  /// الصورة الشخصية: ملف `My.png` في مجلد `Images`.
  static const String _avatarPath = 'assets/Images/My.png';

  /// (الاسم، الأيقونة، لون الدائرة، الرابط) — روابط ملاطف الداهية فقط.
  static const _contacts = [
    (
      'GitHub',
      Icons.code,
      OkoColors.primary,
      'https://github.com/Mulatef-Aldahia',
    ),
    (
      'LinkedIn',
      Icons.business,
      Color(0xFF0A66C2),
      'https://www.linkedin.com/in/ملاطف-الداهية-71416a32b',
    ),
    (
      'WhatsApp',
      Icons.chat,
      Color(0xFF25D366),
      'https://wa.me/967771770119',
    ),
  ];

  static const _programmingLanguages = [
    'C++',
    'C#',
    'Python',
    'JavaScript',
    'PHP',
  ];

  static const _webTechnologies = [
    'HTML5',
    'CSS3',
    'React.js',
    'Vite',
  ];

  static const _databases = ['SQL', 'SQL Server'];

  static const _tools = ['Git', 'GitHub'];

  /// (الاسم بالإنجليزية، الاسم بالعربية، الاختصار)
  static const _interests = [
    ('Digital Image Processing', 'معالجة الصور الرقمية', 'DIP'),
    ('Optical Character Recognition', 'التعرّف الضوئي على الحروف', 'OCR'),
    ('Natural Language Processing', 'معالجة اللغة الطبيعية', 'NLP'),
    ('Data Mining', 'تنقيب البيانات', 'DM'),
    ('Problem Solving', 'حل المشكلات', 'PS'),
  ];

  static const _learning = ['Flutter', 'Laravel'];

  @override
  void initState() {
    super.initState();
    _startHeadlineTyping();
  }

  /// يكتب الاسم والمسمى الوظيفي تدريجيًا عند فتح الصفحة.
  void _startHeadlineTyping() {
    var index = 0;
    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 85), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (index >= _headlineTarget.length) {
        timer.cancel();
        return;
      }
      setState(() {
        index++;
        _typedHeadline = _headlineTarget.substring(0, index);
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  /// يفتح رابطا في المتصفح (يُفتَح في تطبيق خارجي على كل المنصات).
  Future<void> _openLink(String url) async {
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الرابط')),
        );
      }
    } catch (_) {
      // إذا تعذّر فتح الرابط (مشكلة في النظام أو المتصفح) — إظهار تنبيه.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح الرابط')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text('About Me', 'عني'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: TextButton(
              onPressed: () => setState(() => _isArabic = !_isArabic),
              style: TextButton.styleFrom(
                foregroundColor: OkoColors.buttonText,
              ),
              child: Text(_isArabic ? 'English' : 'العربية'),
            ),
          ),
        ],
      ),
      body: Container(
        color: OkoColors.background,
        child: Directionality(
          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              _buildPhoto(),
              // الاسم والمسمى الوظيفي يُكتبان تدريجيًا عند فتح الصفحة.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _typedHeadline,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: OkoColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: _text('About Me', 'نبذة عني'),
                child: Text(
                  _text(
                    'I am a fourth-year Information Technology student at '
                    'the College of Computing and Applied Sciences. I am '
                    'interested in full-stack development, software analysis '
                    'and design, and building practical solutions. My project '
                    'experience and learning interests include programming, '
                    'database-driven applications, digital image processing '
                    '(DIP), OCR, NLP, data mining, and problem solving.',
                    'أنا ملاطف الداهية، طالب تقنية معلومات في السنة '
                    'الرابعة بكلية الحاسبات والعلوم التطبيقية. أهتم بتطوير '
                    'تطبيقات الويب المتكاملة وتحليل الأنظمة وتصميمها وبناء '
                    'حلول عملية. تشمل خبراتي ومشاريعي الدراسية البرمجة '
                    'وتطبيقات قواعد البيانات، كما أهتم بمعالجة الصور '
                    'الرقمية (DIP)، والتعرّف الضوئي على الحروف (OCR)، '
                    'ومعالجة اللغة الطبيعية (NLP)، وتنقيب البيانات، وحل '
                    'المشكلات.',
                  ),
                  textDirection: _isArabic
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  style: const TextStyle(fontSize: 15, height: 1.7),
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: _text('Programming Languages', 'لغات البرمجة'),
                child: _chips(_programmingLanguages),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: _text('Web Technologies', 'تقنيات الويب'),
                child: _chips(_webTechnologies),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: _text('Databases', 'قواعد البيانات'),
                child: _chips(_databases),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: _text(
                    'Tools & Version Control',
                    'أدوات التطوير وإدارة الإصدارات'),
                child: _chips(_tools),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: _text('Areas of Interest', 'مجالات الاهتمام'),
                child: _interestList(),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: _text('Currently Learning', 'تقنيات أتعلمها حاليًا'),
                child: _chips(_learning),
              ),
              const SizedBox(height: 20),
              Text(
                _text('Contact', 'تواصل معي'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: OkoColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < _contacts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    _contactButton(
                      label: _contacts[i].$1,
                      icon: _contacts[i].$2,
                      color: _contacts[i].$3,
                      url: _contacts[i].$4,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// الصورة الشخصية: مستطيلة بعرض المحتوى كاملًا وتظهر كاملة
  /// بدون قصّ. إن لم توجد تُعرض بطاقة بديلة بحرف الاسم.
  Widget _buildPhoto() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: OkoColors.surface,
        border: Border.all(color: OkoColors.line, width: 1.5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: OkoColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        _avatarPath,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          height: 180,
          child: Center(
            child: Text(
              'م',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: OkoColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// نقاط تمثيلية لمجالات الاهتمام (تُستبدل بالبيانات الفعلية).
  Widget _interestList() {
    return Column(
      children: [
        for (final (englishName, arabicName, short) in _interests)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 16,
                    color: OkoColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    _text(englishName, arabicName),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                Text(
                  short,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: OkoColors.accent,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// زر تواصل دائري بلون العلامة التجارية — الأيقونة في الوسط تمامًا.
  Widget _contactButton({
    required String label,
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return InkWell(
      onTap: () => _openLink(url),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: const [
                BoxShadow(
                  color: OkoColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: OkoColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة قسم: بنفس ستايل بطاقات الشاشة الرئيسية.
  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: OkoColors.surface,
        border: Border.all(color: OkoColors.line, width: 1.5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: OkoColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: OkoColors.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: OkoColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  /// رقائق نصية (للمهارات وما يُتعلَّم حاليًا).
  Widget _chips(List<String> items) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: OkoColors.background,
              border: Border.all(color: OkoColors.line),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(item, style: const TextStyle(fontSize: 14)),
          ),
      ],
    );
  }
}

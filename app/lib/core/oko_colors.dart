import 'package:flutter/material.dart';

/// ألوان تطبيق oko — لوحة دافئة (بني داكن / عنبري) بطابع هندسي.
///
/// أي تعديل على لون يتم من هنا فقط.
class OkoColors {
  OkoColors._();

  // ===== الخلفيات والبطاقات =====
  static const Color background = Color(0xFFF7F3EC); // خلفية الشاشات (بيج فاتح دافئ)
  static const Color surface = Color(0xFFFFFBF5); // البطاقات
  static const Color line = Color(0xFFE4D9C6); // حدود البطاقات والفواصل

  // ===== الهوية =====
  static const Color primary = Color(0xFF2B2118); // بني داكن جداً — الشريط العلوي والعناوين
  static const Color primarySoft = Color(0xFF4A382A); // بني أفتح — الأشكال الثانوية
  static const Color accent = Color(0xFFE08A2B); // عنبري برتقالي — اللمسات والزخرفة

  // ===== زر البدء =====
  static const Color button = Color(0xFFC2410C); // برتقالي محروق — زر «ابدأ»
  static const Color buttonText = Color(0xFFFFFBF5);

  // ===== النصوص =====
  static const Color ink = Color(0xFF2B2118); // نص أساسي
  static const Color muted = Color(0xFF7C6A58); // نص ثانوي وأيقونات

  // ===== الكشف على الصورة =====
  static const Color detect = Color(0xFF0E7490); // سماوي غامق — مربعات الحروف ونسبها

  // ===== الظلال والزخرفة =====
  static const Color shadow = Color(0x142B2118); // ظل ناعم بني للبطاقات
  static const Color pattern = Color(0x0D2B2118); // نقاط الشبكة الهندسية الخلفية
}

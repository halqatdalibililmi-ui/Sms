// ═══════════════════════════════════════════════════════════════════════════
// Academic School Management System — Single File
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DB.I.init();
  await Auth.seedDefaults();
  runApp(const AcademicApp());
}

class AcademicApp extends StatefulWidget {
  const AcademicApp({super.key});
  @override
  State<AcademicApp> createState() => _AcademicAppState();
}

class _AcademicAppState extends State<AcademicApp> {
  Locale _locale = const Locale('ar');
  ThemeMode _mode = ThemeMode.light;
  Color _seed = const Color(0xFF1565C0);

  void setLocale(Locale l) => setState(() => _locale = l);
  void setMode(ThemeMode m) => setState(() => _mode = m);
  void setSeed(Color c) => setState(() => _seed = c);

  @override
  Widget build(BuildContext context) {
    return AppCtx(
      locale: _locale,
      mode: _mode,
      seed: _seed,
      setLocale: setLocale,
      setMode: setMode,
      setSeed: setSeed,
      child: MaterialApp(
        title: 'Academic SMS',
        debugShowCheckedModeBanner: false,
        locale: _locale,
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: _buildTheme(_seed, Brightness.light),
        darkTheme: _buildTheme(_seed, Brightness.dark),
        themeMode: _mode,
        home: const RootGate(),
      ),
    );
  }

  ThemeData _buildTheme(Color seed, Brightness b) {
    final s = ColorScheme.fromSeed(seedColor: seed, brightness: b);
    return ThemeData(
      useMaterial3: true,
      colorScheme: s,
      scaffoldBackgroundColor: s.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: s.primary, foregroundColor: s.onPrimary, elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
    );
  }
}

// Context for global settings changes
class AppCtx extends InheritedWidget {
  final Locale locale;
  final ThemeMode mode;
  final Color seed;
  final void Function(Locale) setLocale;
  final void Function(ThemeMode) setMode;
  final void Function(Color) setSeed;
  const AppCtx({
    super.key, required this.locale, required this.mode, required this.seed,
    required this.setLocale, required this.setMode, required this.setSeed,
    required super.child,
  });
  static AppCtx of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<AppCtx>()!;
  @override
  bool updateShouldNotify(AppCtx old) =>
      locale != old.locale || mode != old.mode || seed != old.seed;
}

// ═══════════════════════════════════════════════════════════════════════════
// LOCALIZATION (simple inline map)
// ═══════════════════════════════════════════════════════════════════════════
class L {
  static const _m = <String, Map<String, String>>{
    'ar': {
      'app_title': 'نظام إدارة المدرسة',
      'login': 'دخول', 'username': 'اسم المستخدم / رقم التسجيل',
      'password': 'كلمة المرور', 'school': 'المدرسة',
      'dashboard': 'الرئيسية', 'students': 'الطلاب', 'teachers': 'المعلمون',
      'classes': 'الفصول', 'subjects': 'المواد', 'attendance': 'الحضور',
      'exams': 'الامتحانات', 'grades': 'الدرجات', 'fees': 'الرسوم',
      'payments': 'المدفوعات', 'certificates': 'الشهادات', 'cards': 'البطاقات',
      'reports': 'التقارير', 'settings': 'الإعدادات', 'audit': 'سجل العمليات',
      'logout': 'خروج', 'save': 'حفظ', 'cancel': 'إلغاء', 'delete': 'حذف',
      'edit': 'تعديل', 'add': 'إضافة', 'search': 'بحث', 'name': 'الاسم',
      'full_name': 'الاسم الكامل', 'photo': 'الصورة', 'phone': 'الهاتف',
      'email': 'البريد', 'class': 'الصف', 'section': 'الشعبة',
      'registration_number': 'رقم التسجيل', 'gender': 'الجنس',
      'male': 'ذكر', 'female': 'أنثى', 'dob': 'تاريخ الميلاد',
      'address': 'العنوان', 'status': 'الحالة', 'active': 'نشط',
      'print': 'طباعة', 'pdf': 'PDF', 'share': 'مشاركة', 'preview': 'معاينة',
      'present': 'حاضر', 'absent': 'غائب', 'late': 'متأخر',
      'excused': 'بعذر', 'early': 'خروج مبكر',
      'total': 'المجموع', 'average': 'المتوسط', 'percentage': 'النسبة',
      'result': 'النتيجة', 'report_card': 'كشف الدرجات',
      'student_card': 'بطاقة الطالب', 'receipt': 'إيصال',
      'amount': 'المبلغ', 'date': 'التاريخ', 'notes': 'ملاحظات',
      'welcome': 'مرحبًا', 'my_profile': 'ملفي', 'my_grades': 'درجاتي',
      'my_attendance': 'حضوري', 'my_certificates': 'شهاداتي',
      'my_card': 'بطاقتي', 'announcements': 'الإعلانات',
      'notifications': 'الإشعارات', 'courses': 'الدورات',
      'academic_year': 'السنة الدراسية', 'term': 'الفصل الدراسي',
      'max_score': 'الدرجة القصوى', 'pass_score': 'درجة النجاح',
      'score': 'الدرجة', 'exam_title': 'عنوان الامتحان',
      'school_name': 'اسم المدرسة', 'school_logo': 'شعار المدرسة',
      'language': 'اللغة', 'theme': 'المظهر', 'dark_mode': 'الوضع الليلي',
      'light': 'فاتح', 'dark': 'داكن', 'system': 'تلقائي',
      'change_password': 'تغيير كلمة المرور', 'new_password': 'كلمة المرور الجديدة',
      'confirm': 'تأكيد', 'welcome_back': 'مرحبًا بعودتك',
      'no_data': 'لا توجد بيانات', 'loading': 'جاري التحميل...',
      'recent_activity': 'آخر العمليات', 'student_portal': 'بوابة الطالب',
      'teacher_portal': 'بوابة المعلم', 'parent_portal': 'بوابة ولي الأمر',
      'overview': 'نظرة عامة', 'total_students': 'إجمالي الطلاب',
      'total_teachers': 'إجمالي المعلمين', 'attendance_today': 'حضور اليوم',
      'absent_today': 'غياب اليوم', 'total_fees': 'إجمالي الرسوم',
      'paid': 'المدفوع', 'remaining': 'المتبقي',
    },
    'en': {
      'app_title': 'School Management System',
      'login': 'Login', 'username': 'Username / Registration No.',
      'password': 'Password', 'school': 'School',
      'dashboard': 'Dashboard', 'students': 'Students', 'teachers': 'Teachers',
      'classes': 'Classes', 'subjects': 'Subjects', 'attendance': 'Attendance',
      'exams': 'Exams', 'grades': 'Grades', 'fees': 'Fees',
      'payments': 'Payments', 'certificates': 'Certificates', 'cards': 'Cards',
      'reports': 'Reports', 'settings': 'Settings', 'audit': 'Audit Log',
      'logout': 'Logout', 'save': 'Save', 'cancel': 'Cancel', 'delete': 'Delete',
      'edit': 'Edit', 'add': 'Add', 'search': 'Search', 'name': 'Name',
      'full_name': 'Full Name', 'photo': 'Photo', 'phone': 'Phone',
      'email': 'Email', 'class': 'Class', 'section': 'Section',
      'registration_number': 'Registration No.', 'gender': 'Gender',
      'male': 'Male', 'female': 'Female', 'dob': 'Date of Birth',
      'address': 'Address', 'status': 'Status', 'active': 'Active',
      'print': 'Print', 'pdf': 'PDF', 'share': 'Share', 'preview': 'Preview',
      'present': 'Present', 'absent': 'Absent', 'late': 'Late',
      'excused': 'Excused', 'early': 'Early Leave',
      'total': 'Total', 'average': 'Average', 'percentage': 'Percentage',
      'result': 'Result', 'report_card': 'Report Card',
      'student_card': 'Student Card', 'receipt': 'Receipt',
      'amount': 'Amount', 'date': 'Date', 'notes': 'Notes',
      'welcome': 'Welcome', 'my_profile': 'My Profile', 'my_grades': 'My Grades',
      'my_attendance': 'My Attendance', 'my_certificates': 'My Certificates',
      'my_card': 'My Card', 'announcements': 'Announcements',
      'notifications': 'Notifications', 'courses': 'Courses',
      'academic_year': 'Academic Year', 'term': 'Term',
      'max_score': 'Max Score', 'pass_score': 'Pass Score',
      'score': 'Score', 'exam_title': 'Exam Title',
      'school_name': 'School Name', 'school_logo': 'School Logo',
      'language': 'Language', 'theme': 'Theme', 'dark_mode': 'Dark Mode',
      'light': 'Light', 'dark': 'Dark', 'system': 'System',
      'change_password': 'Change Password', 'new_password': 'New Password',
      'confirm': 'Confirm', 'welcome_back': 'Welcome Back',
      'no_data': 'No Data', 'loading': 'Loading...',
      'recent_activity': 'Recent Activity', 'student_portal': 'Student Portal',
      'teacher_portal': 'Teacher Portal', 'parent_portal': 'Parent Portal',
      'overview': 'Overview', 'total_students': 'Total Students',
      'total_teachers': 'Total Teachers', 'attendance_today': 'Attendance Today',
      'absent_today': 'Absent Today', 'total_fees': 'Total Fees',
      'paid': 'Paid', 'remaining': 'Remaining',
    },
  };

  static String t(BuildContext c, String key) {
    final code = Localizations.localeOf(c).languageCode;
    return _m[code]?[key] ?? _m['ar']![key] ?? key;
  }
}

String tr(BuildContext c, String key) => L.t(c, key);

// ═══════════════════════════════════════════════════════════════════════════
// DATABASE
// ═══════════════════════════════════════════════════════════════════════════
class DB {
  DB._();
  static final DB I = DB._();
  late Database db;
  final _uuid = const Uuid();

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'academic_sms.db');
    db = await openDatabase(
      path,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''CREATE TABLE users(
          id TEXT PRIMARY KEY,
          username TEXT UNIQUE NOT NULL,
          pass_hash TEXT NOT NULL,
          salt TEXT NOT NULL,
          role TEXT NOT NULL,
          linked_id TEXT,
          must_change INTEGER DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL,
          last_login INTEGER
        )''');
        await d.execute('''CREATE TABLE settings(
          key TEXT PRIMARY KEY, value TEXT
        )''');
        await d.execute('''CREATE TABLE academic_years(
          id TEXT PRIMARY KEY, name TEXT, start_date INTEGER, end_date INTEGER, active INTEGER DEFAULT 0
        )''');
        await d.execute('''CREATE TABLE classes(
          id TEXT PRIMARY KEY, name TEXT, level TEXT, "order" INTEGER DEFAULT 0
        )''');
        await d.execute('''CREATE TABLE sections(
          id TEXT PRIMARY KEY, class_id TEXT, name TEXT, academic_year_id TEXT
        )''');
        await d.execute('''CREATE TABLE subjects(
          id TEXT PRIMARY KEY, name TEXT, code TEXT UNIQUE, class_id TEXT, weekly_hours INTEGER DEFAULT 2
        )''');
        await d.execute('''CREATE TABLE students(
          id TEXT PRIMARY KEY,
          reg_no TEXT UNIQUE NOT NULL,
          full_name TEXT NOT NULL,
          name_ar TEXT, name_en TEXT,
          gender TEXT, dob INTEGER, nationality TEXT,
          address TEXT, phone TEXT, email TEXT, photo TEXT,
          parent_name TEXT, parent_phone TEXT,
          class_id TEXT, section_id TEXT, academic_year_id TEXT,
          enroll_date INTEGER, status TEXT DEFAULT 'active', notes TEXT
        )''');
        await d.execute('''CREATE TABLE teachers(
          id TEXT PRIMARY KEY,
          employee_no TEXT UNIQUE NOT NULL,
          full_name TEXT NOT NULL, photo TEXT,
          gender TEXT, phone TEXT, email TEXT,
          qualification TEXT, specialization TEXT,
          employment_date INTEGER, salary REAL
        )''');
        await d.execute('''CREATE TABLE attendance(
          id TEXT PRIMARY KEY,
          person_id TEXT NOT NULL, person_type TEXT NOT NULL,
          status TEXT NOT NULL, date INTEGER NOT NULL,
          note TEXT, recorded_by TEXT, created_at INTEGER NOT NULL
        )''');
        await d.execute('''CREATE TABLE exams(
          id TEXT PRIMARY KEY, title TEXT,
          subject_id TEXT, section_id TEXT, term TEXT,
          max_score REAL, pass_score REAL, date INTEGER
        )''');
        await d.execute('''CREATE TABLE grades(
          id TEXT PRIMARY KEY, exam_id TEXT, student_id TEXT,
          score REAL, component TEXT DEFAULT 'final',
          entered_by TEXT, updated_at INTEGER
        )''');
        await d.execute('''CREATE TABLE fee_items(
          id TEXT PRIMARY KEY, student_id TEXT, type TEXT,
          amount REAL, discount REAL DEFAULT 0, academic_year_id TEXT
        )''');
        await d.execute('''CREATE TABLE payments(
          id TEXT PRIMARY KEY, receipt_no TEXT UNIQUE,
          student_id TEXT, amount REAL, method TEXT,
          note TEXT, paid_at INTEGER, received_by TEXT
        )''');
        await d.execute('''CREATE TABLE certificates(
          id TEXT PRIMARY KEY, serial TEXT UNIQUE, type TEXT,
          recipient_id TEXT, recipient_type TEXT,
          issued_at INTEGER, issued_by TEXT, verify_code TEXT UNIQUE
        )''');
        await d.execute('''CREATE TABLE announcements(
          id TEXT PRIMARY KEY, title TEXT, body TEXT,
          audience TEXT, published_at INTEGER, author_id TEXT
        )''');
        await d.execute('''CREATE TABLE notifications(
          id TEXT PRIMARY KEY, user_id TEXT, title TEXT, body TEXT,
          type TEXT, read INTEGER DEFAULT 0, created_at INTEGER
        )''');
        await d.execute('''CREATE TABLE messages(
          id TEXT PRIMARY KEY, from_user TEXT, to_user TEXT,
          subject TEXT, body TEXT, read INTEGER DEFAULT 0, sent_at INTEGER
        )''');
        await d.execute('''CREATE TABLE audit_logs(
          id TEXT PRIMARY KEY, user_id TEXT, action TEXT,
          target TEXT, target_id TEXT, old_value TEXT, new_value TEXT,
          device TEXT, timestamp INTEGER
        )''');
        // indexes
        await d.execute('CREATE INDEX ix_students_section ON students(section_id)');
        await d.execute('CREATE INDEX ix_att_person ON attendance(person_id, date)');
        await d.execute('CREATE INDEX ix_grades_student ON grades(student_id, exam_id)');
        await d.execute('CREATE INDEX ix_payments_student ON payments(student_id)');
      },
    );
  }

  String newId() => _uuid.v4();

  // ────────── Settings helpers ──────────
  Future<String?> getSetting(String key) async {
    final r = await db.query('settings', where: 'key=?', whereArgs: [key], limit: 1);
    if (r.isEmpty) return null;
    return r.first['value'] as String?;
  }

  Future<void> setSetting(String key, String? value) async {
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, String>> allSettings() async {
    final r = await db.query('settings');
    return {for (var x in r) x['key'] as String: (x['value'] ?? '') as String};
  }

  // ────────── Audit ──────────
  Future<void> audit(String userId, String action, String target,
      {String? targetId, String? oldValue, String? newValue}) async {
    await db.insert('audit_logs', {
      'id': newId(), 'user_id': userId, 'action': action,
      'target': target, 'target_id': targetId,
      'old_value': oldValue, 'new_value': newValue,
      'device': Platform.operatingSystem,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AUTH
// ═══════════════════════════════════════════════════════════════════════════
class Auth {
  static final _uuid = const Uuid();

  static String _salt() {
    final r = Random.secure();
    return base64Encode(List.generate(16, (_) => r.nextInt(256)));
  }

  static String _hash(String password, String salt) {
    var d = sha256.convert(utf8.encode('$salt::$password'));
    for (int i = 0; i < 8000; i++) {
      d = sha256.convert([...d.bytes, ...utf8.encode(salt)]);
    }
    return d.toString();
  }

  static bool verify(String password, String salt, String expected) =>
      _hash(password, salt) == expected;

  static Future<void> seedDefaults() async {
    final c = await DB.I.db.rawQuery('SELECT COUNT(*) AS n FROM users');
    if ((c.first['n'] as int) > 0) return;
    await _create('Admin', 'Admin123', 'admin', mustChange: true);
    await _create('Teacher', 'Teacher123', 'teacher', mustChange: true);
    // default academic year
    final y = DateTime.now().year;
    await DB.I.db.insert('academic_years', {
      'id': _uuid.v4(),
      'name': '$y/${y + 1}',
      'start_date': DateTime(y, 9, 1).millisecondsSinceEpoch,
      'end_date': DateTime(y + 1, 6, 30).millisecondsSinceEpoch,
      'active': 1,
    });
    await DB.I.setSetting('school_name', 'مدرستي الأكاديمية');
    await DB.I.setSetting('school_name_en', 'My Academic School');
    await DB.I.setSetting('language', 'ar');
    await DB.I.setSetting('theme_color', '#1565C0');
    await DB.I.setSetting('theme_mode', 'light');
  }

  static Future<String> _create(String u, String p, String role,
      {bool mustChange = false, String? linkedId}) async {
    final id = _uuid.v4();
    final s = _salt();
    await DB.I.db.insert('users', {
      'id': id, 'username': u, 'pass_hash': _hash(p, s), 'salt': s,
      'role': role, 'linked_id': linkedId,
      'must_change': mustChange ? 1 : 0, 'is_active': 1,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return id;
  }

  static Future<Map<String, dynamic>?> login(String u, String p) async {
    final r = await DB.I.db.query('users',
        where: 'username=? AND is_active=1', whereArgs: [u], limit: 1);
    if (r.isEmpty) return null;
    final row = r.first;
    if (!verify(p, row['salt'] as String, row['pass_hash'] as String)) return null;
    await DB.I.db.update('users',
        {'last_login': DateTime.now().millisecondsSinceEpoch},
        where: 'id=?', whereArgs: [row['id']]);
    await DB.I.audit(row['id'] as String, 'login', 'user', targetId: row['id'] as String);
    return row;
  }

  static Future<void> changePassword(String userId, String newPwd) async {
    final s = _salt();
    await DB.I.db.update('users', {
      'pass_hash': _hash(newPwd, s), 'salt': s, 'must_change': 0,
    }, where: 'id=?', whereArgs: [userId]);
    await DB.I.audit(userId, 'change_password', 'user', targetId: userId);
  }

  static Future<String> createStudentAccount(String studentId, String regNo) async {
    // password = regNo by default
    final id = await _create(regNo, regNo, 'student',
        mustChange: false, linkedId: studentId);
    return id;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SESSION
// ═══════════════════════════════════════════════════════════════════════════
class Session {
  static Map<String, dynamic>? current;
  static bool get isAdmin => current?['role'] == 'admin' ||
      current?['role'] == 'director' ||
      current?['role'] == 'accountant' ||
      current?['role'] == 'secretary' ||
      current?['role'] == 'employee';
  static String get userId => current?['id'] as String? ?? '';
  static String get role => current?['role'] as String? ?? '';
  static String? get linkedId => current?['linked_id'] as String?;
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOT GATE
// ═══════════════════════════════════════════════════════════════════════════
class RootGate extends StatelessWidget {
  const RootGate({super.key});
  @override
  Widget build(BuildContext context) {
    if (Session.current == null) return const LoginScreen();
    if ((Session.current!['must_change'] as int? ?? 0) == 1) {
      return const ChangePasswordScreen(forced: true);
    }
    switch (Session.role) {
      case 'student': return const StudentPortal();
      case 'teacher': return const TeacherPortal();
      case 'parent': return const ParentPortal();
      default: return const AdminShell();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _u = TextEditingController(text: 'Admin');
  final _p = TextEditingController(text: 'Admin123');
  bool _obscure = true, _loading = false;
  String? _err;
  String? _logoPath, _schoolName;

  @override
  void initState() {
    super.initState();
    _loadBranding();
  }

  Future<void> _loadBranding() async {
    final logo = await DB.I.getSetting('school_logo');
    final name = await DB.I.getSetting('school_name');
    if (mounted) setState(() { _logoPath = logo; _schoolName = name; });
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _err = null; });
    final r = await Auth.login(_u.text.trim(), _p.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (r == null) { setState(() => _err = 'بيانات الدخول غير صحيحة'); return; }
    Session.current = Map<String, dynamic>.from(r);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootGate()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_logoPath != null && File(_logoPath!).existsSync())
                  Image.file(File(_logoPath!), height: 96)
                else
                  Icon(Icons.school, size: 96,
                      color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(_schoolName ?? 'مدرستي الأكاديمية',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(tr(context, 'app_title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                TextField(
                  controller: _u,
                  decoration: InputDecoration(
                    labelText: tr(context, 'username'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _p,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: tr(context, 'password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_err != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_err!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(tr(context, 'login')),
                ),
                const SizedBox(height: 20),
                Text('Admin / Admin123  •  Teacher / Teacher123',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CHANGE PASSWORD
// ═══════════════════════════════════════════════════════════════════════════
class ChangePasswordScreen extends StatefulWidget {
  final bool forced;
  const ChangePasswordScreen({super.key, this.forced = false});
  @override
  State<ChangePasswordScreen> createState() => _ChangePwdState();
}

class _ChangePwdState extends State<ChangePasswordScreen> {
  final _p = TextEditingController();
  final _c = TextEditingController();
  String? _err;

  Future<void> _save() async {
    if (_p.text.length < 6) { setState(() => _err = 'كلمة المرور قصيرة جدًا'); return; }
    if (_p.text != _c.text) { setState(() => _err = 'كلمتا المرور غير متطابقتين'); return; }
    await Auth.changePassword(Session.userId, _p.text);
    Session.current!['must_change'] = 0;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootGate()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'change_password')),
        automaticallyImplyLeading: !widget.forced,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (widget.forced)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                        '⚠️ أنت تستخدم كلمة مرور افتراضية. يجب تغييرها للمتابعة.'),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _p, obscureText: true,
                decoration: InputDecoration(labelText: tr(context, 'new_password')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _c, obscureText: true,
                decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
              ),
              if (_err != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_err!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _save, child: Text(tr(context, 'save'))),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN SHELL
// ═══════════════════════════════════════════════════════════════════════════
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;
  String? _logoPath, _schoolName;

  final _tabs = const [
    _NavItem('dashboard', Icons.dashboard_outlined),
    _NavItem('students', Icons.people_outline),
    _NavItem('attendance', Icons.check_circle_outline),
    _NavItem('fees', Icons.attach_money),
    _NavItem('settings', Icons.settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l = await DB.I.getSetting('school_logo');
    final n = await DB.I.getSetting('school_name');
    if (mounted) setState(() { _logoPath = l; _schoolName = n; });
  }

  void _onDrawer(String key) {
    Navigator.of(context).pop();
    switch (key) {
      case 'dashboard': setState(() => _tab = 0); break;
      case 'students': setState(() => _tab = 1); break;
      case 'teachers': _push(const TeachersScreen()); break;
      case 'classes': _push(const ClassesScreen()); break;
      case 'subjects': _push(const SubjectsScreen()); break;
      case 'attendance': setState(() => _tab = 2); break;
      case 'exams': _push(const ExamsScreen()); break;
      case 'grades': _push(const GradesScreen()); break;
      case 'fees': setState(() => _tab = 3); break;
      case 'payments': _push(const PaymentsScreen()); break;
      case 'certificates': _push(const CertificatesScreen()); break;
      case 'cards': _push(const CardsScreen()); break;
      case 'reports': _push(const ReportsScreen()); break;
      case 'audit': _push(const AuditScreen()); break;
      case 'settings': setState(() => _tab = 4); break;
      case 'logout':
        Session.current = null;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
        break;
    }
  }

  void _push(Widget w) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardScreen(),
      const StudentsScreen(),
      const AttendanceScreen(),
      const FeesScreen(),
      SettingsScreen(onBrandingChanged: _load),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(children: [
          if (_logoPath != null && File(_logoPath!).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(File(_logoPath!), height: 32, width: 32, fit: BoxFit.cover),
            )
          else
            const Icon(Icons.school, size: 28),
          const SizedBox(width: 10),
          Expanded(child: Text(_schoolName ?? tr(context, 'app_title'),
              overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16))),
        ]),
      ),
      drawer: _buildDrawer(context),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          for (var t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              label: tr(context, t.key),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            accountName: Text(_schoolName ?? ''),
            accountEmail: Text('${Session.role.toUpperCase()} • ${Session.userId.substring(0, 6)}'),
            currentAccountPicture: _logoPath != null && File(_logoPath!).existsSync()
                ? CircleAvatar(backgroundImage: FileImage(File(_logoPath!)))
                : const CircleAvatar(child: Icon(Icons.school)),
          ),
          _sectionHeader(context, 'ACADEMIC'),
          _tile(Icons.dashboard_outlined, 'dashboard', 'dashboard'),
          _tile(Icons.people_outline, 'students', 'students'),
          _tile(Icons.person_outline, 'teachers', 'teachers'),
          _tile(Icons.class_outlined, 'classes', 'classes'),
          _tile(Icons.menu_book_outlined, 'subjects', 'subjects'),
          _tile(Icons.check_circle_outline, 'attendance', 'attendance'),
          _tile(Icons.assignment_outlined, 'exams', 'exams'),
          _tile(Icons.grade_outlined, 'grades', 'grades'),
          _sectionHeader(context, 'FINANCE'),
          _tile(Icons.attach_money, 'fees', 'fees'),
          _tile(Icons.receipt_long_outlined, 'payments', 'payments'),
          _sectionHeader(context, 'DOCUMENTS'),
          _tile(Icons.workspace_premium_outlined, 'certificates', 'certificates'),
          _tile(Icons.badge_outlined, 'cards', 'cards'),
          _sectionHeader(context, 'ADMINISTRATION'),
          _tile(Icons.bar_chart, 'reports', 'reports'),
          _tile(Icons.history, 'audit', 'audit'),
          _tile(Icons.settings_outlined, 'settings', 'settings'),
          const Divider(),
          _tile(Icons.logout, 'logout', 'logout'),
        ]),
      ),
    );
  }

  Widget _sectionHeader(BuildContext c, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
    child: Text(text,
        style: TextStyle(
            fontSize: 11, letterSpacing: 1.4,
            fontWeight: FontWeight.bold,
            color: Theme.of(c).colorScheme.primary)),
  );

  Widget _tile(IconData i, String key, String action) => ListTile(
    leading: Icon(i), title: Text(tr(context, key)),
    onTap: () => _onDrawer(action),
  );
}

class _NavItem {
  final String key;
  final IconData icon;
  const _NavItem(this.key, this.icon);
}

// ═══════════════════════════════════════════════════════════════════════════
// DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashState();
}

class _DashState extends State<DashboardScreen> {
  Map<String, int> _stats = {};
  double _totalFees = 0, _paid = 0;
  List<Map<String, dynamic>> _recent = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db = DB.I.db;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
    final endOfDay = startOfDay + 86400000;

    Future<int> cnt(String sql) async =>
        (Sqflite.firstIntValue(await db.rawQuery(sql)) ?? 0);

    final s = <String, int>{};
    s['students'] = await cnt('SELECT COUNT(*) FROM students WHERE status="active"');
    s['teachers'] = await cnt('SELECT COUNT(*) FROM teachers');
    s['classes'] = await cnt('SELECT COUNT(*) FROM classes');
    s['subjects'] = await cnt('SELECT COUNT(*) FROM subjects');
    s['present'] = await cnt(
        'SELECT COUNT(*) FROM attendance WHERE date>=$startOfDay AND date<$endOfDay AND status="present"');
    s['absent'] = await cnt(
        'SELECT COUNT(*) FROM attendance WHERE date>=$startOfDay AND date<$endOfDay AND status="absent"');
    final fees = await db.rawQuery('SELECT COALESCE(SUM(amount-discount),0) t FROM fee_items');
    final pays = await db.rawQuery('SELECT COALESCE(SUM(amount),0) t FROM payments');
    final recent = await db.query('audit_logs',
        orderBy: 'timestamp DESC', limit: 8);

    if (!mounted) return;
    setState(() {
      _stats = s;
      _totalFees = (fees.first['t'] as num).toDouble();
      _paid = (pays.first['t'] as num).toDouble();
      _recent = recent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(tr(context, 'overview'),
              style: Theme.of(context).textTheme.titleLarge),
        ),
        _grid(context),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(tr(context, 'recent_activity'),
              style: Theme.of(context).textTheme.titleMedium),
        ),
        if (_recent.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(child: Text(tr(context, 'no_data'))),
          )
        else
          ..._recent.map((r) => ListTile(
            dense: true,
            leading: const Icon(Icons.history, size: 20),
            title: Text('${r['action']} → ${r['target']}'),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(
                DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int))),
          )),
      ]),
    );
  }

  Widget _grid(BuildContext context) {
    final items = [
      _StatCard(tr(context, 'total_students'), '${_stats['students'] ?? 0}', Icons.people_outline),
      _StatCard(tr(context, 'total_teachers'), '${_stats['teachers'] ?? 0}', Icons.person_outline),
      _StatCard(tr(context, 'classes'), '${_stats['classes'] ?? 0}', Icons.class_outlined),
      _StatCard(tr(context, 'subjects'), '${_stats['subjects'] ?? 0}', Icons.menu_book_outlined),
      _StatCard(tr(context, 'attendance_today'), '${_stats['present'] ?? 0}', Icons.check_circle_outline),
      _StatCard(tr(context, 'absent_today'), '${_stats['absent'] ?? 0}', Icons.cancel_outlined),
      _StatCard(tr(context, 'total_fees'),
          _totalFees.toStringAsFixed(0), Icons.attach_money),
      _StatCard(tr(context, 'remaining'),
          (_totalFees - _paid).toStringAsFixed(0), Icons.trending_down),
    ];
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.7,
        children: items,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: s.primary),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: s.primary)),
              Text(label, style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STUDENTS
// ═══════════════════════════════════════════════════════════════════════════
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override
  State<StudentsScreen> createState() => _StudentsState();
}

class _StudentsState extends State<StudentsScreen> {
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _sections = [];
  String _query = '';
  String? _filterClass;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db = DB.I.db;
    final classes = await db.query('classes', orderBy: '"order"');
    final sections = await db.query('sections');
    final where = <String>[];
    final args = <Object>[];
    if (_query.isNotEmpty) {
      where.add('(full_name LIKE ? OR reg_no LIKE ?)');
      args..add('%$_query%')..add('%$_query%');
    }
    if (_filterClass != null) { where.add('class_id=?'); args.add(_filterClass!); }
    final rows = await db.query('students',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'full_name');
    if (!mounted) return;
    setState(() { _rows = rows; _classes = classes; _sections = sections; });
  }

  String _className(String? id) {
    if (id == null) return '-';
    final c = _classes.firstWhere((e) => e['id'] == id, orElse: () => {});
    return c['name']?.toString() ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'students')),
        actions: [
          IconButton(icon: const Icon(Icons.add),
              onPressed: () => _openForm(null)),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: InputDecoration(
              hintText: tr(context, 'search'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (v) { _query = v; _load(); },
          ),
        ),
        if (_classes.isNotEmpty)
          SizedBox(height: 44, child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              ChoiceChip(
                label: Text(tr(context, 'classes')),
                selected: _filterClass == null,
                onSelected: (_) { _filterClass = null; _load(); },
              ),
              const SizedBox(width: 6),
              for (var c in _classes) Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(c['name'] as String),
                  selected: _filterClass == c['id'],
                  onSelected: (_) { _filterClass = c['id'] as String; _load(); },
                ),
              ),
            ],
          )),
        Expanded(
          child: _rows.isEmpty
              ? Center(child: Text(tr(context, 'no_data')))
              : ListView.builder(
                  itemCount: _rows.length,
                  itemBuilder: (c, i) {
                    final r = _rows[i];
                    final photo = r['photo'] as String?;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            (photo != null && File(photo).existsSync())
                                ? FileImage(File(photo)) : null,
                        child: (photo == null || !File(photo).existsSync())
                            ? const Icon(Icons.person) : null,
                      ),
                      title: Text(r['full_name'] as String),
                      subtitle: Text(
                          '${r['reg_no']} • ${_className(r['class_id'] as String?)}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') _openForm(r);
                          else if (v == 'card') _openCard(r);
                          else if (v == 'report') _openReport(r);
                          else if (v == 'delete') _delete(r);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('تعديل')),
                          PopupMenuItem(value: 'card', child: Text('بطاقة')),
                          PopupMenuItem(value: 'report', child: Text('كشف درجات')),
                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                      ),
                      onTap: () => _openForm(r),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  void _openForm(Map<String, dynamic>? row) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StudentFormScreen(student: row),
    )).then((_) => _load());
  }

  void _openCard(Map<String, dynamic> r) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StudentCardScreen(student: r),
    ));
  }

  void _openReport(Map<String, dynamic> r) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReportCardScreen(student: r),
    ));
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('حذف الطالب ${r['full_name']}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    await DB.I.db.delete('students', where: 'id=?', whereArgs: [r['id']]);
    await DB.I.db.delete('users', where: 'linked_id=?', whereArgs: [r['id']]);
    await DB.I.audit(Session.userId, 'delete', 'student', targetId: r['id'] as String);
    _load();
  }
}

class StudentFormScreen extends StatefulWidget {
  final Map<String, dynamic>? student;
  const StudentFormScreen({super.key, this.student});
  @override
  State<StudentFormScreen> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentFormScreen> {
  final _name = TextEditingController();
  final _reg = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _parentName = TextEditingController();
  final _parentPhone = TextEditingController();
  String _gender = 'male';
  DateTime? _dob;
  String? _photo;
  String? _classId;
  String? _sectionId;
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _years = [];

  @override
  void initState() {
    super.initState();
    _loadRefs();
    final s = widget.student;
    if (s != null) {
      _name.text = s['full_name'] as String;
      _reg.text = s['reg_no'] as String;
      _phone.text = (s['phone'] as String?) ?? '';
      _email.text = (s['email'] as String?) ?? '';
      _address.text = (s['address'] as String?) ?? '';
      _parentName.text = (s['parent_name'] as String?) ?? '';
      _parentPhone.text = (s['parent_phone'] as String?) ?? '';
      _gender = (s['gender'] as String?) ?? 'male';
      _photo = s['photo'] as String?;
      _classId = s['class_id'] as String?;
      _sectionId = s['section_id'] as String?;
      final d = s['dob'] as int?;
      if (d != null) _dob = DateTime.fromMillisecondsSinceEpoch(d);
    } else {
      _reg.text = 'S${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  Future<void> _loadRefs() async {
    final db = DB.I.db;
    final classes = await db.query('classes', orderBy: '"order"');
    final sections = await db.query('sections');
    final years = await db.query('academic_years', orderBy: 'start_date DESC');
    if (!mounted) return;
    setState(() {
      _classes = classes; _sections = sections; _years = years;
      _classId ??= classes.isNotEmpty ? classes.first['id'] as String : null;
      _sectionId ??= sections.isNotEmpty ? sections.first['id'] as String : null;
    });
  }

  Future<void> _pickPhoto(ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src, imageQuality: 70, maxWidth: 600);
    if (x == null) return;
    setState(() => _photo = x.path);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _snack('الاسم مطلوب'); return;
    }
    if (_reg.text.trim().isEmpty) {
      _snack('رقم التسجيل مطلوب'); return;
    }
    final db = DB.I.db;
    final isNew = widget.student == null;
    final data = {
      'reg_no': _reg.text.trim(),
      'full_name': _name.text.trim(),
      'gender': _gender,
      'dob': _dob?.millisecondsSinceEpoch,
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'address': _address.text.trim(),
      'photo': _photo,
      'parent_name': _parentName.text.trim(),
      'parent_phone': _parentPhone.text.trim(),
      'class_id': _classId,
      'section_id': _sectionId,
      'academic_year_id': _years.isNotEmpty ? _years.first['id'] : null,
      'enroll_date': DateTime.now().millisecondsSinceEpoch,
      'status': 'active',
    };
    try {
      if (isNew) {
        final id = DB.I.newId();
        await db.insert('students', {'id': id, ...data});
        await Auth.createStudentAccount(id, _reg.text.trim());
        await DB.I.audit(Session.userId, 'create', 'student',
            targetId: id, newValue: _name.text);
      } else {
        final id = widget.student!['id'] as String;
        await db.update('students', data, where: 'id=?', whereArgs: [id]);
        await DB.I.audit(Session.userId, 'update', 'student',
            targetId: id, newValue: _name.text);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _snack('خطأ: رقم التسجيل مستخدم مسبقًا');
    }
  }

  void _snack(String s) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    final sectionsForClass = _sections
        .where((s) => s['class_id'] == _classId).toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.student == null
          ? 'إضافة طالب' : 'تعديل طالب')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Column(children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: (_photo != null && File(_photo!).existsSync())
                ? FileImage(File(_photo!)) : null,
            child: (_photo == null || !File(_photo!).existsSync())
                ? const Icon(Icons.person, size: 48) : null,
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton.icon(
              onPressed: () => _pickPhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library), label: const Text('معرض')),
            TextButton.icon(
              onPressed: () => _pickPhoto(ImageSource.camera),
              icon: const Icon(Icons.camera_alt), label: const Text('كاميرا')),
            if (_photo != null)
              IconButton(
                onPressed: () => setState(() => _photo = null),
                icon: const Icon(Icons.delete_outline)),
          ]),
        ])),
        const SizedBox(height: 12),
        _f('الاسم الكامل', _name),
        _f('رقم التسجيل', _reg),
        _f('الهاتف', _phone, keyboard: TextInputType.phone),
        _f('البريد', _email, keyboard: TextInputType.emailAddress),
        _f('العنوان', _address),
        _f('اسم ولي الأمر', _parentName),
        _f('هاتف ولي الأمر', _parentPhone, keyboard: TextInputType.phone),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _gender,
          decoration: const InputDecoration(labelText: 'الجنس'),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('ذكر')),
            DropdownMenuItem(value: 'female', child: Text('أنثى')),
          ],
          onChanged: (v) => setState(() => _gender = v!),
        ),
        const SizedBox(height: 12),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          title: const Text('تاريخ الميلاد'),
          subtitle: Text(_dob == null ? '-' : DateFormat('yyyy-MM-dd').format(_dob!)),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final d = await showDatePicker(
              context: context, firstDate: DateTime(1990), lastDate: DateTime.now(),
              initialDate: _dob ?? DateTime(2015));
            if (d != null) setState(() => _dob = d);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _classId,
          decoration: const InputDecoration(labelText: 'الصف'),
          items: _classes.map((c) => DropdownMenuItem(
              value: c['id'] as String, child: Text(c['name'] as String))).toList(),
          onChanged: (v) => setState(() {
            _classId = v; _sectionId = null;
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: sectionsForClass.any((s) => s['id'] == _sectionId) ? _sectionId : null,
          decoration: const InputDecoration(labelText: 'الشعبة'),
          items: sectionsForClass.map((s) => DropdownMenuItem(
              value: s['id'] as String, child: Text(s['name'] as String))).toList(),
          onChanged: (v) => setState(() => _sectionId = v),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: Text(tr(context, 'save')),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr(context, 'cancel')),
        ),
      ]),
    );
  }

  Widget _f(String label, TextEditingController c,
      {TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c, keyboardType: keyboard,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// TEACHERS
// ═══════════════════════════════════════════════════════════════════════════
class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});
  @override
  State<TeachersScreen> createState() => _TeachersState();
}

class _TeachersState extends State<TeachersScreen> {
  List<Map<String, dynamic>> _rows = [];
  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final r = await DB.I.db.query('teachers', orderBy: 'full_name');
    if (mounted) setState(() => _rows = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'teachers')),
        actions: [IconButton(icon: const Icon(Icons.add),
            onPressed: () => _open(null))],
      ),
      body: _rows.isEmpty
          ? Center(child: Text(tr(context, 'no_data')))
          : ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (c, i) {
                final r = _rows[i];
                final photo = r['photo'] as String?;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (photo != null && File(photo).existsSync())
                        ? FileImage(File(photo)) : null,
                    child: (photo == null || !File(photo).existsSync())
                        ? const Icon(Icons.person) : null,
                  ),
                  title: Text(r['full_name'] as String),
                  subtitle: Text('${r['employee_no']} • ${r['specialization'] ?? ''}'),
                  onTap: () => _open(r),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await DB.I.db.delete('teachers', where: 'id=?', whereArgs: [r['id']]);
                      _load();
                    },
                  ),
                );
              },
            ),
    );
  }

  void _open(Map<String, dynamic>? r) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TeacherFormScreen(teacher: r),
    )).then((_) => _load());
  }
}

class TeacherFormScreen extends StatefulWidget {
  final Map<String, dynamic>? teacher;
  const TeacherFormScreen({super.key, this.teacher});
  @override
  State<TeacherFormScreen> createState() => _TeacherFormState();
}

class _TeacherFormState extends State<TeacherFormScreen> {
  final _name = TextEditingController();
  final _no = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _spec = TextEditingController();
  final _qual = TextEditingController();
  String? _photo;

  @override
  void initState() {
    super.initState();
    final t = widget.teacher;
    if (t != null) {
      _name.text = t['full_name'] as String;
      _no.text = t['employee_no'] as String;
      _phone.text = (t['phone'] as String?) ?? '';
      _email.text = (t['email'] as String?) ?? '';
      _spec.text = (t['specialization'] as String?) ?? '';
      _qual.text = (t['qualification'] as String?) ?? '';
      _photo = t['photo'] as String?;
    } else {
      _no.text = 'T${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  Future<void> _pick(ImageSource s) async {
    final x = await ImagePicker().pickImage(source: s, imageQuality: 70, maxWidth: 600);
    if (x != null) setState(() => _photo = x.path);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _no.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الاسم والرقم الوظيفي مطلوبان')));
      return;
    }
    final data = {
      'employee_no': _no.text.trim(),
      'full_name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'specialization': _spec.text.trim(),
      'qualification': _qual.text.trim(),
      'photo': _photo,
    };
    try {
      if (widget.teacher == null) {
        final id = DB.I.newId();
        await DB.I.db.insert('teachers', {'id': id, ...data});
        await DB.I.audit(Session.userId, 'create', 'teacher', targetId: id);
      } else {
        await DB.I.db.update('teachers', data,
            where: 'id=?', whereArgs: [widget.teacher!['id']]);
        await DB.I.audit(Session.userId, 'update', 'teacher',
            targetId: widget.teacher!['id'] as String);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رقم وظيفي مستخدم مسبقًا')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.teacher == null
          ? 'إضافة معلم' : 'تعديل معلم')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Column(children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: (_photo != null && File(_photo!).existsSync())
                ? FileImage(File(_photo!)) : null,
            child: (_photo == null || !File(_photo!).existsSync())
                ? const Icon(Icons.person, size: 48) : null,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton.icon(onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library), label: const Text('معرض')),
            TextButton.icon(onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt), label: const Text('كاميرا')),
          ]),
        ])),
        const SizedBox(height: 12),
        _f('الاسم', _name), _f('الرقم الوظيفي', _no),
        _f('الهاتف', _phone), _f('البريد', _email),
        _f('التخصص', _spec), _f('المؤهل', _qual),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: _save,
            icon: const Icon(Icons.save), label: Text(tr(context, 'save'))),
      ]),
    );
  }

  Widget _f(String l, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(controller: c, decoration: InputDecoration(labelText: l)),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CLASSES
// ═══════════════════════════════════════════════════════════════════════════
class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});
  @override
  State<ClassesScreen> createState() => _ClassesState();
}

class _ClassesState extends State<ClassesScreen> {
  List<Map<String, dynamic>> _rows = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final r = await DB.I.db.query('classes', orderBy: '"order"');
    if (mounted) setState(() => _rows = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'classes')),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addClass),
          IconButton(icon: const Icon(Icons.grid_view), onPressed: _addSection),
        ],
      ),
      body: _rows.isEmpty
          ? Center(child: Text(tr(context, 'no_data')))
          : ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (c, i) {
                final r = _rows[i];
                return ListTile(
                  leading: const Icon(Icons.class_outlined),
                  title: Text(r['name'] as String),
                  subtitle: Text((r['level'] as String?) ?? ''),
                  onTap: () => _showSections(r),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await DB.I.db.delete('classes', where: 'id=?', whereArgs: [r['id']]);
                      await DB.I.db.delete('sections', where: 'class_id=?', whereArgs: [r['id']]);
                      _load();
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _addClass() async {
    final name = TextEditingController();
    final level = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة صف'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
          const SizedBox(height: 8),
          TextField(controller: level, decoration: const InputDecoration(labelText: 'المرحلة')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok != true) return;
    await DB.I.db.insert('classes', {
      'id': DB.I.newId(), 'name': name.text.trim(),
      'level': level.text.trim(), 'order': DateTime.now().millisecondsSinceEpoch,
    });
    _load();
  }

  Future<void> _addSection() async {
    if (_rows.isEmpty) return;
    final name = TextEditingController();
    final cls = _rows.first['id'] as String;
    final years = await DB.I.db.query('academic_years');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة شعبة'),
        content: TextField(controller: name,
            decoration: const InputDecoration(labelText: 'اسم الشعبة (A/B)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok != true) return;
    await DB.I.db.insert('sections', {
      'id': DB.I.newId(), 'class_id': cls,
      'name': name.text.trim(),
      'academic_year_id': years.isNotEmpty ? years.first['id'] : null,
    });
    _load();
  }

  Future<void> _showSections(Map<String, dynamic> cls) async {
    final secs = await DB.I.db.query('sections',
        where: 'class_id=?', whereArgs: [cls['id']]);
    if (!mounted) return;
    showModalBottomSheet(context: context, builder: (_) => ListView(
      children: [
        ListTile(title: Text('شعب ${cls['name']}', style: const TextStyle(fontWeight: FontWeight.bold))),
        if (secs.isEmpty) const ListTile(title: Text('لا توجد شعب')),
        for (var s in secs) ListTile(
          leading: const Icon(Icons.group_outlined),
          title: Text(s['name'] as String),
          trailing: IconButton(icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await DB.I.db.delete('sections', where: 'id=?', whereArgs: [s['id']]);
                Navigator.pop(context);
              }),
        ),
      ],
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUBJECTS
// ═══════════════════════════════════════════════════════════════════════════
class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});
  @override
  State<SubjectsScreen> createState() => _SubjectsState();
}

class _SubjectsState extends State<SubjectsScreen> {
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _classes = [];
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final r = await DB.I.db.query('subjects', orderBy: 'name');
    final c = await DB.I.db.query('classes');
    if (mounted) setState(() { _rows = r; _classes = c; });
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final code = TextEditingController();
    final hours = TextEditingController(text: '2');
    String? cls = _classes.isNotEmpty ? _classes.first['id'] as String : null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (c, setS) => AlertDialog(
        title: const Text('إضافة مادة'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم المادة')),
          const SizedBox(height: 8),
          TextField(controller: code, decoration: const InputDecoration(labelText: 'الرمز')),
          const SizedBox(height: 8),
          TextField(controller: hours, decoration: const InputDecoration(labelText: 'الساعات الأسبوعية'),
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          if (_classes.isNotEmpty)
            DropdownButtonFormField<String>(
              value: cls,
              decoration: const InputDecoration(labelText: 'الصف'),
              items: _classes.map((c) => DropdownMenuItem(
                  value: c['id'] as String, child: Text(c['name'] as String))).toList(),
              onChanged: (v) => setS(() => cls = v),
            ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      )),
    );
    if (ok != true) return;
    try {
      await DB.I.db.insert('subjects', {
        'id': DB.I.newId(), 'name': name.text.trim(),
        'code': code.text.trim(), 'class_id': cls,
        'weekly_hours': int.tryParse(hours.text) ?? 2,
      });
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرمز مستخدم مسبقًا')));
    }
  }

  String _cls(String? id) =>
      _classes.firstWhere((e) => e['id'] == id, orElse: () => {})['name'] as String? ?? '-';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'subjects')),
          actions: [IconButton(icon: const Icon(Icons.add), onPressed: _add)]),
      body: _rows.isEmpty
          ? Center(child: Text(tr(context, 'no_data')))
          : ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (c, i) {
                final r = _rows[i];
                return ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(r['name'] as String),
                  subtitle: Text('${r['code']} • ${_cls(r['class_id'] as String?)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await DB.I.db.delete('subjects', where: 'id=?', whereArgs: [r['id']]);
                      _load();
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ATTENDANCE
// ═══════════════════════════════════════════════════════════════════════════
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttState();
}

class _AttState extends State<AttendanceScreen> {
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>> _classes = [];
  String? _classId;
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _marks = {}; // studentId -> status

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final cls = await DB.I.db.query('classes', orderBy: '"order"');
    setState(() {
      _classes = cls;
      _classId = cls.isNotEmpty ? cls.first['id'] as String : null;
    });
    _load();
  }

  Future<void> _load() async {
    if (_classId == null) return;
    final db = DB.I.db;
    final startOfDay = DateTime(_date.year, _date.month, _date.day).millisecondsSinceEpoch;
    final endOfDay = startOfDay + 86400000;
    final students = await db.query('students',
        where: 'class_id=? AND status="active"', whereArgs: [_classId],
        orderBy: 'full_name');
    final att = await db.query('attendance',
        where: 'date>=? AND date<? AND person_type="student"',
        whereArgs: [startOfDay, endOfDay]);
    final marks = <String, String>{};
    for (var a in att) marks[a['person_id'] as String] = a['status'] as String;
    if (!mounted) return;
    setState(() { _students = students; _marks = marks; });
  }

  Future<void> _saveAll() async {
    if (_classId == null) return;
    final db = DB.I.db;
    final startOfDay = DateTime(_date.year, _date.month, _date.day).millisecondsSinceEpoch;
    final endOfDay = startOfDay + 86400000;
    await db.delete('attendance',
        where: 'date>=? AND date<? AND person_type="student" AND person_id IN '
            '(SELECT id FROM students WHERE class_id=?)',
        whereArgs: [startOfDay, endOfDay, _classId]);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var s in _students) {
      final status = _marks[s['id'] as String] ?? 'present';
      await db.insert('attendance', {
        'id': DB.I.newId(),
        'person_id': s['id'],
        'person_type': 'student',
        'status': status,
        'date': startOfDay + 3600000, // noon-ish
        'recorded_by': Session.userId,
        'created_at': now,
      });
    }
    await DB.I.audit(Session.userId, 'attendance_bulk', 'class',
        targetId: _classId, newValue: '${_students.length} records');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الحضور')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'attendance'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _classId,
                decoration: const InputDecoration(labelText: 'الصف', isDense: true),
                items: _classes.map((c) => DropdownMenuItem(
                    value: c['id'] as String, child: Text(c['name'] as String))).toList(),
                onChanged: (v) { setState(() => _classId = v); _load(); },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.calendar_today), onPressed: () async {
              final d = await showDatePicker(
                context: context, firstDate: DateTime(2020),
                lastDate: DateTime.now(), initialDate: _date);
              if (d != null) { setState(() => _date = d); _load(); }
            }),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(alignment: Alignment.centerLeft,
            child: Text(DateFormat('yyyy-MM-dd').format(_date))),
        ),
        Expanded(
          child: _students.isEmpty
              ? Center(child: Text(tr(context, 'no_data')))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (c, i) {
                    final s = _students[i];
                    final st = _marks[s['id'] as String] ?? 'present';
                    return ListTile(
                      title: Text(s['full_name'] as String),
                      subtitle: Text(s['reg_no'] as String),
                      trailing: DropdownButton<String>(
                        value: st, underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'present', child: Text('حاضر')),
                          DropdownMenuItem(value: 'absent', child: Text('غائب')),
                          DropdownMenuItem(value: 'late', child: Text('متأخر')),
                          DropdownMenuItem(value: 'excused', child: Text('بعذر')),
                        ],
                        onChanged: (v) => setState(() => _marks[s['id'] as String] = v!),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  for (var s in _students) _marks[s['id'] as String] = 'present';
                });
              },
              icon: const Icon(Icons.done_all), label: const Text('الكل حاضر'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.icon(
              onPressed: _saveAll,
              icon: const Icon(Icons.save), label: Text(tr(context, 'save')))),
          ]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXAMS
// ═══════════════════════════════════════════════════════════════════════════
class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});
  @override
  State<ExamsScreen> createState() => _ExamsState();
}

class _ExamsState extends State<ExamsScreen> {
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _sections = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final r = await DB.I.db.query('exams', orderBy: 'date DESC');
    final s = await DB.I.db.query('subjects');
    final sec = await DB.I.db.query('sections');
    if (mounted) setState(() { _rows = r; _subjects = s; _sections = sec; });
  }

  Future<void> _add() async {
    final title = TextEditingController(text: 'امتحان الفصل');
    final maxS = TextEditingController(text: '100');
    final passS = TextEditingController(text: '50');
    final term = TextEditingController(text: 'T1');
    String? sub = _subjects.isNotEmpty ? _subjects.first['id'] as String : null;
    String? sec = _sections.isNotEmpty ? _sections.first['id'] as String : null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (c, setS) => AlertDialog(
        title: const Text('إضافة امتحان'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'العنوان')),
          const SizedBox(height: 8),
          TextField(controller: term, decoration: const InputDecoration(labelText: 'الفصل الدراسي')),
          const SizedBox(height: 8),
          TextField(controller: maxS, decoration: const InputDecoration(labelText: 'الدرجة القصوى'),
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: passS, decoration: const InputDecoration(labelText: 'درجة النجاح'),
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: sub,
            decoration: const InputDecoration(labelText: 'المادة'),
            items: _subjects.map((s) => DropdownMenuItem(
                value: s['id'] as String, child: Text(s['name'] as String))).toList(),
            onChanged: (v) => setS(() => sub = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: sec,
            decoration: const InputDecoration(labelText: 'الشعبة'),
            items: _sections.map((s) => DropdownMenuItem(
                value: s['id'] as String, child: Text(s['name'] as String))).toList(),
            onChanged: (v) => setS(() => sec = v),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      )),
    );
    if (ok != true) return;
    await DB.I.db.insert('exams', {
      'id': DB.I.newId(), 'title': title.text.trim(),
      'subject_id': sub, 'section_id': sec, 'term': term.text.trim(),
      'max_score': double.tryParse(maxS.text) ?? 100,
      'pass_score': double.tryParse(passS.text) ?? 50,
      'date': DateTime.now().millisecondsSinceEpoch,
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'exams')),
          actions: [IconButton(icon: const Icon(Icons.add), onPressed: _add)]),
      body: _rows.isEmpty
          ? Center(child: Text(tr(context, 'no_data')))
          : ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (c, i) {
                final r = _rows[i];
                return ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: Text(r['title'] as String),
                  subtitle: Text('${r['term']} • ${r['max_score']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_note),
                    tooltip: 'إدخال الدرجات',
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => GradesEntryScreen(exam: r))),
                  ),
                );
              },
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRADES
// ═══════════════════════════════════════════════════════════════════════════
class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'grades'))),
      body: FutureBuilder(
        future: DB.I.db.query('exams', orderBy: 'date DESC'),
        builder: (c, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snap.data!;
          if (rows.isEmpty) return Center(child: Text(tr(context, 'no_data')));
          return ListView.builder(itemCount: rows.length, itemBuilder: (_, i) {
            final r = rows[i];
            return ListTile(
              leading: const Icon(Icons.grade_outlined),
              title: Text(r['title'] as String),
              subtitle: Text(r['term'] as String),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => GradesEntryScreen(exam: r))),
            );
          });
        },
      ),
    );
  }
}

class GradesEntryScreen extends StatefulWidget {
  final Map<String, dynamic> exam;
  const GradesEntryScreen({super.key, required this.exam});
  @override
  State<GradesEntryScreen> createState() => _GradesEntryState();
}

class _GradesEntryState extends State<GradesEntryScreen> {
  List<Map<String, dynamic>> _students = [];
  Map<String, double?> _scores = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db = DB.I.db;
    final secId = widget.exam['section_id'] as String?;
    final rows = await db.query('students',
        where: secId != null ? 'section_id=? AND status="active"' : 'status="active"',
        whereArgs: secId != null ? [secId] : null,
        orderBy: 'full_name');
    final grades = await db.query('grades',
        where: 'exam_id=?', whereArgs: [widget.exam['id']]);
    final sc = <String, double?>{};
    for (var g in grades) sc[g['student_id'] as String] = (g['score'] as num).toDouble();
    if (mounted) setState(() { _students = rows; _scores = sc; });
  }

  Future<void> _save() async {
    final db = DB.I.db;
    for (var s in _students) {
      final score = _scores[s['id'] as String];
      if (score == null) continue;
      final existing = await db.query('grades',
          where: 'exam_id=? AND student_id=?',
          whereArgs: [widget.exam['id'], s['id']]);
      if (existing.isEmpty) {
        await db.insert('grades', {
          'id': DB.I.newId(), 'exam_id': widget.exam['id'],
          'student_id': s['id'], 'score': score,
          'component': 'final', 'entered_by': Session.userId,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        await db.update('grades', {
          'score': score, 'entered_by': Session.userId,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        }, where: 'id=?', whereArgs: [existing.first['id']]);
      }
    }
    await DB.I.audit(Session.userId, 'grades_bulk', 'exam',
        targetId: widget.exam['id'] as String);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الدرجات')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exam['title'] as String)),
      body: Column(children: [
        Expanded(
          child: _students.isEmpty
              ? Center(child: Text(tr(context, 'no_data')))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (c, i) {
                    final s = _students[i];
                    final ctrl = TextEditingController(
                        text: _scores[s['id']]?.toStringAsFixed(0) ?? '');
                    return ListTile(
                      title: Text(s['full_name'] as String),
                      subtitle: Text(s['reg_no'] as String),
                      trailing: SizedBox(
                        width: 100,
                        child: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '/ ${widget.exam['max_score']}',
                            isDense: true,
                          ),
                          onChanged: (v) => _scores[s['id'] as String] =
                              double.tryParse(v),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(onPressed: _save,
              icon: const Icon(Icons.save), label: Text(tr(context, 'save'))),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PDF HELPERS
// ═══════════════════════════════════════════════════════════════════════════
class PdfBranding {
  final String schoolName;
  final String? schoolNameEn;
  final File? logo;
  final String? address;
  final String? phone;
  final bool watermark;
  PdfBranding({
    required this.schoolName, this.schoolNameEn, this.logo,
    this.address, this.phone, this.watermark = true,
  });
}

class PdfHelper {
  static Future<PdfBranding> branding() async {
    final settings = await DB.I.allSettings();
    final logo = settings['school_logo'];
    return PdfBranding(
      schoolName: settings['school_name'] ?? 'School',
      schoolNameEn: settings['school_name_en'],
      logo: logo != null && File(logo).existsSync() ? File(logo) : null,
      address: settings['school_address'],
      phone: settings['school_phone'],
      watermark: (settings['watermark_enabled'] ?? '1') == '1',
    );
  }

  static Future<pw.MemoryImage?> _img(File? f) async =>
      f != null && f.existsSync() ? pw.MemoryImage(await f.readAsBytes()) : null;

  static pw.Widget _watermark(pw.MemoryImage? logo, PdfBranding b) {
    if (!b.watermark || logo == null) return pw.SizedBox();
    return pw.Opacity(
      opacity: 0.08,
      child: pw.Center(child: pw.Image(logo, width: 340)),
    );
  }

  // ─── Student Card ───
  static Future<void> printStudentCard(Map<String, dynamic> s) async {
    final b = await branding();
    final logo = await _img(b.logo);
    final photo = await _img(
        s['photo'] != null ? File(s['photo'] as String) : null);
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: const PdfPageFormat(85.6 * PdfPageFormat.mm, 54 * PdfPageFormat.mm),
      margin: const pw.EdgeInsets.all(8),
      build: (ctx) => pw.Stack(children: [
        _watermark(logo, b),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.Row(children: [
            if (logo != null) pw.Image(logo, height: 26),
            pw.SizedBox(width: 6),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(b.schoolName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text('Student Card', style: const pw.TextStyle(fontSize: 8)),
            ])),
          ]),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            if (photo != null)
              pw.Container(width: 60, height: 70,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Image(photo, fit: pw.BoxFit.cover))
            else
              pw.Container(width: 60, height: 70,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Center(child: pw.Text('PHOTO', style: const pw.TextStyle(fontSize: 7)))),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(s['full_name'] as String,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('ID: ${s['reg_no']}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Class: ${s['class_id'] ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 4),
              pw.Text('Issued: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 7)),
            ])),
          ]),
          pw.Spacer(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Verify: ${s['reg_no']}', style: const pw.TextStyle(fontSize: 6)),
            pw.Text('Signature: ______', style: const pw.TextStyle(fontSize: 6)),
          ]),
        ]),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  // ─── Teacher Card ───
  static Future<void> printTeacherCard(Map<String, dynamic> t) async {
    final b = await branding();
    final logo = await _img(b.logo);
    final photo = await _img(
        t['photo'] != null ? File(t['photo'] as String) : null);
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: const PdfPageFormat(85.6 * PdfPageFormat.mm, 54 * PdfPageFormat.mm),
      margin: const pw.EdgeInsets.all(8),
      build: (ctx) => pw.Stack(children: [
        _watermark(logo, b),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.Row(children: [
            if (logo != null) pw.Image(logo, height: 26),
            pw.SizedBox(width: 6),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(b.schoolName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text('Staff Card', style: const pw.TextStyle(fontSize: 8)),
            ])),
          ]),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            if (photo != null)
              pw.Container(width: 60, height: 70,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Image(photo, fit: pw.BoxFit.cover))
            else
              pw.Container(width: 60, height: 70,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: pw.Center(child: pw.Text('PHOTO', style: const pw.TextStyle(fontSize: 7)))),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(t['full_name'] as String,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('ID: ${t['employee_no']}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Spec: ${t['specialization'] ?? '-'}', style: const pw.TextStyle(fontSize: 8)),
            ])),
          ]),
        ]),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  // ─── Certificate ───
  static Future<void> printCertificate({
    required String recipientName,
    required String certificateType,
    required String bodyText,
  }) async {
    final b = await branding();
    final logo = await _img(b.logo);
    final serial = 'CERT-${DateTime.now().millisecondsSinceEpoch}';
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(30),
      build: (ctx) => pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 3, color: PdfColors.blue800)),
        padding: const pw.EdgeInsets.all(24),
        child: pw.Stack(children: [
          _watermark(logo, b),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
            pw.Row(children: [
              if (logo != null) pw.Image(logo, height: 60),
              pw.SizedBox(width: 12),
              pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(b.schoolName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                if (b.schoolNameEn != null) pw.Text(b.schoolNameEn!, style: const pw.TextStyle(fontSize: 12)),
              ])),
            ]),
            pw.SizedBox(height: 30),
            pw.Center(child: pw.Text(certificateType,
                style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900))),
            pw.SizedBox(height: 30),
            pw.Center(child: pw.Text(recipientName,
                style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text(bodyText,
                textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 14))),
            pw.Spacer(),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Serial: $serial', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 9)),
              ]),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'CERT:$serial:$recipientName',
                width: 60, height: 60,
              ),
              pw.Column(children: [
                pw.Container(width: 120, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text('Director Signature', style: const pw.TextStyle(fontSize: 9)),
              ]),
            ]),
          ]),
        ]),
      ),
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  // ─── Receipt ───
  static Future<void> printReceipt({
    required Map<String, dynamic> student,
    required double amount,
    required String method,
    required String receiptNo,
  }) async {
    final b = await branding();
    final logo = await _img(b.logo);
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) => pw.Stack(children: [
        _watermark(logo, b),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.Row(children: [
            if (logo != null) pw.Image(logo, height: 44),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(b.schoolName, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
              pw.Text('Payment Receipt', style: const pw.TextStyle(fontSize: 10)),
            ])),
          ]),
          pw.Divider(),
          pw.SizedBox(height: 8),
          _row('Receipt No.', receiptNo),
          _row('Date', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
          _row('Student', student['full_name'] as String),
          _row('Registration No.', student['reg_no'] as String),
          _row('Amount', amount.toStringAsFixed(2)),
          _row('Method', method),
          _row('Received By', Session.userId.substring(0, 6)),
          pw.Spacer(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Signature: __________', style: const pw.TextStyle(fontSize: 10)),
            pw.BarcodeWidget(barcode: pw.Barcode.qrCode(),
                data: 'RCPT:$receiptNo', width: 50, height: 50),
          ]),
        ]),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  static pw.Widget _row(String k, String v) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(children: [
      pw.SizedBox(width: 120,
          child: pw.Text(k, style: const pw.TextStyle(fontSize: 10))),
      pw.Expanded(child: pw.Text(v,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
    ]),
  );

  // ─── Report Card ───
  static Future<void> printReportCard(Map<String, dynamic> student) async {
    final b = await branding();
    final logo = await _img(b.logo);
    final photo = await _img(
        student['photo'] != null ? File(student['photo'] as String) : null);

    // fetch grades
    final grades = await DB.I.db.rawQuery('''
      SELECT g.score, e.max_score, e.pass_score, e.title, e.term, s.name AS subject
      FROM grades g
      JOIN exams e ON e.id = g.exam_id
      LEFT JOIN subjects s ON s.id = e.subject_id
      WHERE g.student_id = ?
    ''', [student['id']]);

    double total = 0, maxTotal = 0;
    for (var g in grades) {
      total += (g['score'] as num).toDouble();
      maxTotal += (g['max_score'] as num).toDouble();
    }
    final pct = maxTotal == 0 ? 0 : (total / maxTotal * 100);
    final avg = grades.isEmpty ? 0 : total / grades.length;

    // attendance rate
    final att = await DB.I.db.rawQuery(
      'SELECT status, COUNT(*) c FROM attendance WHERE person_id=? GROUP BY status',
      [student['id']]);
    final attMap = {for (var a in att) a['status'] as String: a['c'] as int};
    final present = attMap['present'] ?? 0;
    final totalAtt = attMap.values.fold<int>(0, (a, b) => a + b);
    final attRate = totalAtt == 0 ? 0 : (present / totalAtt * 100);

    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => pw.Stack(children: [
        _watermark(logo, b),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
          pw.Row(children: [
            if (logo != null) pw.Image(logo, height: 50),
            pw.SizedBox(width: 10),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(b.schoolName, style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
              pw.Text('Report Card', style: const pw.TextStyle(fontSize: 13)),
            ])),
          ]),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            if (photo != null) pw.Container(width: 70, height: 85,
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                child: pw.Image(photo, fit: pw.BoxFit.cover)),
            pw.SizedBox(width: 10),
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              _row('Name', student['full_name'] as String),
              _row('Reg. No.', student['reg_no'] as String),
              _row('Gender', (student['gender'] ?? '-') as String),
            ])),
          ]),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Subject', 'Exam', 'Term', 'Score', 'Max', 'Result'],
            data: grades.map((g) {
              final s = (g['score'] as num).toDouble();
              final m = (g['max_score'] as num).toDouble();
              final p = (g['pass_score'] as num).toDouble();
              return [
                g['subject']?.toString() ?? '-',
                g['title']?.toString() ?? '-',
                g['term']?.toString() ?? '-',
                s.toStringAsFixed(1),
                m.toStringAsFixed(0),
                s >= p ? 'Pass' : 'Fail',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Total: ${total.toStringAsFixed(1)}', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Average: ${avg.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Percentage: ${pct.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Attendance: ${attRate.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 11)),
            ]),
          ),
          pw.Spacer(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(children: [
              pw.Container(width: 120, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text('Class Teacher', style: const pw.TextStyle(fontSize: 10)),
            ]),
            pw.Column(children: [
              pw.Container(width: 120, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text('Director', style: const pw.TextStyle(fontSize: 10)),
            ]),
          ]),
        ]),
      ]),
    ));
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STUDENT CARD SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class StudentCardScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  const StudentCardScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final photo = student['photo'] as String?;
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'student_card'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  if (photo != null && File(photo).existsSync())
                    CircleAvatar(radius: 34, backgroundImage: FileImage(File(photo)))
                  else
                    const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 34)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(student['full_name'] as String,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(student['reg_no'] as String),
                  ])),
                ]),
                const SizedBox(height: 12),
                QrImageView(
                  data: 'STU:${student['reg_no']}',
                  size: 140,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 12),
                Text('Scan to verify',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => PdfHelper.printStudentCard(student),
            icon: const Icon(Icons.print),
            label: Text(tr(context, 'print')),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REPORT CARD SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class ReportCardScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  const ReportCardScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'report_card'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.description, size: 80),
            const SizedBox(height: 12),
            Text(student['full_name'] as String,
                style: Theme.of(context).textTheme.titleLarge),
            Text(student['reg_no'] as String),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => PdfHelper.printReportCard(student),
              icon: const Icon(Icons.print),
              label: Text(tr(context, 'print')),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CERTIFICATES
// ═══════════════════════════════════════════════════════════════════════════
class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});
  @override
  State<CertificatesScreen> createState() => _CertsState();
}

class _CertsState extends State<CertificatesScreen> {
  List<Map<String, dynamic>> _students = [];
  String? _studentId;
  String _type = 'Certificate of Achievement';

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final r = await DB.I.db.query('students', orderBy: 'full_name');
    if (mounted) setState(() {
      _students = r;
      _studentId = r.isNotEmpty ? r.first['id'] as String : null;
    });
  }

  Future<void> _generate() async {
    if (_studentId == null) return;
    final s = _students.firstWhere((e) => e['id'] == _studentId);
    await PdfHelper.printCertificate(
      recipientName: s['full_name'] as String,
      certificateType: _type,
      bodyText:
          'This is to certify that the above named student has successfully '
          'completed the requirements of the stated program at ${(await DB.I.getSetting('school_name')) ?? ''}.',
    );
    await DB.I.db.insert('certificates', {
      'id': DB.I.newId(),
      'serial': 'CERT-${DateTime.now().millisecondsSinceEpoch}',
      'type': _type,
      'recipient_id': _studentId,
      'recipient_type': 'student',
      'issued_at': DateTime.now().millisecondsSinceEpoch,
      'issued_by': Session.userId,
      'verify_code': DB.I.newId().substring(0, 8),
    });
    await DB.I.audit(Session.userId, 'certificate_generate', 'student',
        targetId: _studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'certificates'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          DropdownButtonFormField<String>(
            value: _studentId,
            decoration: const InputDecoration(labelText: 'الطالب'),
            items: _students.map((s) => DropdownMenuItem(
                value: s['id'] as String, child: Text(s['full_name'] as String))).toList(),
            onChanged: (v) => setState(() => _studentId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'نوع الشهادة'),
            items: const [
              DropdownMenuItem(value: 'Certificate of Achievement', child: Text('شهادة إنجاز')),
              DropdownMenuItem(value: 'Certificate of Completion', child: Text('شهادة إتمام')),
              DropdownMenuItem(value: 'Certificate of Excellence', child: Text('شهادة تميز')),
              DropdownMenuItem(value: 'Certificate of Attendance', child: Text('شهادة حضور')),
              DropdownMenuItem(value: 'Certificate of Participation', child: Text('شهادة مشاركة')),
              DropdownMenuItem(value: 'Certificate of Appreciation', child: Text('شهادة تقدير')),
            ],
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _generate,
            icon: const Icon(Icons.workspace_premium),
            label: const Text('توليد وطباعة'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              for (var s in _students) {
                await PdfHelper.printCertificate(
                  recipientName: s['full_name'] as String,
                  certificateType: _type,
                  bodyText: 'Certificate issued to the named student.',
                );
              }
            },
            icon: const Icon(Icons.groups),
            label: const Text('توليد للجميع'),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CARDS SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});
  @override
  State<CardsScreen> createState() => _CardsState();
}

class _CardsState extends State<CardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tc;
  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
  }
  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'cards')),
        bottom: TabBar(controller: _tc, tabs: const [
          Tab(text: 'طلاب'), Tab(text: 'معلمون'),
        ]),
      ),
      body: TabBarView(controller: _tc, children: const [
        _StudentCardsList(),
        _TeacherCardsList(),
      ]),
    );
  }
}

class _StudentCardsList extends StatelessWidget {
  const _StudentCardsList();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DB.I.db.query('students', orderBy: 'full_name'),
      builder: (c, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final rows = snap.data!;
        if (rows.isEmpty) return Center(child: Text(tr(context, 'no_data')));
        return ListView.builder(itemCount: rows.length, itemBuilder: (_, i) {
          final s = rows[i];
          return ListTile(
            title: Text(s['full_name'] as String),
            subtitle: Text(s['reg_no'] as String),
            trailing: IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => PdfHelper.printStudentCard(s),
            ),
          );
        });
      },
    );
  }
}

class _TeacherCardsList extends StatelessWidget {
  const _TeacherCardsList();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DB.I.db.query('teachers', orderBy: 'full_name'),
      builder: (c, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final rows = snap.data!;
        if (rows.isEmpty) return Center(child: Text(tr(context, 'no_data')));
        return ListView.builder(itemCount: rows.length, itemBuilder: (_, i) {
          final t = rows[i];
          return ListTile(
            title: Text(t['full_name'] as String),
            subtitle: Text(t['employee_no'] as String),
            trailing: IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => PdfHelper.printTeacherCard(t),
            ),
          );
        });
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FEES
// ═══════════════════════════════════════════════════════════════════════════
class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});
  @override
  State<FeesScreen> createState() => _FeesState();
}

class _FeesState extends State<FeesScreen> {
  List<Map<String, dynamic>> _students = [];
  String? _sid;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final r = await DB.I.db.query('students', orderBy: 'full_name');
    if (mounted) setState(() {
      _students = r;
      _sid = r.isNotEmpty ? r.first['id'] as String : null;
    });
  }

  Future<void> _addFee() async {
    if (_sid == null) return;
    final amount = TextEditingController(text: '1000');
    final type = TextEditingController(text: 'Tuition');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة رسم'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: type, decoration: const InputDecoration(labelText: 'النوع')),
          const SizedBox(height: 8),
          TextField(controller: amount, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok != true) return;
    await DB.I.db.insert('fee_items', {
      'id': DB.I.newId(), 'student_id': _sid, 'type': type.text.trim(),
      'amount': double.tryParse(amount.text) ?? 0,
      'discount': 0,
    });
    setState(() {});
  }

  Future<void> _addPayment() async {
    if (_sid == null) return;
    final amount = TextEditingController();
    final method = TextEditingController(text: 'Cash');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تسجيل دفعة'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amount, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ')),
          const SizedBox(height: 8),
          TextField(controller: method, decoration: const InputDecoration(labelText: 'الطريقة')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تسجيل')),
        ],
      ),
    );
    if (ok != true) return;
    final amt = double.tryParse(amount.text) ?? 0;
    final rno = 'R${DateTime.now().millisecondsSinceEpoch}';
    await DB.I.db.insert('payments', {
      'id': DB.I.newId(), 'receipt_no': rno, 'student_id': _sid,
      'amount': amt, 'method': method.text.trim(),
      'paid_at': DateTime.now().millisecondsSinceEpoch,
      'received_by': Session.userId,
    });
    await DB.I.audit(Session.userId, 'payment', 'student',
        targetId: _sid, newValue: amt.toString());
    final s = _students.firstWhere((e) => e['id'] == _sid);
    await PdfHelper.printReceipt(
        student: s, amount: amt, method: method.text.trim(), receiptNo: rno);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'fees')), actions: [
        IconButton(icon: const Icon(Icons.add_card), tooltip: 'إضافة رسم', onPressed: _addFee),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: DropdownButtonFormField<String>(
            value: _sid,
            decoration: const InputDecoration(labelText: 'الطالب'),
            items: _students.map((s) => DropdownMenuItem(
                value: s['id'] as String, child: Text(s['full_name'] as String))).toList(),
            onChanged: (v) { setState(() => _sid = v); },
          ),
        ),
        Expanded(child: _sid == null
          ? Center(child: Text(tr(context, 'no_data')))
          : _details()),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _addPayment,
            icon: const Icon(Icons.payments),
            label: const Text('تسجيل دفعة + طباعة إيصال'),
          ),
        ),
      ]),
    );
  }

  Widget _details() {
    return FutureBuilder(
      future: Future.wait([
        DB.I.db.query('fee_items', where: 'student_id=?', whereArgs: [_sid]),
        DB.I.db.query('payments', where: 'student_id=?', whereArgs: [_sid]),
      ]),
      builder: (c, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final fees = snap.data![0];
        final pays = snap.data![1];
        final totalFees = fees.fold<double>(0, (a, b) =>
            a + ((b['amount'] as num).toDouble() - ((b['discount'] ?? 0) as num).toDouble()));
        final totalPaid = pays.fold<double>(0, (a, b) => a + (b['amount'] as num).toDouble());
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              _feeCard('إجمالي الرسوم', totalFees, Colors.blue),
              _feeCard('المدفوع', totalPaid, Colors.green),
              _feeCard('المتبقي', totalFees - totalPaid, Colors.red),
            ]),
          ),
          Expanded(child: ListView(children: [
            const Padding(padding: EdgeInsets.all(8),
                child: Text('الرسوم', style: TextStyle(fontWeight: FontWeight.bold))),
            ...fees.map((f) => ListTile(
              dense: true,
              leading: const Icon(Icons.receipt),
              title: Text(f['type'] as String),
              trailing: Text((f['amount'] as num).toStringAsFixed(2)),
            )),
            const Padding(padding: EdgeInsets.all(8),
                child: Text('المدفوعات', style: TextStyle(fontWeight: FontWeight.bold))),
            ...pays.map((p) => ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(p['receipt_no'] as String),
              subtitle: Text(p['method'] as String),
              trailing: Text((p['amount'] as num).toStringAsFixed(2)),
            )),
          ])),
        ]);
      },
    );
  }

  Widget _feeCard(String label, double value, Color color) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 4),
          Text(value.toStringAsFixed(0),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// PAYMENTS
// ═══════════════════════════════════════════════════════════════════════════
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'payments'))),
      body: FutureBuilder(
        future: DB.I.db.rawQuery('''
          SELECT p.*, s.full_name, s.reg_no FROM payments p
          LEFT JOIN students s ON s.id = p.student_id
          ORDER BY p.paid_at DESC LIMIT 300
        '''),
        builder: (c, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snap.data!;
          if (rows.isEmpty) return Center(child: Text(tr(context, 'no_data')));
          return ListView.builder(itemCount: rows.length, itemBuilder: (_, i) {
            final r = rows[i];
            return ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(r['full_name'] as String? ?? '-'),
              subtitle: Text('${r['receipt_no']} • ${r['method']}'),
              trailing: Text((r['amount'] as num).toStringAsFixed(2)),
            );
          });
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REPORTS
// ═══════════════════════════════════════════════════════════════════════════
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'reports'))),
      body: ListView(children: [
        _report(context, 'تقرير الطلاب', Icons.people, () => _studentsReport(context)),
        _report(context, 'تقرير الحضور', Icons.check_circle, () => _attReport(context)),
        _report(context, 'التقرير المالي', Icons.attach_money, () => _finReport(context)),
      ]),
    );
  }

  Widget _report(BuildContext c, String t, IconData i, VoidCallback onTap) =>
      Card(child: ListTile(leading: Icon(i), title: Text(t),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14), onTap: onTap));

  void _studentsReport(BuildContext c) async {
    final rows = await DB.I.db.query('students', orderBy: 'full_name');
    showModalBottomSheet(context: c, builder: (_) => ListView(children: [
      ListTile(title: Text('${rows.length} طالب')),
      ...rows.map((r) => ListTile(
        dense: true, title: Text(r['full_name'] as String),
        subtitle: Text(r['reg_no'] as String),
      )),
    ]));
  }

  void _attReport(BuildContext c) async {
    final rows = await DB.I.db.rawQuery('''
      SELECT status, COUNT(*) n FROM attendance GROUP BY status
    ''');
    showModalBottomSheet(context: c, builder: (_) => ListView(children: [
      for (var r in rows) ListTile(
        title: Text(r['status'] as String),
        trailing: Text('${r['n']}'),
      ),
    ]));
  }

  void _finReport(BuildContext c) async {
    final fees = await DB.I.db.rawQuery('SELECT COALESCE(SUM(amount),0) t FROM fee_items');
    final pays = await DB.I.db.rawQuery('SELECT COALESCE(SUM(amount),0) t FROM payments');
    final total = (fees.first['t'] as num).toDouble();
    final paid = (pays.first['t'] as num).toDouble();
    showModalBottomSheet(context: c, builder: (_) => ListView(children: [
      ListTile(title: const Text('إجمالي الرسوم'), trailing: Text(total.toStringAsFixed(2))),
      ListTile(title: const Text('إجمالي المدفوع'), trailing: Text(paid.toStringAsFixed(2))),
      ListTile(title: const Text('المتبقي'),
          trailing: Text((total - paid).toStringAsFixed(2))),
    ]));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AUDIT SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'audit'))),
      body: FutureBuilder(
        future: DB.I.db.query('audit_logs', orderBy: 'timestamp DESC', limit: 500),
        builder: (c, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snap.data!;
          if (rows.isEmpty) return Center(child: Text(tr(context, 'no_data')));
          return ListView.builder(itemCount: rows.length, itemBuilder: (_, i) {
            final r = rows[i];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.history),
              title: Text('${r['action']} → ${r['target']}'),
              subtitle: Text(DateFormat('yyyy-MM-dd HH:mm:ss')
                  .format(DateTime.fromMillisecondsSinceEpoch(r['timestamp'] as int))),
            );
          });
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SETTINGS
// ═══════════════════════════════════════════════════════════════════════════
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBrandingChanged;
  const SettingsScreen({super.key, this.onBrandingChanged});
  @override
  State<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  final _name = TextEditingController();
  final _nameEn = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  String? _logo;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final s = await DB.I.allSettings();
    setState(() {
      _name.text = s['school_name'] ?? '';
      _nameEn.text = s['school_name_en'] ?? '';
      _address.text = s['school_address'] ?? '';
      _phone.text = s['school_phone'] ?? '';
      _logo = s['school_logo'];
    });
  }

  Future<void> _pickLogo() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery,
        imageQuality: 80, maxWidth: 512);
    if (x == null) return;
    await DB.I.setSetting('school_logo', x.path);
    setState(() => _logo = x.path);
    widget.onBrandingChanged?.call();
  }

  Future<void> _save() async {
    await DB.I.setSetting('school_name', _name.text.trim());
    await DB.I.setSetting('school_name_en', _nameEn.text.trim());
    await DB.I.setSetting('school_address', _address.text.trim());
    await DB.I.setSetting('school_phone', _phone.text.trim());
    await DB.I.audit(Session.userId, 'update', 'settings');
    widget.onBrandingChanged?.call();
    if (mounted) ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
  }

  @override
  Widget build(BuildContext context) {
    final ctx = AppCtx.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'settings'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('معلومات المدرسة', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Center(child: Column(children: [
          if (_logo != null && File(_logo!).existsSync())
            CircleAvatar(radius: 48, backgroundImage: FileImage(File(_logo!)))
          else
            const CircleAvatar(radius: 48, child: Icon(Icons.school, size: 48)),
          TextButton.icon(onPressed: _pickLogo,
              icon: const Icon(Icons.upload), label: const Text('تغيير الشعار')),
        ])),
        _f('اسم المدرسة', _name),
        _f('School Name (EN)', _nameEn),
        _f('العنوان', _address),
        _f('الهاتف', _phone),
        FilledButton.icon(onPressed: _save,
            icon: const Icon(Icons.save), label: Text(tr(context, 'save'))),
        const Divider(height: 40),
        const Text('المظهر', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('فاتح')),
            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('داكن')),
            ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_brightness), label: Text('تلقائي')),
          ],
          selected: {ctx.mode},
          onSelectionChanged: (s) => ctx.setMode(s.first),
        ),
        const SizedBox(height: 16),
        const Text('لون الثيم'),
        const SizedBox(height: 8),
        Wrap(spacing: 10, children: [
          _colorDot(ctx, const Color(0xFF1565C0)),
          _colorDot(ctx, const Color(0xFF00897B)),
          _colorDot(ctx, const Color(0xFF6A1B9A)),
          _colorDot(ctx, const Color(0xFFC62828)),
          _colorDot(ctx, const Color(0xFFEF6C00)),
          _colorDot(ctx, const Color(0xFF2E7D32)),
        ]),
        const Divider(height: 40),
        const Text('اللغة', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'ar', label: Text('العربية')),
            ButtonSegment(value: 'en', label: Text('English')),
          ],
          selected: {ctx.locale.languageCode},
          onSelectionChanged: (s) => ctx.setLocale(Locale(s.first)),
        ),
        const Divider(height: 40),
        const Text('البيانات التجريبية'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _seedDemo,
          icon: const Icon(Icons.science_outlined),
          label: const Text('إضافة بيانات تجريبية'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _clearDemo(context),
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('مسح كل البيانات (مع الإبقاء على المستخدمين)'),
        ),
      ]),
    );
  }

  Widget _colorDot(AppCtx ctx, Color c) => GestureDetector(
    onTap: () => ctx.setSeed(c),
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: c, shape: BoxShape.circle,
        border: Border.all(
          color: ctx.seed == c ? Colors.white : Colors.transparent, width: 3),
      ),
    ),
  );

  Widget _f(String l, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(controller: c, decoration: InputDecoration(labelText: l)),
  );

  Future<void> _seedDemo() async {
    final db = DB.I.db;
    // classes
    if ((await db.query('classes')).isEmpty) {
      for (var n in ['Grade 1', 'Grade 2', 'Grade 3']) {
        await db.insert('classes', {
          'id': DB.I.newId(), 'name': n, 'level': 'Primary',
          'order': DateTime.now().millisecondsSinceEpoch + n.hashCode,
        });
      }
    }
    final classes = await db.query('classes');
    // sections
    for (var c in classes) {
      final s = await db.query('sections',
          where: 'class_id=?', whereArgs: [c['id']]);
      if (s.isEmpty) {
        await db.insert('sections', {
          'id': DB.I.newId(), 'class_id': c['id'], 'name': 'A',
        });
      }
    }
    final sections = await db.query('sections');
    // subjects
    if ((await db.query('subjects')).isEmpty) {
      for (var sub in ['Math', 'Arabic', 'English', 'Science']) {
        await db.insert('subjects', {
          'id': DB.I.newId(), 'name': sub,
          'code': '${sub.substring(0, 2).toUpperCase()}${DateTime.now().microsecondsSinceEpoch % 1000}',
          'class_id': classes.first['id'], 'weekly_hours': 2,
        });
      }
    }
    // teachers
    if ((await db.query('teachers')).isEmpty) {
      for (var i = 1; i <= 3; i++) {
        await db.insert('teachers', {
          'id': DB.I.newId(),
          'employee_no': 'T${1000 + i}',
          'full_name': ['أحمد محمد', 'فاطمة علي', 'يوسف إبراهيم'][i - 1],
          'specialization': ['رياضيات', 'لغة عربية', 'علوم'][i - 1],
        });
      }
    }
    // students
    if ((await db.query('students')).isEmpty) {
      final names = ['عبدالله سعد', 'مريم يوسف', 'كريم أنور',
        'سارة محمد', 'علي حسن', 'نور خالد'];
      for (var i = 0; i < names.length; i++) {
        final id = DB.I.newId();
        final reg = 'S${2000 + i}';
        await db.insert('students', {
          'id': id, 'reg_no': reg, 'full_name': names[i],
          'gender': i.isEven ? 'male' : 'female',
          'class_id': classes[i % classes.length]['id'],
          'section_id': sections[i % sections.length]['id'],
          'enroll_date': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
        });
        try { await Auth.createStudentAccount(id, reg); } catch (_) {}
      }
    }
    if (mounted) ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تمت إضافة البيانات التجريبية')));
  }

  Future<void> _clearDemo(BuildContext c) async {
    final ok = await showDialog<bool>(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد'),
        content: const Text('سيتم حذف كل البيانات باستثناء المستخدمين. متابعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (ok != true) return;
    final db = DB.I.db;
    for (var t in ['students', 'teachers', 'classes', 'sections', 'subjects',
      'attendance', 'exams', 'grades', 'fee_items', 'payments',
      'certificates', 'audit_logs']) {
      await db.delete(t);
    }
    if (mounted) ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تم المسح')));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STUDENT PORTAL
// ═══════════════════════════════════════════════════════════════════════════
class StudentPortal extends StatefulWidget {
  const StudentPortal({super.key});
  @override
  State<StudentPortal> createState() => _StudentPortalState();
}

class _StudentPortalState extends State<StudentPortal> {
  Map<String, dynamic>? _student;
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db = DB.I.db;
    final s = await db.query('students',
        where: 'id=?', whereArgs: [Session.linkedId], limit: 1);
    if (s.isEmpty) { setState(() => _loading = false); return; }
    final student = s.first;
    final att = await db.rawQuery(
        'SELECT status, COUNT(*) c FROM attendance WHERE person_id=? GROUP BY status',
        [student['id']]);
    final grades = await db.rawQuery('''
      SELECT g.score, e.max_score, e.pass_score, e.title, s.name AS subject
      FROM grades g JOIN exams e ON e.id=g.exam_id
      LEFT JOIN subjects s ON s.id=e.subject_id
      WHERE g.student_id=?''', [student['id']]);
    double total = 0, maxT = 0;
    for (var g in grades) {
      total += (g['score'] as num).toDouble();
      maxT += (g['max_score'] as num).toDouble();
    }
    final present = (att.firstWhere((a) => a['status'] == 'present',
        orElse: () => {'c': 0})['c'] as int);
    final totalAtt = att.fold<int>(0, (a, b) => a + (b['c'] as int));
    setState(() {
      _student = student;
      _stats = {
        'attendance': totalAtt == 0 ? 0 : (present / totalAtt * 100),
        'avg': grades.isEmpty ? 0 : total / grades.length,
        'pct': maxT == 0 ? 0 : (total / maxT * 100),
        'gradesCount': grades.length,
      };
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_student == null) return Scaffold(
      body: Center(child: Text(tr(context, 'no_data'))));

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'student_portal')),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () {
            Session.current = null;
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          }),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Card(child: ListTile(
          leading: CircleAvatar(
            backgroundImage: _student!['photo'] != null &&
                File(_student!['photo'] as String).existsSync()
                ? FileImage(File(_student!['photo'] as String)) : null,
            child: _student!['photo'] == null ? const Icon(Icons.person) : null,
          ),
          title: Text(_student!['full_name'] as String),
          subtitle: Text(_student!['reg_no'] as String),
        )),
        Row(children: [
          _statCard('حضور %', '${(_stats['attendance'] as double).toStringAsFixed(1)}%',
              Icons.check_circle, Colors.green),
          _statCard('متوسط', (_stats['avg'] as double).toStringAsFixed(1),
              Icons.grade, Colors.blue),
        ]),
        Row(children: [
          _statCard('النسبة %', '${(_stats['pct'] as double).toStringAsFixed(1)}%',
              Icons.trending_up, Colors.orange),
          _statCard('الدرجات', '${_stats['gradesCount']}', Icons.list, Colors.purple),
        ]),
        _action(tr(context, 'my_card'), Icons.badge, () =>
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StudentCardScreen(student: _student!)))),
        _action(tr(context, 'report_card'), Icons.description, () =>
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ReportCardScreen(student: _student!)))),
        _action(tr(context, 'my_grades'), Icons.grade, () =>
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StudentGradesScreen(studentId: _student!['id'] as String)))),
        _action(tr(context, 'my_attendance'), Icons.check_circle, () =>
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StudentAttendanceScreen(studentId: _student!['id'] as String)))),
        _action(tr(context, 'change_password'), Icons.lock, () =>
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ChangePasswordScreen()))),
      ]),
    );
  }

  Widget _statCard(String l, String v, IconData i, Color c) => Expanded(
    child: Card(child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Icon(i, color: c, size: 28),
        const SizedBox(height: 6),
        Text(v, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c)),
        Text(l, style: const TextStyle(fontSize: 11)),
      ]),
    )),
  );

  Widget _action(String t, IconData i, VoidCallback onTap) =>
      Card(child: ListTile(leading: Icon(i), title: Text(t),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14), onTap: onTap));
}

class StudentGradesScreen extends StatelessWidget {
  final String studentId;
  const StudentGradesScreen({super.key, required this.studentId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'my_grades'))),
      body: FutureBuilder(
        future: DB.I.db.rawQuery('''
          SELECT g.score, e.max_score, e.title, e.term, s.name AS subject
          FROM grades g JOIN exams e ON e.id=g.exam_id
          LEFT JOIN subjects s ON s.id=e.subject_id
          WHERE g.student_id=? ORDER BY e.date DESC''', [studentId]),
        builder: (c, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snap.data!;
          if (rows.isEmpty) return Center(child: Text(tr(context, 'no_data')));
          return ListView.builder(itemCount: rows.length, itemBuilder: (_, i) {
            final r = rows[i];
            return ListTile(
              title: Text(r['subject']?.toString() ?? '-'),
              subtitle: Text('${r['title']} • ${r['term']}'),
              trailing: Text('${r['score']}/${r['max_score']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          });
        },
      ),
    );
  }
}

class StudentAttendanceScreen extends StatelessWidget {
  final String studentId;
  const StudentAttendanceScreen({super.key, required this.studentId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'my_attendance'))),
      body: FutureBuilder(
        future: DB.I.db.query('attendance',
            where: 'person_id=?', whereArgs: [studentId],
            orderBy: 'date DESC', limit: 200),
        builder: (c, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snap.data!;
          if (rows.isEmpty) return Center(child: Text(tr(context, 'no_data')));
          return ListView.builder(itemCount: rows.length, itemBuilder: (_, i) {
            final r = rows[i];
            return ListTile(
              title: Text(r['status'] as String),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(
                  DateTime.fromMillisecondsSinceEpoch(r['date'] as int))),
            );
          });
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TEACHER PORTAL
// ═══════════════════════════════════════════════════════════════════════════
class TeacherPortal extends StatelessWidget {
  const TeacherPortal({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'teacher_portal')),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () {
            Session.current = null;
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          }),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        _action(context, tr(context, 'students'), Icons.people_outline,
            () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const StudentsScreen()))),
        _action(context, tr(context, 'attendance'), Icons.check_circle_outline,
            () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AttendanceScreen()))),
        _action(context, tr(context, 'exams'), Icons.assignment_outlined,
            () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ExamsScreen()))),
        _action(context, tr(context, 'grades'), Icons.grade_outlined,
            () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const GradesScreen()))),
        _action(context, tr(context, 'change_password'), Icons.lock,
            () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ChangePasswordScreen()))),
      ]),
    );
  }

  Widget _action(BuildContext c, String t, IconData i, VoidCallback onTap) =>
      Card(child: ListTile(leading: Icon(i), title: Text(t),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14), onTap: onTap));
}

// ═══════════════════════════════════════════════════════════════════════════
// PARENT PORTAL
// ═══════════════════════════════════════════════════════════════════════════
class ParentPortal extends StatelessWidget {
  const ParentPortal({super.key});
  @override
  Widget build(BuildContext context) {
    // Demo: parent sees first student's data (simplified)
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'parent_portal')),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () {
            Session.current = null;
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          }),
        ],
      ),
      body: FutureBuilder(
        future: DB.I.db.query('students', limit: 5),
        builder: (c, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snap.data!;
          if (rows.isEmpty) return Center(child: Text(tr(context, 'no_data')));
          return ListView(children: [
            const Padding(padding: EdgeInsets.all(12),
                child: Text('أبنائي', style: TextStyle(fontWeight: FontWeight.bold))),
            ...rows.map((s) => Card(child: ListTile(
              leading: CircleAvatar(
                backgroundImage: s['photo'] != null &&
                    File(s['photo'] as String).existsSync()
                    ? FileImage(File(s['photo'] as String)) : null,
                child: s['photo'] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(s['full_name'] as String),
              subtitle: Text(s['reg_no'] as String),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ParentChildDetail(student: s))),
            ))),
          ]);
        },
      ),
    );
  }
}

class ParentChildDetail extends StatelessWidget {
  final Map<String, dynamic> student;
  const ParentChildDetail({super.key, required this.student});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(student['full_name'] as String)),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Card(child: ListTile(
          leading: const Icon(Icons.badge),
          title: const Text('بطاقة الطالب'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StudentCardScreen(student: student))),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.description),
          title: const Text('كشف الدرجات'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ReportCardScreen(student: student))),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.grade),
          title: const Text('الدرجات'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StudentGradesScreen(studentId: student['id'] as String))),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.check_circle),
          title: const Text('الحضور'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StudentAttendanceScreen(studentId: student['id'] as String))),
        )),
      ]),
    );
  }
}
// ═══════════════════════════════════════════════════════════════════════════
// END OF FILE
// ═══════════════════════════════════════════════════════════════════════════
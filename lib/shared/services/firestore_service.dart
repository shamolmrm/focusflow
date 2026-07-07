import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../models/habit.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference? get _userDoc =>
      _uid == null ? null : _db.collection('users').doc(_uid);

  // ── User profile ────────────────────────────────────────────────────────────

  static Future<void> saveUser(AppUser user) async {
    final doc = _userDoc;
    if (doc == null) return;
    await doc.set({
      ...user.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<AppUser?> loadUser() async {
    final doc = _userDoc;
    if (doc == null) return null;
    final snap = await doc.get();
    if (!snap.exists) return null;
    final d = Map<String, dynamic>.from(snap.data() as Map);
    // Firestore may store createdAt as Timestamp — normalise to ISO string
    if (d['createdAt'] is! String) {
      d['createdAt'] = DateTime.now().toIso8601String();
    }
    d['id'] = _uid!;
    return AppUser.fromJson(d);
  }

  // ── Habits ──────────────────────────────────────────────────────────────────

  static Future<void> saveHabits(List<Habit> habits) async {
    final doc = _userDoc;
    if (doc == null) return;
    final batch = _db.batch();
    final col = doc.collection('habits');

    // Overwrite all habits as a batch
    for (final h in habits) {
      batch.set(col.doc(h.id), h.toJson());
    }
    await batch.commit();
  }

  static Future<List<Habit>> loadHabits() async {
    final doc = _userDoc;
    if (doc == null) return [];
    final snap = await doc.collection('habits').get();
    return snap.docs
        .map((d) => Habit.fromJson(d.data()))
        .toList();
  }

  // ── Focus stats ─────────────────────────────────────────────────────────────

  static Future<void> addFocusMinutes(int minutes, int xpEarned) async {
    final doc = _userDoc;
    if (doc == null) return;
    final today = _dateKey(DateTime.now());
    await doc.set({
      'stats': {
        today: FieldValue.increment(minutes),
        'totalMinutes': FieldValue.increment(minutes),
        'totalXp': FieldValue.increment(xpEarned),
        'sessions': FieldValue.increment(1),
      }
    }, SetOptions(merge: true));
  }

  // ── FCM token ───────────────────────────────────────────────────────────────

  static Future<void> saveFcmToken(String token) async {
    final doc = _userDoc;
    if (doc == null) return;
    await doc.set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> removeFcmToken(String token) async {
    final doc = _userDoc;
    if (doc == null) return;
    await doc.set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _dateKey(DateTime d) =>
      '${d.year}_${d.month.toString().padLeft(2, '0')}_${d.day.toString().padLeft(2, '0')}';
}

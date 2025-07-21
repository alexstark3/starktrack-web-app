import 'package:cloud_firestore/cloud_firestore.dart';

/// Rate limiting system to prevent brute force attacks
class LoginRateLimiter {
  // Maximum failed attempts allowed
  static const int maxFailedAttempts = 5;
  
  // Time window for counting attempts (15 minutes)
  static const Duration attemptWindow = Duration(minutes: 15);
  
  // Lockout duration after max attempts (15 minutes)
  static const Duration lockoutDuration = Duration(minutes: 15);

  /// Check if a user can attempt to login
  static Future<bool> canAttemptLogin(String email) async {
    try {
      final emailKey = _normalizeEmail(email);
      final now = DateTime.now();
      
      // Get the user's login attempts from Firestore
      final attemptsDoc = await FirebaseFirestore.instance
          .collection('login_attempts')
          .doc(emailKey)
          .get();

      if (!attemptsDoc.exists) {
        // No previous attempts, allow login
        return true;
      }

      final data = attemptsDoc.data()!;
      final attempts = List<DateTime>.from(data['attempts'] ?? []);
      final isLocked = data['isLocked'] ?? false;
      final lockoutUntil = data['lockoutUntil'] != null 
          ? (data['lockoutUntil'] as Timestamp).toDate() 
          : null;

      // Check if account is currently locked
      if (isLocked && lockoutUntil != null && now.isBefore(lockoutUntil)) {
        return false; // Account is locked
      }

      // If lockout period has expired, reset the account
      if (isLocked && lockoutUntil != null && now.isAfter(lockoutUntil)) {
        await _resetAccount(emailKey);
        return true;
      }

      // Filter attempts within the time window
      final recentAttempts = attempts.where((attempt) => 
          now.difference(attempt) <= attemptWindow).toList();

      // Check if too many recent attempts
      if (recentAttempts.length >= maxFailedAttempts) {
        // Lock the account
        await _lockAccount(emailKey, now);
        return false;
      }

      return true;
    } catch (e) {
      // If there's an error, allow login (fail open for user experience)
      return true;
    }
  }

  /// Record a failed login attempt
  static Future<void> recordFailedAttempt(String email) async {
    try {
      final emailKey = _normalizeEmail(email);
      final now = DateTime.now();
      
      final attemptsDoc = await FirebaseFirestore.instance
          .collection('login_attempts')
          .doc(emailKey)
          .get();

      List<DateTime> attempts = [];
      if (attemptsDoc.exists) {
        final data = attemptsDoc.data()!;
        attempts = List<DateTime>.from(data['attempts'] ?? []);
      }

      // Add new attempt
      attempts.add(now);
      
      // Keep only recent attempts (within window)
      attempts = attempts.where((attempt) => 
          now.difference(attempt) <= attemptWindow).toList();

      // Check if we should lock the account
      bool isLocked = false;
      DateTime? lockoutUntil;
      
      if (attempts.length >= maxFailedAttempts) {
        isLocked = true;
        lockoutUntil = now.add(lockoutDuration);
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('login_attempts')
          .doc(emailKey)
          .set({
        'email': email,
        'attempts': attempts.map((d) => Timestamp.fromDate(d)).toList(),
        'isLocked': isLocked,
        'lockoutUntil': lockoutUntil != null ? Timestamp.fromDate(lockoutUntil) : null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // print('Error recording failed attempt: $e');
    }
  }

  /// Record a successful login attempt (reset the counter)
  static Future<void> recordSuccessfulLogin(String email) async {
    try {
      final emailKey = _normalizeEmail(email);
      
      // Reset the account on successful login
      await _resetAccount(emailKey);
    } catch (e) {
      // print('Error recording successful login: $e');
    }
  }

  /// Reset account after successful login or lockout expiration
  static Future<void> _resetAccount(String emailKey) async {
    await FirebaseFirestore.instance
        .collection('login_attempts')
        .doc(emailKey)
        .set({
      'attempts': [],
      'isLocked': false,
      'lockoutUntil': null,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Lock account after too many failed attempts
  static Future<void> _lockAccount(String emailKey, DateTime now) async {
    await FirebaseFirestore.instance
        .collection('login_attempts')
        .doc(emailKey)
        .update({
      'isLocked': true,
      'lockoutUntil': Timestamp.fromDate(now.add(lockoutDuration)),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Normalize email for consistent storage
  static String _normalizeEmail(String email) {
    return email.toLowerCase().trim();
  }

  /// Get remaining lockout time for a user
  static Future<Duration?> getRemainingLockoutTime(String email) async {
    try {
      final emailKey = _normalizeEmail(email);
      final attemptsDoc = await FirebaseFirestore.instance
          .collection('login_attempts')
          .doc(emailKey)
          .get();

      if (!attemptsDoc.exists) return null;

      final data = attemptsDoc.data()!;
      final isLocked = data['isLocked'] ?? false;
      final lockoutUntil = data['lockoutUntil'] != null 
          ? (data['lockoutUntil'] as Timestamp).toDate() 
          : null;

      if (!isLocked || lockoutUntil == null) return null;

      final now = DateTime.now();
      if (now.isAfter(lockoutUntil)) return null;

      return lockoutUntil.difference(now);
    } catch (e) {
      // print('Error getting lockout time: $e');
      return null;
    }
  }

  /// Get remaining attempts before lockout
  static Future<int> getRemainingAttempts(String email) async {
    try {
      final emailKey = _normalizeEmail(email);
      final now = DateTime.now();
      
      final attemptsDoc = await FirebaseFirestore.instance
          .collection('login_attempts')
          .doc(emailKey)
          .get();

      if (!attemptsDoc.exists) return maxFailedAttempts;

      final data = attemptsDoc.data()!;
      final attempts = List<DateTime>.from(data['attempts'] ?? []);
      
      // Filter attempts within the time window
      final recentAttempts = attempts.where((attempt) => 
          now.difference(attempt) <= attemptWindow).toList();

      return maxFailedAttempts - recentAttempts.length;
    } catch (e) {
      // print('Error getting remaining attempts: $e');
      return maxFailedAttempts;
    }
  }
} 
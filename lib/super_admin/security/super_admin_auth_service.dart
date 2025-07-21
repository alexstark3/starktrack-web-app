import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuperAdminAuthService {
  static const String _adminCollection = 'sadmin';
  
  /// Check if the current user is an admin
  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection(_adminCollection)
          .doc(user.uid)
          .get();
      
      return adminDoc.exists;
    } catch (e) {
      return false;
    }
  }
  
  /// Get admin user data
  static Future<Map<String, dynamic>?> getAdminData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection(_adminCollection)
          .doc(user.uid)
          .get();
      
      if (!adminDoc.exists) return null;
      
      return adminDoc.data();
    } catch (e) {
      return null;
    }
  }
  
  /// Check if admin has specific role
  static Future<bool> hasAdminRole(String role) async {
    final adminData = await getAdminData();
    if (adminData == null) return false;
    
    final roles = List<String>.from(adminData['roles'] ?? []);
    return roles.contains(role);
  }
  
  /// Check if admin has super admin privileges
  static Future<bool> isSuperAdmin() async {
    return await hasAdminRole('super_admin');
  }
  
  /// Get all admin users (for super admin management)
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(_adminCollection)
          .get();
      
      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Create new admin user
  static Future<bool> createAdmin({
    required String email,
    required String password,
    required String firstName,
    required String surname,
    required List<String> roles,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      
      final user = userCredential.user;
      if (user == null) return false;
      
      // Create admin document
      await FirebaseFirestore.instance
          .collection(_adminCollection)
          .doc(user.uid)
          .set({
        'email': email,
        'firstName': firstName,
        'surname': surname,
        'roles': roles,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Update admin user
  static Future<bool> updateAdmin({
    required String adminId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection(_adminCollection)
          .doc(adminId)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Delete admin user
  static Future<bool> deleteAdmin(String adminId) async {
    try {
      await FirebaseFirestore.instance
          .collection(_adminCollection)
          .doc(adminId)
          .delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }
} 
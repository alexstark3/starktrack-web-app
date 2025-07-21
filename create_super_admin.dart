import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// This script helps you create your first super admin
// Run this once to set up your super admin user

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  
  print('=== Super Admin Creation Tool ===\n');
  
  // Get current user
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('❌ No user logged in. Please log in first.');
    return;
  }
  
  print('Current user: ${user.email}');
  print('User ID: ${user.uid}');
  
  // Find which company this user belongs to
  final companies = await FirebaseFirestore.instance.collection('companies').get();
  
  String? userCompanyId;
  DocumentSnapshot? userDoc;
  
  for (final company in companies.docs) {
    final userRef = company.reference.collection('users').doc(user.uid);
    final userSnapshot = await userRef.get();
    
    if (userSnapshot.exists) {
      userCompanyId = company.id;
      userDoc = userSnapshot;
      break;
    }
  }
  
  if (userCompanyId == null || userDoc == null) {
    print('❌ User not found in any company.');
    return;
  }
  
  print('Found user in company: $userCompanyId');
  
  // Check current roles
  final userData = userDoc.data() as Map<String, dynamic>;
  final currentRoles = List<String>.from(userData['roles'] ?? []);
  
  print('Current roles: ${currentRoles.join(', ')}');
  
  if (currentRoles.contains('super_admin')) {
    print('✅ User is already a super admin!');
    return;
  }
  
  // Add super_admin role
  currentRoles.add('super_admin');
  
  // Update user
  await userDoc.reference.update({
    'roles': currentRoles,
  });
  
  print('✅ Successfully added super_admin role!');
  print('New roles: ${currentRoles.join(', ')}');
  print('\nYou can now:');
  print('1. Access the Migration Tool in Admin Panel');
  print('2. Manage all companies (if you have access)');
  print('3. Use all super admin features');
  
  // Also create user access document for fast login
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'email': user.email,
    'companyId': userCompanyId,
    'createdAt': FieldValue.serverTimestamp(),
  });
  
  print('✅ Created fast access document for login optimization');
} 
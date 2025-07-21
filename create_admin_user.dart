import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';

// This script creates your first admin user in the separate admin collection
// Run this to set up your admin system

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  
  print('=== Admin User Creation Tool ===\n');
  
  // Get admin details
  stdout.write('Enter admin email: ');
  final email = stdin.readLineSync()?.trim();
  if (email == null || email.isEmpty) {
    print('❌ Email is required');
    return;
  }
  
  stdout.write('Enter admin password (min 6 chars): ');
  final password = stdin.readLineSync();
  if (password == null || password.length < 6) {
    print('❌ Password must be at least 6 characters');
    return;
  }
  
  stdout.write('Enter first name: ');
  final firstName = stdin.readLineSync()?.trim();
  if (firstName == null || firstName.isEmpty) {
    print('❌ First name is required');
    return;
  }
  
  stdout.write('Enter surname: ');
  final surname = stdin.readLineSync()?.trim();
  if (surname == null || surname.isEmpty) {
    print('❌ Surname is required');
    return;
  }
  
  stdout.write('Make super admin? (y/n): ');
  final makeSuperAdmin = stdin.readLineSync()?.toLowerCase() == 'y';
  
  final roles = makeSuperAdmin ? ['super_admin'] : ['admin'];
  
  print('\nCreating admin user...');
  print('Email: $email');
  print('Name: $firstName $surname');
  print('Roles: ${roles.join(', ')}');
  
  stdout.write('\nProceed? (y/n): ');
  final confirm = stdin.readLineSync()?.toLowerCase();
  if (confirm != 'y') {
    print('❌ Cancelled');
    return;
  }
  
  try {
    // Create Firebase Auth user
    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    
    final user = userCredential.user;
    if (user == null) {
      print('❌ Failed to create Firebase Auth user');
      return;
    }
    
    // Create admin document
    await FirebaseFirestore.instance
        .collection('admin_users')
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
    
    print('✅ Admin user created successfully!');
    print('User ID: ${user.uid}');
    print('Roles: ${roles.join(', ')}');
    
    if (makeSuperAdmin) {
      print('\n🎉 Super Admin created! You can now:');
      print('1. Access the admin dashboard');
      print('2. Use the migration tool');
      print('3. Manage all companies');
    } else {
      print('\n🎉 Admin created! You can now:');
      print('1. Access the admin dashboard');
      print('2. Manage admin users');
    }
    
    print('\nTo access admin dashboard:');
    print('1. Navigate to /admin in your app');
    print('2. Or add a route to AdminLoginScreen');
    
  } catch (e) {
    print('❌ Error creating admin user: $e');
    
    if (e.toString().contains('email-already-in-use')) {
      print('\n💡 The email is already registered. You can:');
      print('1. Use a different email');
      print('2. Or manually add the user to admin_users collection');
    }
  }
} 
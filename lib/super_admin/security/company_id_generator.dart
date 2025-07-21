import 'dart:math';

/// Generates secure company IDs with format: {company-name}-{8-char-random-code}
class CompanyIdGenerator {
  static const String _chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const int _randomCodeLength = 8;
  
  /// Generate a secure company ID from company name
  /// Example: "Sm Tronik" → "sm-tronik-AbC3h5El"
  static String generateSecureCompanyId(String companyName) {
    // Normalize company name: lowercase, replace spaces with hyphens
    final normalizedName = companyName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')  // Replace spaces with hyphens
        .replaceAll(RegExp(r'[^a-z0-9-]'), ''); // Remove special characters
    
    // Generate random 8-character code
    final randomCode = _generateRandomCode();
    
    return '$normalizedName-$randomCode';
  }
  
  /// Generate random 8-character code with mixed case and numbers
  static String _generateRandomCode() {
    final random = Random.secure(); // Use secure random for better security
    return String.fromCharCodes(
      Iterable.generate(_randomCodeLength, (_) => _chars.codeUnitAt(random.nextInt(_chars.length)))
    );
  }
  
  /// Extract company name from secure ID
  /// Example: "sm-tronik-AbC3h5El" → "sm-tronik"
  static String extractCompanyName(String secureCompanyId) {
    final parts = secureCompanyId.split('-');
    if (parts.length < 2) return secureCompanyId;
    
    // Remove the last part (random code) and join the rest
    return parts.take(parts.length - 1).join('-');
  }
  
  /// Validate if a company ID follows the secure format
  static bool isValidSecureCompanyId(String companyId) {
    // Check if it has the format: {name}-{8-char-code}
    final parts = companyId.split('-');
    if (parts.length < 2) return false;
    
    final randomCode = parts.last;
    if (randomCode.length != _randomCodeLength) return false;
    
    // Check if random code contains only valid characters
    return RegExp(r'^[a-zA-Z0-9]{8}$').hasMatch(randomCode);
  }
  
  /// Generate multiple random codes for testing
  static List<String> generateTestCodes(int count) {
    return List.generate(count, (_) => _generateRandomCode());
  }
} 
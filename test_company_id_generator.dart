import 'lib/super_admin/security/company_id_generator.dart';

void main() {
  print('=== Company ID Generator Test ===\n');
  
  // Test company names
  final testCompanies = [
    'smtronik',
    'Sm Tronik',
    'Acme Corp',
    'Test Company 123',
    'My-Company',
    'Company with Spaces',
  ];
  
  for (final companyName in testCompanies) {
    final secureId = CompanyIdGenerator.generateSecureCompanyId(companyName);
    final extractedName = CompanyIdGenerator.extractCompanyName(secureId);
    final isValid = CompanyIdGenerator.isValidSecureCompanyId(secureId);
    
    print('Original: "$companyName"');
    print('Secure ID: "$secureId"');
    print('Extracted: "$extractedName"');
    print('Valid: $isValid');
    print('---');
  }
  
  // Test random code generation
  print('\n=== Random Code Test ===');
  final testCodes = CompanyIdGenerator.generateTestCodes(5);
  for (int i = 0; i < testCodes.length; i++) {
    print('Code ${i + 1}: ${testCodes[i]}');
  }
  
  // Test validation
  print('\n=== Validation Test ===');
  final testIds = [
    'sm-tronik-AbC3h5El',  // Valid
    'acme-corp-12345678',  // Valid
    'invalid-id',          // Invalid (no random code)
    'test-123',            // Invalid (short random code)
    'company-name-ABC123', // Invalid (mixed case in random code)
  ];
  
  for (final testId in testIds) {
    final isValid = CompanyIdGenerator.isValidSecureCompanyId(testId);
    print('"$testId" -> Valid: $isValid');
  }
} 
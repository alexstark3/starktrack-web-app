import 'dart:convert';
import 'dart:io';

void main() async {
  final inputFile = File('scripts/AMTOVZ_CSV_LV95.csv');
  final outputFile = File('lib/data/swiss_cities.json');

  final lines = await inputFile.readAsLines();
  if (lines.isEmpty) {
    print('Input file is empty.');
    return;
  }

  final header = lines.first.split(';');
  final plzIdx = header.indexOf('PLZ');
  final gemeindeIdx = header.indexOf('Gemeindename');
  final kantonIdx = header.indexOf('Kantonskürzel');

  // Map: { 'kanton|gemeinde' : {area, city, Set<postCodes>} }
  final Map<String, Map<String, dynamic>> cityMap = {};

  for (final line in lines.skip(1)) {
    if (line.trim().isEmpty) continue;
    final parts = line.split(';');
    if (parts.length <= kantonIdx) continue;

    final postCode = parts[plzIdx].trim();
    final gemeinde = parts[gemeindeIdx].trim();
    final kanton = parts[kantonIdx].trim();

    if (kanton.isEmpty || gemeinde.isEmpty || postCode.isEmpty) continue;

    final key = '$kanton|$gemeinde';
    
    if (!cityMap.containsKey(key)) {
      cityMap[key] = {
        'area': kanton,
        'city': gemeinde,
        'postCodes': <String>{},
      };
    }
    
    cityMap[key]!['postCodes'].add(postCode);
  }

  // Convert to list and sort
  final result = cityMap.values.map((city) {
    final postCodesList = (city['postCodes'] as Set<String>).toList()..sort();
    return {
      'area': city['area'],
      'city': city['city'],
      'postCodes': postCodesList,
    };
  }).toList();

  // Sort by area, then by city
  result.sort((a, b) {
    final areaCompare = a['area'].compareTo(b['area']);
    if (areaCompare != 0) return areaCompare;
    return a['city'].compareTo(b['city']);
  });

  await outputFile.writeAsString(JsonEncoder.withIndent('  ').convert(result));
  print('Generated ${result.length} municipalities with their post codes.');
  
  // Print some examples
  print('\nExamples:');
  for (final city in result.take(10)) {
    print('${city['area']} - ${city['city']}: ${city['postCodes'].join(', ')}');
  }
  
  // Print Luzern specifically
  final luzern = result.where((city) => city['city'] == 'Luzern').firstOrNull;
  if (luzern != null) {
    print('\nLuzern post codes: ${luzern['postCodes'].join(', ')}');
  }
} 
class CarouselConfig {
  // Auto-generated from assets/dasboard_img directory
  static const List<String> imageFilenames = [
    'Approvals - Manage aprovals of Time Off Requests.png',
    'Balance - Complete overview of Team member Time Off Balance.png',
    'Calendar - Overview of vacation and holidays and other custom policy.png',
    'Holiday Policy - Add custom Holidays to your specific Area and Company policy.png',
    'Time Off Policy - Add custom policy for Special Time Off Requests.png',
    'Time Tracker - Simple time entry session connected to projects, expenses and notes..png',
  ];

  static String getImageFilename(int index) {
    if (index >= 0 && index < imageFilenames.length) {
      return imageFilenames[index];
    }
    return 'dash$index.png'; // Fallback
  }

  static String getShortName(int index) {
    final filename = getImageFilename(index);
    final nameWithoutExt = filename.split('.').first; // Remove .png extension
    
    // Check if there's a dash separator for short name - full description
    // Handle both " - " and "-" separators
    if (nameWithoutExt.contains(' - ')) {
      final dashParts = nameWithoutExt.split(' - ');
      if (dashParts.length >= 2) {
        return dashParts[0].trim();
      }
    } else if (nameWithoutExt.contains('-')) {
      final dashParts = nameWithoutExt.split('-');
      if (dashParts.length >= 2) {
        return dashParts[0].trim();
      }
    }
    
    // If no dash, return the filename without extension
    return nameWithoutExt;
  }

  static String getFullDescription(int index) {
    final filename = getImageFilename(index);
    final nameWithoutExt = filename.split('.').first; // Remove .png extension
    
    // Check if there's a dash separator for short name - full description
    // Handle both " - " and "-" separators
    if (nameWithoutExt.contains(' - ')) {
      final dashParts = nameWithoutExt.split(' - ');
      if (dashParts.length >= 2) {
        return dashParts[1].trim();
      }
    } else if (nameWithoutExt.contains('-')) {
      final dashParts = nameWithoutExt.split('-');
      if (dashParts.length >= 2) {
        return dashParts[1].trim();
      }
    }
    
    // If no dash, return empty description
    return '';
  }
}

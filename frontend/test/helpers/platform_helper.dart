// This file provides mock implementations for platform-specific features
// to make tests work regardless of the platform they run on.

// For web-specific features
class MockHtmlHelper {
  // Mock methods for any HTML functionality used in the app
  // Add methods as needed
  
  static void download(List<int> bytes, String fileName, String contentType) {
    // Mock implementation - in tests this just pretends to download
  }
  
  static void openInNewTab(String url) {
    // Mock implementation - in tests this just pretends to open a new tab
  }
  
  static String getWindowLocation() {
    return 'https://test.example.com';
  }
}

// Add more mock classes as needed for other platform-specific imports

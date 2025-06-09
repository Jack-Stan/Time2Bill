// Stub implementation for non-web platforms
// This provides dummy implementations of web-specific functionality

// Stub methods to match the real dart:html functionality
void downloadFile(List<int> bytes, String fileName, String contentType) {
  // No-op implementation for non-web platforms
}

void openInNewTab(String url) {
  // No-op implementation for non-web platforms
}

String getWindowLocation() {
  return 'https://test.example.com';
}

// Helper file to conditionally import dart:html for web platform tests
// Use this instead of importing dart:html directly in your code

import 'html_stub.dart' if (dart.library.html) 'html_impl.dart' as html;

// Common interface for web-specific functions
class WebHelper {
  static void downloadFile(List<int> bytes, String fileName, String contentType) {
    html.downloadFile(bytes, fileName, contentType);
  }
  
  static void openInNewTab(String url) {
    html.openInNewTab(url);
  }
  
  static String getWindowLocation() {
    return html.getWindowLocation();
  }
}

// Real implementation using web package for web platforms
import 'package:universal_html/html.dart' as html;

// Actual implementations of web-specific functionality
void downloadFile(List<int> bytes, String fileName, String contentType) {
  final blob = html.Blob([bytes], contentType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}

void openInNewTab(String url) {
  html.window.open(url, '_blank');
}

String getWindowLocation() {
  return html.window.location.href;
}

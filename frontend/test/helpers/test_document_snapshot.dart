// A simple implementation to simulate Firebase models with a TestDocumentSnapshot
// that avoids issues with sealed classes

/// A simple implementation to use in place of actual DocumentSnapshot
/// for testing models that depend on Firestore
class TestDocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;

  TestDocumentSnapshot(this._id, this._data);

  String get id => _id;
  Map<String, dynamic> data() => _data;
}

/// Extension methods for creating models from test snapshots
extension ClientModelFromTest on TestDocumentSnapshot {
  /// Convert a test document snapshot to a model
  T toModel<T>(T Function(TestDocumentSnapshot) fromTestDoc) {
    return fromTestDoc(this);
  }
}

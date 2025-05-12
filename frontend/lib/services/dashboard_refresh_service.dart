import 'dart:async';

/// Beheert een stream die kan worden gebruikt om widgets te informeren over gebeurtenissen
class DashboardRefreshService {
  // Singleton pattern
  static final DashboardRefreshService _instance = DashboardRefreshService._internal();
  
  factory DashboardRefreshService() {
    return _instance;
  }
  
  DashboardRefreshService._internal();
  
  // StreamController voor het verzenden van gebeurtenissen
  final _controller = StreamController<bool>.broadcast();
  
  /// Stroom waarop widgets kunnen luisteren voor vernieuwingsgebeurtenissen
  Stream<bool> get refreshStream => _controller.stream;
  
  /// Roep deze methode aan wanneer een widget het dashboard moet vernieuwen
  void refreshDashboard() {
    _controller.add(true);
  }
  
  /// Sluit de stream controller wanneer niet meer nodig
  void dispose() {
    _controller.close();
  }
}

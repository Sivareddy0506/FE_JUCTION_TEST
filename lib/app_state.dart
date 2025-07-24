class AppState {
  static AppState? _instance;

  AppState._();

  static AppState get instance => _instance ??= AppState._();
  bool isJuction = false;
  String auctionDate = "";
  String listingDuration = "";
}
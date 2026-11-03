class SupportRoutePresence {
  SupportRoutePresence._();

  static bool visible = false;
  static String? threadUuid;

  static bool isViewing(String? uuid) =>
      visible && (uuid == null || uuid.isEmpty || threadUuid == uuid);
}

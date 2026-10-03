// User-visible strings in pt-BR. No hard-coded text in widgets.
// See PLAN.md 9.2 and section 20 appendices.
/// Table of pt-BR strings used by every screen.
class StringsPt {
  const StringsPt._();

  /// Application name in the app bar.
  static const String appName = 'Pontual';

  /// Welcome headline.
  static const String welcomeTitle = 'Acompanhe o ônibus ao vivo';

  /// First welcome bullet.
  static const String welcomeBullet1 = 'Veja onde o ônibus está';

  /// Second welcome bullet.
  static const String welcomeBullet2 =
      'Quem está dentro compartilha a posição, de forma anônima';

  /// Third welcome bullet.
  static const String welcomeBullet3 = 'Sem cadastro, sem anúncios';

  /// Non-affiliation disclaimer.
  static const String unofficialNotice = 'App independente e não oficial.';

  /// Primary action label.
  static const String start = 'Começar';

  /// Privacy explainer entry point.
  static const String privacyHow = 'Como funciona a privacidade';

  /// Home app bar title.
  static const String homeTitle = 'Pontual';

  /// Home search field hint.
  static const String homeSearchHint = 'Buscar linha ou bairro';

  /// Section header for lines with vehicles.
  static const String homeLiveNow = 'Ao vivo agora';

  /// Section header for the full line list.
  static const String homeAllLines = 'Todas as linhas';

  /// Subtitle for lines without live tracking.
  static const String homeTimetableOnly = 'Só horários';

  /// Persistent timetable disclaimer.
  static const String homeUnofficial = 'Horários não oficiais.';

  /// Settings screen title.
  static const String settingsTitle = 'Configurações';

  /// Privacy center title.
  static const String privacyTitle = 'Privacidade';

  /// About screen title.
  static const String aboutTitle = 'Sobre';

  /// Trip screen title.
  static const String tripTitle = 'Viagem';

  /// Share action starting a trip.
  static const String shareTrip = 'Estou no ônibus';

  /// Line screen title.
  static const String lineTitle = 'Linha';

  /// System screen title.
  static const String systemTitle = 'Aviso';

  /// RF16 walking prompt title.
  static const String walkingTitle = 'Você ainda está no ônibus?';

  /// Confirm button keeping the trip alive.
  static const String walkingYes = 'Sim, continuar';

  /// Confirm button ending the trip.
  static const String walkingNo = 'Desci';

  /// Offline saver status row.
  static const String offlineSaver =
      'Sem conexão. Vamos retomar assim que voltar.';

  /// GPS-off banner text.
  static const String gpsOffBanner =
      'Ative a localização para continuar compartilhando.';

  /// Connection status when connected.
  static const String connected = 'Conexão     ✓ Conectado';

  /// Connection status when offline.
  static const String disconnected =
      'Conexão     ✕ Sem conexão - tentando de novo';

  /// GPS status when the fix quality is good.
  static const String gpsGood = 'GPS         ✓ Bom';

  /// GPS status when location services are off.
  static const String gpsOff = 'GPS         Desligado';

  /// Placeholder body for screens built in later tasks.
  static const String placeholderBody = 'Em construção.';
}

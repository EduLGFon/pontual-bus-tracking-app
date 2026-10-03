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

  /// Line screen title.
  static const String lineTitle = 'Linha';

  /// System screen title.
  static const String systemTitle = 'Aviso';

  /// Placeholder body for screens built in later tasks.
  static const String placeholderBody = 'Em construção.';
}

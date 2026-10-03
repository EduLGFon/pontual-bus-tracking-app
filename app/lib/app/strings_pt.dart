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

  /// Web trip banner: keep the page open and unlocked.
  static const String webKeepOpen =
      'Mantenha esta tela aberta e o celular desbloqueado.';

  /// Web trip note about battery: the screen stays on.
  static const String webWakeNote =
      'A tela fica ligada durante a viagem. Baixe o brilho para economizar bateria.';

  /// Shown when the browser cannot hold a wake lock.
  static const String webWakeUnsupported =
      'Este navegador não mantém a tela ligada. Deixe o brilho no máximo e não troque de aba.';

  /// Shown while a web trip is paused for a hidden page.
  static const String webHiddenPaused =
      'Tela oculta: compartilhamento pausado. Volte para esta aba para continuar.';

  /// iOS install hint title.
  static const String installHintTitle = 'Instale o Pontual';

  /// iOS install hint steps for the Safari share sheet.
  static const String installHintBody =
      'No Safari, toque em Compartilhar e depois em "Adicionar à Tela de Início" para abrir como app.';

  /// iOS install hint dismiss button.
  static const String installHintDismiss = 'Entendi';

  /// Settings theme section title.
  static const String themeTitle = 'Tema';

  /// Theme option following the system.
  static const String themeSystem = 'Sistema';

  /// Light theme option.
  static const String themeLight = 'Claro';

  /// Dark theme option.
  static const String themeDark = 'Escuro';

  /// Row opening the privacy center.
  static const String privacyData = 'Privacidade e dados';

  /// Row opening the about screen.
  static const String aboutSources = 'Sobre e fontes de dados';

  /// Settings help section title.
  static const String helpTitle = 'Ajuda';

  /// How to share a trip.
  static const String helpShare =
      'Para compartilhar: abra a linha do seu ônibus, toque em "Estou no ônibus" e confirme. Toque em "Desci" ao descer.';

  /// Battery tip for trips stopped by the system.
  static const String helpBattery =
      'Se a viagem parar sozinha, defina a bateria do app como "Sem restrições" nas configurações do celular.';

  /// Web and iOS notice.
  static const String helpWeb =
      'Na web e no iPhone, o compartilhamento funciona só com a tela aberta.';

  /// Contact row label.
  static const String contactUs = 'Falar com a gente';

  /// Timetable version prefix.
  static const String timetablesPrefix = 'Horários: ';

  /// About non-affiliation disclaimer.
  static const String aboutDisclaimer =
      'App independente e não oficial. Não é da Viação São Gabriel nem da Prefeitura de São Mateus.';

  /// About sources section title.
  static const String aboutSourcesTitle = 'Fontes dos dados';

  /// About source line for timetables.
  static const String aboutSourceLines =
      'Linhas e horários: transcritos de páginas públicas (onibus.online). Horários não oficiais e podem mudar sem aviso.';

  /// OSM attribution row.
  static const String aboutOsm = 'Mapa: © OpenStreetMap contributors';

  /// Row opening the open-source licences page.
  static const String aboutLicences = 'Licenças de código aberto';

  /// Row opening the source repository.
  static const String aboutRepo = 'Código-fonte';

  /// Privacy delete action.
  static const String privacyDelete = 'Apagar meus dados';

  /// Delete confirmation title.
  static const String privacyDeleteTitle = 'Apagar meus dados?';

  /// Delete confirmation body.
  static const String privacyDeleteBody =
      'Isso encerra sua viagem, apaga os dados ligados a este aparelho no servidor e reinicia o app.';

  /// Cancel button.
  static const String privacyCancel = 'Cancelar';

  /// Delete confirm button.
  static const String privacyConfirmDelete = 'Apagar';

  /// Offline delete error: honest, keeps local data.
  static const String privacyOffline =
      'Sem conexão. Tente novamente quando estiver online.';

  /// Consent revocation action.
  static const String privacyRevoke = 'Revogar consentimento';

  /// Revocation confirmation.
  static const String privacyRevoked =
      'Consentimento revogado. Vamos pedir de novo na próxima viagem.';

  /// Policy row.
  static const String privacyPolicy = 'Política de Privacidade';

  /// Terms row.
  static const String privacyTerms = 'Termos de Uso';

  /// Collection summary section title.
  static const String privacyCollectsTitle = 'O que coletamos';

  /// Contact row for data-subject requests.
  static const String privacyContact = 'Contato para seus dados';
}

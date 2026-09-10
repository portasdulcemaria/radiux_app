import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_provider.dart';

class AppStrings {
  final String _lang;
  AppStrings._(this._lang);

  factory AppStrings.of(BuildContext context) {
    final lp = context.watch<LanguageProvider>();
    return AppStrings._(lp.locale.languageCode);
  }

  static AppStrings listen(BuildContext context) {
    final lp = context.read<LanguageProvider>();
    return AppStrings._(lp.locale.languageCode);
  }

  String _t(String key) =>
      (_translations[_lang] ?? _translations['es']!)[key] ??
      _translations['es']![key] ??
      key;

  String get appTitle           => 'Radiux';
  String get tagline            => _t('tagline');
  String get sectionCalc        => _t('sectionCalc');
  String get sectionRecords     => _t('sectionRecords');
  String get sectionPrefs       => _t('sectionPrefs');
  String get sectionLegal       => _t('sectionLegal');
  String get unitConversion     => _t('unitConversion');
  String get radioactiveDecay   => _t('radioactiveDecay');
  String get shiftActivity      => _t('shiftActivity');
  String get settings           => _t('settings');
  String get terms              => _t('terms');
  String get privacy            => _t('privacy');
  String get about              => _t('about');
  String get language           => _t('language');
  String get selectLanguage     => _t('selectLanguage');
  String get stateOk            => _t('stateOk');
  String get stateAttention     => _t('stateAttention');
  String get stateCritical      => _t('stateCritical');
  String get stateExpired       => _t('stateExpired');
  String get calculate          => _t('calculate');
  String get copy               => _t('copy');
  String get clear              => _t('clear');
  String get cancel             => _t('cancel');
  String get close              => _t('close');
  String get activity           => _t('activity');
  String get isotope            => _t('isotope');
  String get result             => _t('result');
  String get remaining          => _t('remaining');
  String get halfLives          => _t('halfLives');
  String get reduction          => _t('reduction');
  String get initialActivity    => _t('initialActivity');
  String get residualActivity   => _t('residualActivity');

  // Conversion screen
  String get convert            => _t('convert');
  String get from               => _t('from');
  String get toward             => _t('toward');
  String get newConversion      => _t('newConversion');
  String get copyResult         => _t('copyResult');
  String get copied             => _t('copied');
  String get selectUnit         => _t('selectUnit');
  String get quickReference     => _t('quickReference');
  String get lastLabel          => _t('lastLabel');
  String get enterPositiveValue => _t('enterPositiveValue');

  // History screen
  String get todayShift         => _t('todayShift');
  String get records            => _t('records');
  String get today              => _t('today');
  String get yesterday          => _t('yesterday');
  String get sevenDays          => _t('sevenDays');
  String get filterByIsotope    => _t('filterByIsotope');
  String get allIsotopes        => _t('allIsotopes');
  String get noFilter           => _t('noFilter');
  String get avgRemainingAct    => _t('avgRemainingAct');
  String get shiftNotStarted    => _t('shiftNotStarted');
  String get shiftNotStartedSub => _t('shiftNotStartedSub');
  String get goToDecay          => _t('goToDecay');
  String get lowActivity        => _t('lowActivity');
  String get initialLabel       => _t('initialLabel');
  String get todayUpper         => _t('todayUpper');
  String get yesterdayUpper     => _t('yesterdayUpper');

  // Decaimiento screen
  String get newCalculation     => _t('newCalculation');
  String get confirmIsotope     => _t('confirmIsotope');
  String get initialDate        => _t('initialDate');
  String get modify             => _t('modify');
  String get elapsedTime        => _t('elapsedTime');
  String get activityUnit       => _t('activityUnit');
  String get selectIsotope      => _t('selectIsotope');
  String get recent             => _t('recent');
  String get dateLabel          => _t('dateLabel');
  String get timeLabel          => _t('timeLabel');
  String get now                => _t('now');
  String get calculateResidual  => _t('calculateResidual');
  String get recordedInShift    => _t('recordedInShift');
  String get remainingActivity  => _t('remainingActivity');
  String get autoCalculated     => _t('autoCalculated');

  static const List<SupportedLanguage> supportedLanguages = [
    SupportedLanguage(code: 'es', name: 'Español',  nativeName: 'Español',   flag: '🇦🇷'),
    SupportedLanguage(code: 'en', name: 'Inglés',   nativeName: 'English',   flag: '🇬🇧'),
    SupportedLanguage(code: 'it', name: 'Italiano', nativeName: 'Italiano',  flag: '🇮🇹'),
    SupportedLanguage(code: 'ku', name: 'Kurdo',    nativeName: 'Kurdî',     flag: '🏳️'),
    SupportedLanguage(code: 'el', name: 'Griego',   nativeName: 'Ελληνικά', flag: '🇬🇷'),
    SupportedLanguage(code: 'ru', name: 'Ruso',     nativeName: 'Русский',  flag: '🇷🇺'),
  ];

  static const Map<String, Map<String, String>> _translations = {
    'es': {
      'tagline': 'Medicina Nuclear',
      'sectionCalc': 'Calculadoras',
      'sectionRecords': 'Registros',
      'sectionPrefs': 'Preferencias',
      'sectionLegal': 'Legal',
      'unitConversion': 'Conversión de unidades',
      'radioactiveDecay': 'Decaimiento radiactivo',
      'shiftActivity': 'Actividad del turno',
      'settings': 'Configuración',
      'terms': 'Términos y condiciones',
      'privacy': 'Política de privacidad',
      'about': 'Acerca de Radiux',
      'language': 'Idioma',
      'selectLanguage': 'Seleccionar idioma',
      'stateOk': 'Dentro rango',
      'stateAttention': 'Verificar dosis',
      'stateCritical': 'Verificar viabilidad',
      'stateExpired': 'Fuera de ventana',
      'calculate': 'Calcular',
      'copy': 'Copiar',
      'clear': 'Limpiar',
      'cancel': 'Cancelar',
      'close': 'Cerrar',
      'activity': 'Actividad',
      'isotope': 'Isótopo',
      'result': 'Resultado',
      'remaining': 'Restante',
      'halfLives': 'Vidas medias',
      'reduction': 'Reducción',
      'initialActivity': 'Actividad inicial',
      'residualActivity': 'Actividad residual',
      'convert': 'Convertir',
      'from': 'Desde',
      'toward': 'Hacia',
      'newConversion': 'Nueva conversión',
      'copyResult': 'Copiar resultado',
      'copied': 'Copiado',
      'selectUnit': 'Seleccioná unidad',
      'quickReference': 'Referencia rápida',
      'lastLabel': 'Último: ',
      'enterPositiveValue': 'Ingresá un valor mayor a cero',
      'todayShift': 'TURNO DE HOY',
      'records': 'REGISTROS',
      'today': 'Hoy',
      'yesterday': 'Ayer',
      'sevenDays': '7 días',
      'filterByIsotope': 'Filtrar por isótopo',
      'allIsotopes': 'Todos los isótopos',
      'noFilter': 'Sin filtro activo',
      'avgRemainingAct': 'Actividad promedio restante',
      'shiftNotStarted': 'Aún no comenzó tu turno',
      'shiftNotStartedSub': 'Calculá un decaimiento para empezar a registrar la actividad del turno.',
      'goToDecay': 'Ir a Decaimiento',
      'lowActivity': 'Actividad baja',
      'initialLabel': 'Inicial: ',
      'todayUpper': 'HOY',
      'yesterdayUpper': 'AYER',
      'newCalculation': 'Nuevo cálculo',
      'confirmIsotope': 'Confirmar isótopo',
      'initialDate': 'Fecha inicial',
      'modify': 'Modificar',
      'elapsedTime': 'Tiempo transcurrido',
      'activityUnit': 'Unidad de actividad',
      'selectIsotope': 'Seleccionar isótopo',
      'recent': 'RECIENTES',
      'dateLabel': 'Fecha',
      'timeLabel': 'Hora',
      'now': 'Ahora',
      'calculateResidual': 'Calcular actividad residual',
      'recordedInShift': 'Registrado en turno',
      'remainingActivity': 'ACTIVIDAD RESTANTE',
      'autoCalculated': 'Calculada automáticamente · ',
    },
    'en': {
      'tagline': 'Nuclear Medicine',
      'sectionCalc': 'Calculators',
      'sectionRecords': 'Records',
      'sectionPrefs': 'Preferences',
      'sectionLegal': 'Legal',
      'unitConversion': 'Unit conversion',
      'radioactiveDecay': 'Radioactive decay',
      'shiftActivity': 'Shift activity',
      'settings': 'Settings',
      'terms': 'Terms & Conditions',
      'privacy': 'Privacy Policy',
      'about': 'About Radiux',
      'language': 'Language',
      'selectLanguage': 'Select language',
      'stateOk': 'In range',
      'stateAttention': 'Check dose',
      'stateCritical': 'Check viability',
      'stateExpired': 'Outside window',
      'calculate': 'Calculate',
      'copy': 'Copy',
      'clear': 'Clear',
      'cancel': 'Cancel',
      'close': 'Close',
      'activity': 'Activity',
      'isotope': 'Isotope',
      'result': 'Result',
      'remaining': 'Remaining',
      'halfLives': 'Half-lives',
      'reduction': 'Reduction',
      'initialActivity': 'Initial activity',
      'residualActivity': 'Residual activity',
      'convert': 'Convert',
      'from': 'From',
      'toward': 'To',
      'newConversion': 'New conversion',
      'copyResult': 'Copy result',
      'copied': 'Copied',
      'selectUnit': 'Select unit',
      'quickReference': 'Quick reference',
      'lastLabel': 'Last: ',
      'enterPositiveValue': 'Enter a value greater than zero',
      'todayShift': "TODAY'S SHIFT",
      'records': 'RECORDS',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'sevenDays': '7 days',
      'filterByIsotope': 'Filter by isotope',
      'allIsotopes': 'All isotopes',
      'noFilter': 'No active filter',
      'avgRemainingAct': 'Average remaining activity',
      'shiftNotStarted': "Your shift hasn't started yet",
      'shiftNotStartedSub': 'Calculate a decay to start recording shift activity.',
      'goToDecay': 'Go to Decay',
      'lowActivity': 'Low activity',
      'initialLabel': 'Initial: ',
      'todayUpper': 'TODAY',
      'yesterdayUpper': 'YESTERDAY',
      'newCalculation': 'New calculation',
      'confirmIsotope': 'Confirm isotope',
      'initialDate': 'Initial date',
      'modify': 'Modify',
      'elapsedTime': 'Elapsed time',
      'activityUnit': 'Activity unit',
      'selectIsotope': 'Select isotope',
      'recent': 'RECENT',
      'dateLabel': 'Date',
      'timeLabel': 'Time',
      'now': 'Now',
      'calculateResidual': 'Calculate residual activity',
      'recordedInShift': 'Recorded in shift',
      'remainingActivity': 'REMAINING ACTIVITY',
      'autoCalculated': 'Auto-calculated · ',
    },
    'it': {
      'tagline': 'Medicina Nucleare',
      'sectionCalc': 'Calcolatori',
      'sectionRecords': 'Registri',
      'sectionPrefs': 'Preferenze',
      'sectionLegal': 'Legale',
      'unitConversion': 'Conversione unità',
      'radioactiveDecay': 'Decadimento radioattivo',
      'shiftActivity': 'Attività del turno',
      'settings': 'Impostazioni',
      'terms': 'Termini e condizioni',
      'privacy': 'Informativa privacy',
      'about': 'Informazioni su Radiux',
      'language': 'Lingua',
      'selectLanguage': 'Seleziona lingua',
      'stateOk': 'Nel range',
      'stateAttention': 'Verifica dose',
      'stateCritical': 'Verifica fattibilità',
      'stateExpired': 'Fuori finestra',
      'calculate': 'Calcola',
      'copy': 'Copia',
      'clear': 'Cancella',
      'cancel': 'Annulla',
      'close': 'Chiudi',
      'activity': 'Attività',
      'isotope': 'Isotopo',
      'result': 'Risultato',
      'remaining': 'Rimanente',
      'halfLives': 'Emivite',
      'reduction': 'Riduzione',
      'initialActivity': 'Attività iniziale',
      'residualActivity': 'Attività residua',
      'convert': 'Converti',
      'from': 'Da',
      'toward': 'A',
      'newConversion': 'Nuova conversione',
      'copyResult': 'Copia risultato',
      'copied': 'Copiato',
      'selectUnit': 'Seleziona unità',
      'quickReference': 'Riferimento rapido',
      'lastLabel': 'Ultimo: ',
      'enterPositiveValue': 'Inserisci un valore maggiore di zero',
      'todayShift': 'TURNO DI OGGI',
      'records': 'REGISTRI',
      'today': 'Oggi',
      'yesterday': 'Ieri',
      'sevenDays': '7 giorni',
      'filterByIsotope': 'Filtra per isotopo',
      'allIsotopes': 'Tutti gli isotopi',
      'noFilter': 'Nessun filtro attivo',
      'avgRemainingAct': 'Attività media residua',
      'shiftNotStarted': 'Il turno non è ancora iniziato',
      'shiftNotStartedSub': "Calcola un decadimento per iniziare a registrare l'attività del turno.",
      'goToDecay': 'Vai a Decadimento',
      'lowActivity': 'Attività bassa',
      'initialLabel': 'Iniziale: ',
      'todayUpper': 'OGGI',
      'yesterdayUpper': 'IERI',
      'newCalculation': 'Nuovo calcolo',
      'confirmIsotope': 'Conferma isotopo',
      'initialDate': 'Data iniziale',
      'modify': 'Modifica',
      'elapsedTime': 'Tempo trascorso',
      'activityUnit': 'Unità di attività',
      'selectIsotope': 'Seleziona isotopo',
      'recent': 'RECENTI',
      'dateLabel': 'Data',
      'timeLabel': 'Ora',
      'now': 'Adesso',
      'calculateResidual': 'Calcola attività residua',
      'recordedInShift': 'Registrato nel turno',
      'remainingActivity': 'ATTIVITÀ RESIDUA',
      'autoCalculated': 'Calcolato automaticamente · ',
    },
    'ku': {
      'tagline': 'Tıbbê Nûklear',
      'sectionCalc': 'Hesabker',
      'sectionRecords': 'Tomar',
      'sectionPrefs': 'Bijarteyên',
      'sectionLegal': 'Yasayî',
      'unitConversion': 'Veguhertina yekeyan',
      'radioactiveDecay': 'Hilweşîna radyoaktîf',
      'shiftActivity': 'Çalakiya şiftê',
      'settings': 'Mîheng',
      'terms': 'Şert û mercan',
      'privacy': 'Polîtîkaya nepenîtiyê',
      'about': 'Der barê Radiux',
      'language': 'Ziman',
      'selectLanguage': 'Zimanê hilbijêre',
      'stateOk': 'Di nav sînoran',
      'stateAttention': 'Dozê kontrol bike',
      'stateCritical': 'Jiyana kontrol bike',
      'stateExpired': 'Ji pencerê derve',
      'calculate': 'Hesab bike',
      'copy': 'Kopî bike',
      'clear': 'Paqij bike',
      'cancel': 'Betal bike',
      'close': 'Bigire',
      'activity': 'Çalakî',
      'isotope': 'Îzotop',
      'result': 'Encam',
      'remaining': 'Mayî',
      'halfLives': 'Nîvjiyan',
      'reduction': 'Kêmkirin',
      'initialActivity': 'Çalakiya destpêkê',
      'residualActivity': 'Çalakiya mayî',
      'convert': 'Veguhêre',
      'from': 'Ji',
      'toward': 'Bo',
      'newConversion': 'Veguhertina nû',
      'copyResult': 'Encamê kopî bike',
      'copied': 'Kopî kir',
      'selectUnit': 'Yekeyê hilbijêre',
      'quickReference': 'Çavkaniya bilez',
      'lastLabel': 'Dawî: ',
      'enterPositiveValue': 'Nirxek ji sifirê mezintir binivîse',
      'todayShift': 'ŞÎFTA ÎROYÊ',
      'records': 'TOMAR',
      'today': 'Îro',
      'yesterday': 'Duh',
      'sevenDays': '7 roj',
      'filterByIsotope': 'Li gorî îzotopê fîlter bike',
      'allIsotopes': 'Hemû îzotop',
      'noFilter': 'Fîltera çalak tune',
      'avgRemainingAct': 'Çalakiya navîn a mayî',
      'shiftNotStarted': 'Şîfta te hêj dest pê nekir',
      'shiftNotStartedSub': 'Hilweşînek hesab bike da ku tomarkirin dest pê bike.',
      'goToDecay': 'Biçe Hilweşînê',
      'lowActivity': 'Çalakiya kêm',
      'initialLabel': 'Destpêkê: ',
      'todayUpper': 'ÎRO',
      'yesterdayUpper': 'DUH',
      'newCalculation': 'Hesabek nû',
      'confirmIsotope': 'Îzotopê piştrast bike',
      'initialDate': 'Dîroka destpêkê',
      'modify': 'Biguherîne',
      'elapsedTime': 'Dema derbasbûyî',
      'activityUnit': 'Yekeya çalakiyê',
      'selectIsotope': 'Îzotopê hilbijêre',
      'recent': 'DAWÎ',
      'dateLabel': 'Dîrok',
      'timeLabel': 'Dem',
      'now': 'Niha',
      'calculateResidual': 'Çalakiya mayî hesab bike',
      'recordedInShift': 'Di şiftê de tomarkirin',
      'remainingActivity': 'ÇALAKIYA MAYÎ',
      'autoCalculated': 'Xweser hesabkirin · ',
    },
    'el': {
      'tagline': 'Πυρηνική Ιατρική',
      'sectionCalc': 'Αριθμομηχανές',
      'sectionRecords': 'Αρχεία',
      'sectionPrefs': 'Προτιμήσεις',
      'sectionLegal': 'Νομικά',
      'unitConversion': 'Μετατροπή μονάδων',
      'radioactiveDecay': 'Ραδιενεργός αποσύνθεση',
      'shiftActivity': 'Δραστηριότητα βάρδιας',
      'settings': 'Ρυθμίσεις',
      'terms': 'Όροι & Προϋποθέσεις',
      'privacy': 'Πολιτική απορρήτου',
      'about': 'Σχετικά με Radiux',
      'language': 'Γλώσσα',
      'selectLanguage': 'Επιλογή γλώσσας',
      'stateOk': 'Εντός εύρους',
      'stateAttention': 'Ελέγξτε δόση',
      'stateCritical': 'Ελέγξτε βιωσιμότητα',
      'stateExpired': 'Εκτός παραθύρου',
      'calculate': 'Υπολογισμός',
      'copy': 'Αντιγραφή',
      'clear': 'Εκκαθάριση',
      'cancel': 'Ακύρωση',
      'close': 'Κλείσιμο',
      'activity': 'Δραστηριότητα',
      'isotope': 'Ισότοπο',
      'result': 'Αποτέλεσμα',
      'remaining': 'Απομένον',
      'halfLives': 'Ημίχρονα',
      'reduction': 'Μείωση',
      'initialActivity': 'Αρχική δραστηριότητα',
      'residualActivity': 'Υπολειπόμενη δραστηριότητα',
      'convert': 'Μετατροπή',
      'from': 'Από',
      'toward': 'Προς',
      'newConversion': 'Νέα μετατροπή',
      'copyResult': 'Αντιγραφή αποτελέσματος',
      'copied': 'Αντιγράφηκε',
      'selectUnit': 'Επιλογή μονάδας',
      'quickReference': 'Γρήγορη αναφορά',
      'lastLabel': 'Τελευταίο: ',
      'enterPositiveValue': 'Εισάγετε τιμή μεγαλύτερη του μηδενός',
      'todayShift': 'ΒΆΡΔΙΑ ΣΉΜΕΡΑ',
      'records': 'ΑΡΧΕΊΑ',
      'today': 'Σήμερα',
      'yesterday': 'Χθες',
      'sevenDays': '7 ημέρες',
      'filterByIsotope': 'Φίλτρο ανά ισότοπο',
      'allIsotopes': 'Όλα τα ισότοπα',
      'noFilter': 'Χωρίς ενεργό φίλτρο',
      'avgRemainingAct': 'Μέση υπολειπόμενη δραστηριότητα',
      'shiftNotStarted': 'Η βάρδιά σας δεν έχει ξεκινήσει',
      'shiftNotStartedSub': 'Υπολογίστε αποσύνθεση για να ξεκινήσετε την καταγραφή.',
      'goToDecay': 'Μετάβαση στην Αποσύνθεση',
      'lowActivity': 'Χαμηλή δραστηριότητα',
      'initialLabel': 'Αρχική: ',
      'todayUpper': 'ΣΉΜΕΡΑ',
      'yesterdayUpper': 'ΧΘΕΣ',
      'newCalculation': 'Νέος υπολογισμός',
      'confirmIsotope': 'Επιβεβαίωση ισοτόπου',
      'initialDate': 'Αρχική ημερομηνία',
      'modify': 'Τροποποίηση',
      'elapsedTime': 'Χρόνος που πέρασε',
      'activityUnit': 'Μονάδα δραστηριότητας',
      'selectIsotope': 'Επιλογή ισοτόπου',
      'recent': 'ΠΡΌΣΦΑΤΑ',
      'dateLabel': 'Ημερομηνία',
      'timeLabel': 'Ώρα',
      'now': 'Τώρα',
      'calculateResidual': 'Υπολογισμός υπολειπόμενης δραστηριότητας',
      'recordedInShift': 'Καταγράφηκε στη βάρδια',
      'remainingActivity': 'ΥΠΟΛΕΙΠΌΜΕΝΗ ΔΡΑΣΤΗΡΙΌΤΗΤΑ',
      'autoCalculated': 'Αυτόματος υπολογισμός · ',
    },
    'ru': {
      'tagline': 'Ядерная медицина',
      'sectionCalc': 'Калькуляторы',
      'sectionRecords': 'Записи',
      'sectionPrefs': 'Настройки',
      'sectionLegal': 'Правовое',
      'unitConversion': 'Конверсия единиц',
      'radioactiveDecay': 'Радиоактивный распад',
      'shiftActivity': 'Активность смены',
      'settings': 'Настройки',
      'terms': 'Условия использования',
      'privacy': 'Политика конфиденциальности',
      'about': 'О Radiux',
      'language': 'Язык',
      'selectLanguage': 'Выбрать язык',
      'stateOk': 'В норме',
      'stateAttention': 'Проверить дозу',
      'stateCritical': 'Проверить жизнеспособность',
      'stateExpired': 'Вне окна',
      'calculate': 'Вычислить',
      'copy': 'Копировать',
      'clear': 'Очистить',
      'cancel': 'Отмена',
      'close': 'Закрыть',
      'activity': 'Активность',
      'isotope': 'Изотоп',
      'result': 'Результат',
      'remaining': 'Остаток',
      'halfLives': 'Периоды полураспада',
      'reduction': 'Снижение',
      'initialActivity': 'Начальная активность',
      'residualActivity': 'Остаточная активность',
      'convert': 'Конвертировать',
      'from': 'Из',
      'toward': 'В',
      'newConversion': 'Новая конверсия',
      'copyResult': 'Копировать результат',
      'copied': 'Скопировано',
      'selectUnit': 'Выбрать единицу',
      'quickReference': 'Быстрый справочник',
      'lastLabel': 'Последнее: ',
      'enterPositiveValue': 'Введите значение больше нуля',
      'todayShift': 'СМЕНА СЕГОДНЯ',
      'records': 'ЗАПИСИ',
      'today': 'Сегодня',
      'yesterday': 'Вчера',
      'sevenDays': '7 дней',
      'filterByIsotope': 'Фильтр по изотопу',
      'allIsotopes': 'Все изотопы',
      'noFilter': 'Фильтр не активен',
      'avgRemainingAct': 'Средняя остаточная активность',
      'shiftNotStarted': 'Смена ещё не началась',
      'shiftNotStartedSub': 'Рассчитайте распад, чтобы начать запись активности смены.',
      'goToDecay': 'Перейти к Распаду',
      'lowActivity': 'Низкая активность',
      'initialLabel': 'Начальная: ',
      'todayUpper': 'СЕГОДНЯ',
      'yesterdayUpper': 'ВЧЕРА',
      'newCalculation': 'Новый расчёт',
      'confirmIsotope': 'Подтвердить изотоп',
      'initialDate': 'Начальная дата',
      'modify': 'Изменить',
      'elapsedTime': 'Прошедшее время',
      'activityUnit': 'Единица активности',
      'selectIsotope': 'Выбрать изотоп',
      'recent': 'НЕДАВНИЕ',
      'dateLabel': 'Дата',
      'timeLabel': 'Время',
      'now': 'Сейчас',
      'calculateResidual': 'Рассчитать остаточную активность',
      'recordedInShift': 'Записано в смену',
      'remainingActivity': 'ОСТАТОЧНАЯ АКТИВНОСТЬ',
      'autoCalculated': 'Рассчитано автоматически · ',
    },
  };
}

class SupportedLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
  Locale get locale => Locale(code);
}

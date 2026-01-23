import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================
// I18N SERVICE - Višejezična podrška
// ============================================

enum Language { hr, en, de }

class I18nService extends ChangeNotifier {
  static const String _storageKey = 'aura_language';

  Language _currentLanguage = Language.hr;

  Language get currentLanguage => _currentLanguage;

  // Lista podržanih jezika s zastavama
  static const List<Map<String, dynamic>> supportedLanguages = [
    {'code': Language.hr, 'name': 'Hrvatski', 'flag': '🇭🇷'},
    {'code': Language.en, 'name': 'English', 'flag': '🇬🇧'},
    {'code': Language.de, 'name': 'Deutsch', 'flag': '🇩🇪'},
  ];

  // Inicijalizacija - učitaj spremljeni jezik ili detektiraj
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_storageKey);

    if (savedLang != null) {
      _currentLanguage = Language.values.firstWhere(
        (l) => l.name == savedLang,
        orElse: () => _detectLanguage(),
      );
    } else {
      _currentLanguage = _detectLanguage();
    }
    notifyListeners();
  }

  // Detekcija jezika iz sustava
  Language _detectLanguage() {
    final locale = PlatformDispatcher.instance.locale;
    final langCode = locale.languageCode.toLowerCase();

    if (langCode.startsWith('hr')) return Language.hr;
    if (langCode.startsWith('de')) return Language.de;
    return Language.en;
  }

  // Postavi jezik i spremi
  Future<void> setLanguage(Language lang) async {
    if (_currentLanguage == lang) return;

    _currentLanguage = lang;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, lang.name);
  }

  // Dohvati prijevod
  String t(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }

  // ============================================
  // PRIJEVODI
  // ============================================
  static final Map<Language, Map<String, String>> _translations = {
    Language.hr: {
      // Navigation
      'nav.home': 'Početna',
      'nav.menu': 'Menu',
      'nav.reservation': 'Rezervacija',

      // Home screen
      'home.season': 'Zagreb — Sezona 2026',
      'home.heroTitle': 'Okusi tišine.',
      'home.philosophy': 'FILOZOFIJA',
      'home.philosophyTitle': 'Minimalizam na tanjuru,\nmaksimalizam u okusu.',
      'home.philosophyText': 'Aura nije samo restoran, već putovanje kroz osjetila. Svaka namirnica u sezoni 2026. pažljivo je odabrana s lokalnih OPG-ova, tretirana s poštovanjem i pretvorena u umjetnost.',
      'home.hours': 'Radno vrijeme',
      'home.hoursValue': 'Uto - Sub\n18:00 - 00:00',
      'home.location': 'Lokacija',
      'home.locationValue': 'Trg Kralja\nTomislava 1',

      // Menu screen
      'menu.title': 'MENU',
      'menu.subtitle': 'Degustacijski Menu — Sezona 2026',
      'menu.tryAgain': 'Pokušaj ponovo',
      'menu.add': 'Dodaj',
      'menu.added': 'dodano',
      'menu.cart': 'KOŠARICA',
      'menu.cartEmpty': 'Košarica je prazna',
      'menu.item': 'stavka',
      'menu.items2to4': 'stavke',
      'menu.items5plus': 'stavki',
      'menu.emptyCartTitle': 'Košarica je prazna',
      'menu.emptyCartSubtitle': 'Dodajte jela iz menija',
      'menu.browseMenu': 'PREGLEDAJ MENU',
      'menu.yourOrder': 'VAŠA NARUDŽBA',
      'menu.deliveryData': 'PODACI ZA DOSTAVU',
      'menu.name': 'Ime i prezime',
      'menu.phone': 'Broj telefona',
      'menu.address': 'Adresa dostave',
      'menu.note': 'Napomena (opcionalno)',
      'menu.totalItems': 'Ukupno stavki',
      'menu.delivery': 'Dostava',
      'menu.free': 'Besplatno',
      'menu.total': 'UKUPNO',
      'menu.order': 'NARUČI',
      'menu.clear': 'Isprazni',
      'menu.success': 'USPJEŠNO',
      'menu.orderReceived': 'Narudžba zaprimljena!',
      'menu.thankYou': 'Hvala',
      'menu.deliveredTo': 'Vaša narudžba će biti dostavljena na:',
      'menu.ok': 'U REDU',
      'menu.enterName': 'Molimo unesite ime i prezime',
      'menu.enterPhone': 'Molimo unesite broj telefona',
      'menu.enterAddress': 'Molimo unesite adresu dostave',
      'menu.orderError': 'Greška pri slanju narudžbe',

      // Reservation screen
      'reservation.title': 'REZERVACIJA',
      'reservation.logout': 'Odjava',
      'reservation.register': 'Registracija',
      'reservation.login': 'Prijava',
      'reservation.createAccount': 'Kreirajte račun',
      'reservation.enterData': 'Unesite svoje podatke za rezervaciju',
      'reservation.email': 'Email adresa',
      'reservation.password': 'Lozinka',
      'reservation.registerButton': 'REGISTRIRAJ SE',
      'reservation.haveAccount': 'Već imate račun? ',
      'reservation.loginLink': 'Prijavite se',
      'reservation.welcomeBack': 'Dobro došli natrag',
      'reservation.loginToContinue': 'Prijavite se za nastavak rezervacije',
      'reservation.loginButton': 'PRIJAVI SE',
      'reservation.noAccount': 'Nemate račun? ',
      'reservation.registerLink': 'Registrirajte se',
      'reservation.welcome': 'Dobro došli,',
      'reservation.readyToBook': 'Spremni ste za rezervaciju',
      'reservation.selectDate': 'ODABERITE DATUM',
      'reservation.selectTime': 'ODABERITE TERMIN',
      'reservation.guests': 'BROJ GOSTIJU',
      'reservation.notes': 'POSEBNE NAPOMENE',
      'reservation.notesPlaceholder': 'Alergije, posebni zahtjevi...',
      'reservation.pricePerPerson': 'CIJENA PO OSOBI',
      'reservation.confirmButton': 'POTVRDI REZERVACIJU',
      'reservation.loading': 'Učitavam termine...',
      'reservation.closed': 'Zatvoreno',
      'reservation.closedDefault': 'Restoran ne radi ovaj dan',
      'reservation.noSlots': 'Nema dostupnih termina',
      'reservation.workingHours': 'Radno vrijeme:',
      'reservation.available': 'Slobodno',
      'reservation.full': 'Popunjeno',
      'reservation.person': 'osoba',
      'reservation.persons2to4': 'osobe',
      'reservation.persons5plus': 'osoba',
      'reservation.successTitle': 'USPJEŠNO',
      'reservation.confirmed': 'Rezervacija potvrđena!',
      'reservation.date': 'Datum',
      'reservation.arrival': 'Dolazak',
      'reservation.departure': 'Odlazak',
      'reservation.guestsLabel': 'Gosti',
      'reservation.totalLabel': 'Ukupno',
      'reservation.emailConfirm': 'Potvrdu ćete primiti na email.',
      'reservation.backHome': 'NATRAG NA POČETNU',
      'reservation.selectSlot': 'Molimo odaberite termin',
      'reservation.fillAll': 'Molimo ispunite sva polja',
      'reservation.registerSuccess': 'Uspješna registracija!',
      'reservation.registerError': 'Greška pri registraciji',
      'reservation.enterEmailPassword': 'Molimo unesite email i lozinku',
      'reservation.loginSuccess': 'Uspješna prijava!',
      'reservation.loginError': 'Pogrešan email ili lozinka',
      'reservation.bookingError': 'Greška pri rezervaciji',
      'reservation.price': 'Cijena:',

      // Days
      'day.monday': 'Ponedjeljak',
      'day.tuesday': 'Utorak',
      'day.wednesday': 'Srijeda',
      'day.thursday': 'Četvrtak',
      'day.friday': 'Petak',
      'day.saturday': 'Subota',
      'day.sunday': 'Nedjelja',

      // Months
      'month.january': 'Siječanj',
      'month.february': 'Veljača',
      'month.march': 'Ožujak',
      'month.april': 'Travanj',
      'month.may': 'Svibanj',
      'month.june': 'Lipanj',
      'month.july': 'Srpanj',
      'month.august': 'Kolovoz',
      'month.september': 'Rujan',
      'month.october': 'Listopad',
      'month.november': 'Studeni',
      'month.december': 'Prosinac',
    },

    Language.en: {
      // Navigation
      'nav.home': 'Home',
      'nav.menu': 'Menu',
      'nav.reservation': 'Reservation',

      // Home screen
      'home.season': 'Zagreb — Season 2026',
      'home.heroTitle': 'Taste the silence.',
      'home.philosophy': 'PHILOSOPHY',
      'home.philosophyTitle': 'Minimalism on the plate,\nmaximalism in taste.',
      'home.philosophyText': 'Aura is not just a restaurant, but a journey through the senses. Every ingredient in season 2026 is carefully selected from local farms, treated with respect and transformed into art.',
      'home.hours': 'Opening hours',
      'home.hoursValue': 'Tue - Sat\n18:00 - 00:00',
      'home.location': 'Location',
      'home.locationValue': 'King Tomislav\nSquare 1',

      // Menu screen
      'menu.title': 'MENU',
      'menu.subtitle': 'Tasting Menu — Season 2026',
      'menu.tryAgain': 'Try again',
      'menu.add': 'Add',
      'menu.added': 'added',
      'menu.cart': 'CART',
      'menu.cartEmpty': 'Cart is empty',
      'menu.item': 'item',
      'menu.items2to4': 'items',
      'menu.items5plus': 'items',
      'menu.emptyCartTitle': 'Cart is empty',
      'menu.emptyCartSubtitle': 'Add dishes from the menu',
      'menu.browseMenu': 'BROWSE MENU',
      'menu.yourOrder': 'YOUR ORDER',
      'menu.deliveryData': 'DELIVERY INFORMATION',
      'menu.name': 'Full name',
      'menu.phone': 'Phone number',
      'menu.address': 'Delivery address',
      'menu.note': 'Note (optional)',
      'menu.totalItems': 'Total items',
      'menu.delivery': 'Delivery',
      'menu.free': 'Free',
      'menu.total': 'TOTAL',
      'menu.order': 'ORDER',
      'menu.clear': 'Clear',
      'menu.success': 'SUCCESS',
      'menu.orderReceived': 'Order received!',
      'menu.thankYou': 'Thank you',
      'menu.deliveredTo': 'Your order will be delivered to:',
      'menu.ok': 'OK',
      'menu.enterName': 'Please enter your full name',
      'menu.enterPhone': 'Please enter your phone number',
      'menu.enterAddress': 'Please enter delivery address',
      'menu.orderError': 'Error sending order',

      // Reservation screen
      'reservation.title': 'RESERVATION',
      'reservation.logout': 'Logout',
      'reservation.register': 'Register',
      'reservation.login': 'Login',
      'reservation.createAccount': 'Create account',
      'reservation.enterData': 'Enter your details for reservation',
      'reservation.email': 'Email address',
      'reservation.password': 'Password',
      'reservation.registerButton': 'REGISTER',
      'reservation.haveAccount': 'Already have an account? ',
      'reservation.loginLink': 'Log in',
      'reservation.welcomeBack': 'Welcome back',
      'reservation.loginToContinue': 'Log in to continue with reservation',
      'reservation.loginButton': 'LOG IN',
      'reservation.noAccount': "Don't have an account? ",
      'reservation.registerLink': 'Register',
      'reservation.welcome': 'Welcome,',
      'reservation.readyToBook': 'Ready to book',
      'reservation.selectDate': 'SELECT DATE',
      'reservation.selectTime': 'SELECT TIME',
      'reservation.guests': 'NUMBER OF GUESTS',
      'reservation.notes': 'SPECIAL NOTES',
      'reservation.notesPlaceholder': 'Allergies, special requests...',
      'reservation.pricePerPerson': 'PRICE PER PERSON',
      'reservation.confirmButton': 'CONFIRM RESERVATION',
      'reservation.loading': 'Loading slots...',
      'reservation.closed': 'Closed',
      'reservation.closedDefault': 'Restaurant is closed this day',
      'reservation.noSlots': 'No available slots',
      'reservation.workingHours': 'Opening hours:',
      'reservation.available': 'Available',
      'reservation.full': 'Full',
      'reservation.person': 'person',
      'reservation.persons2to4': 'people',
      'reservation.persons5plus': 'people',
      'reservation.successTitle': 'SUCCESS',
      'reservation.confirmed': 'Reservation confirmed!',
      'reservation.date': 'Date',
      'reservation.arrival': 'Arrival',
      'reservation.departure': 'Departure',
      'reservation.guestsLabel': 'Guests',
      'reservation.totalLabel': 'Total',
      'reservation.emailConfirm': 'Confirmation will be sent to your email.',
      'reservation.backHome': 'BACK TO HOME',
      'reservation.selectSlot': 'Please select a time slot',
      'reservation.fillAll': 'Please fill in all fields',
      'reservation.registerSuccess': 'Registration successful!',
      'reservation.registerError': 'Registration error',
      'reservation.enterEmailPassword': 'Please enter email and password',
      'reservation.loginSuccess': 'Login successful!',
      'reservation.loginError': 'Incorrect email or password',
      'reservation.bookingError': 'Booking error',
      'reservation.price': 'Price:',

      // Days
      'day.monday': 'Monday',
      'day.tuesday': 'Tuesday',
      'day.wednesday': 'Wednesday',
      'day.thursday': 'Thursday',
      'day.friday': 'Friday',
      'day.saturday': 'Saturday',
      'day.sunday': 'Sunday',

      // Months
      'month.january': 'January',
      'month.february': 'February',
      'month.march': 'March',
      'month.april': 'April',
      'month.may': 'May',
      'month.june': 'June',
      'month.july': 'July',
      'month.august': 'August',
      'month.september': 'September',
      'month.october': 'October',
      'month.november': 'November',
      'month.december': 'December',
    },

    Language.de: {
      // Navigation
      'nav.home': 'Startseite',
      'nav.menu': 'Menü',
      'nav.reservation': 'Reservierung',

      // Home screen
      'home.season': 'Zagreb — Saison 2026',
      'home.heroTitle': 'Geschmack der Stille.',
      'home.philosophy': 'PHILOSOPHIE',
      'home.philosophyTitle': 'Minimalismus auf dem Teller,\nMaximalismus im Geschmack.',
      'home.philosophyText': 'Aura ist nicht nur ein Restaurant, sondern eine Reise durch die Sinne. Jede Zutat in der Saison 2026 wird sorgfältig von lokalen Bauernhöfen ausgewählt, mit Respekt behandelt und in Kunst verwandelt.',
      'home.hours': 'Öffnungszeiten',
      'home.hoursValue': 'Di - Sa\n18:00 - 00:00',
      'home.location': 'Standort',
      'home.locationValue': 'König-Tomislav-\nPlatz 1',

      // Menu screen
      'menu.title': 'MENÜ',
      'menu.subtitle': 'Degustationsmenü — Saison 2026',
      'menu.tryAgain': 'Erneut versuchen',
      'menu.add': 'Hinzufügen',
      'menu.added': 'hinzugefügt',
      'menu.cart': 'WARENKORB',
      'menu.cartEmpty': 'Warenkorb ist leer',
      'menu.item': 'Artikel',
      'menu.items2to4': 'Artikel',
      'menu.items5plus': 'Artikel',
      'menu.emptyCartTitle': 'Warenkorb ist leer',
      'menu.emptyCartSubtitle': 'Fügen Sie Gerichte aus dem Menü hinzu',
      'menu.browseMenu': 'MENÜ DURCHSUCHEN',
      'menu.yourOrder': 'IHRE BESTELLUNG',
      'menu.deliveryData': 'LIEFERINFORMATIONEN',
      'menu.name': 'Vollständiger Name',
      'menu.phone': 'Telefonnummer',
      'menu.address': 'Lieferadresse',
      'menu.note': 'Anmerkung (optional)',
      'menu.totalItems': 'Artikel insgesamt',
      'menu.delivery': 'Lieferung',
      'menu.free': 'Kostenlos',
      'menu.total': 'GESAMT',
      'menu.order': 'BESTELLEN',
      'menu.clear': 'Leeren',
      'menu.success': 'ERFOLG',
      'menu.orderReceived': 'Bestellung eingegangen!',
      'menu.thankYou': 'Danke',
      'menu.deliveredTo': 'Ihre Bestellung wird geliefert an:',
      'menu.ok': 'OK',
      'menu.enterName': 'Bitte geben Sie Ihren Namen ein',
      'menu.enterPhone': 'Bitte geben Sie Ihre Telefonnummer ein',
      'menu.enterAddress': 'Bitte geben Sie die Lieferadresse ein',
      'menu.orderError': 'Fehler beim Senden der Bestellung',

      // Reservation screen
      'reservation.title': 'RESERVIERUNG',
      'reservation.logout': 'Abmelden',
      'reservation.register': 'Registrieren',
      'reservation.login': 'Anmelden',
      'reservation.createAccount': 'Konto erstellen',
      'reservation.enterData': 'Geben Sie Ihre Daten für die Reservierung ein',
      'reservation.email': 'E-Mail-Adresse',
      'reservation.password': 'Passwort',
      'reservation.registerButton': 'REGISTRIEREN',
      'reservation.haveAccount': 'Haben Sie bereits ein Konto? ',
      'reservation.loginLink': 'Anmelden',
      'reservation.welcomeBack': 'Willkommen zurück',
      'reservation.loginToContinue': 'Melden Sie sich an, um mit der Reservierung fortzufahren',
      'reservation.loginButton': 'ANMELDEN',
      'reservation.noAccount': 'Kein Konto? ',
      'reservation.registerLink': 'Registrieren',
      'reservation.welcome': 'Willkommen,',
      'reservation.readyToBook': 'Bereit zur Reservierung',
      'reservation.selectDate': 'DATUM AUSWÄHLEN',
      'reservation.selectTime': 'ZEIT AUSWÄHLEN',
      'reservation.guests': 'ANZAHL DER GÄSTE',
      'reservation.notes': 'BESONDERE HINWEISE',
      'reservation.notesPlaceholder': 'Allergien, besondere Wünsche...',
      'reservation.pricePerPerson': 'PREIS PRO PERSON',
      'reservation.confirmButton': 'RESERVIERUNG BESTÄTIGEN',
      'reservation.loading': 'Lade Zeitfenster...',
      'reservation.closed': 'Geschlossen',
      'reservation.closedDefault': 'Restaurant ist an diesem Tag geschlossen',
      'reservation.noSlots': 'Keine verfügbaren Zeitfenster',
      'reservation.workingHours': 'Öffnungszeiten:',
      'reservation.available': 'Verfügbar',
      'reservation.full': 'Voll',
      'reservation.person': 'Person',
      'reservation.persons2to4': 'Personen',
      'reservation.persons5plus': 'Personen',
      'reservation.successTitle': 'ERFOLG',
      'reservation.confirmed': 'Reservierung bestätigt!',
      'reservation.date': 'Datum',
      'reservation.arrival': 'Ankunft',
      'reservation.departure': 'Abreise',
      'reservation.guestsLabel': 'Gäste',
      'reservation.totalLabel': 'Gesamt',
      'reservation.emailConfirm': 'Bestätigung wird per E-Mail gesendet.',
      'reservation.backHome': 'ZURÜCK ZUR STARTSEITE',
      'reservation.selectSlot': 'Bitte wählen Sie ein Zeitfenster',
      'reservation.fillAll': 'Bitte füllen Sie alle Felder aus',
      'reservation.registerSuccess': 'Registrierung erfolgreich!',
      'reservation.registerError': 'Registrierungsfehler',
      'reservation.enterEmailPassword': 'Bitte E-Mail und Passwort eingeben',
      'reservation.loginSuccess': 'Anmeldung erfolgreich!',
      'reservation.loginError': 'Falsche E-Mail oder Passwort',
      'reservation.bookingError': 'Buchungsfehler',
      'reservation.price': 'Preis:',

      // Days
      'day.monday': 'Montag',
      'day.tuesday': 'Dienstag',
      'day.wednesday': 'Mittwoch',
      'day.thursday': 'Donnerstag',
      'day.friday': 'Freitag',
      'day.saturday': 'Samstag',
      'day.sunday': 'Sonntag',

      // Months
      'month.january': 'Januar',
      'month.february': 'Februar',
      'month.march': 'März',
      'month.april': 'April',
      'month.may': 'Mai',
      'month.june': 'Juni',
      'month.july': 'Juli',
      'month.august': 'August',
      'month.september': 'September',
      'month.october': 'Oktober',
      'month.november': 'November',
      'month.december': 'Dezember',
    },
  };

  // Pomoćne metode za nazive dana i mjeseci
  String getDayName(int weekday) {
    final days = [
      '',
      t('day.monday'),
      t('day.tuesday'),
      t('day.wednesday'),
      t('day.thursday'),
      t('day.friday'),
      t('day.saturday'),
      t('day.sunday'),
    ];
    return days[weekday];
  }

  String getMonthName(int month) {
    final months = [
      '',
      t('month.january'),
      t('month.february'),
      t('month.march'),
      t('month.april'),
      t('month.may'),
      t('month.june'),
      t('month.july'),
      t('month.august'),
      t('month.september'),
      t('month.october'),
      t('month.november'),
      t('month.december'),
    ];
    return months[month];
  }

  // Pravilna množina za različite jezike
  String getGuestText(int count) {
    if (_currentLanguage == Language.hr) {
      if (count == 1) return '$count ${t('reservation.person')}';
      if (count >= 2 && count <= 4) return '$count ${t('reservation.persons2to4')}';
      return '$count ${t('reservation.persons5plus')}';
    } else if (_currentLanguage == Language.de) {
      return count == 1 ? '$count ${t('reservation.person')}' : '$count ${t('reservation.persons2to4')}';
    } else {
      return count == 1 ? '$count ${t('reservation.person')}' : '$count ${t('reservation.persons2to4')}';
    }
  }

  String getItemText(int count) {
    if (_currentLanguage == Language.hr) {
      if (count == 1) return '$count ${t('menu.item')}';
      if (count >= 2 && count <= 4) return '$count ${t('menu.items2to4')}';
      return '$count ${t('menu.items5plus')}';
    } else {
      return count == 1 ? '$count ${t('menu.item')}' : '$count ${t('menu.items2to4')}';
    }
  }
}

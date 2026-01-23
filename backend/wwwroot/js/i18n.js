// Aura Fine Dining - Internationalization (i18n)
const translations = {
  hr: {
    // Navigation
    menu: 'Menu',
    reservation: 'Rezervacija',
    contact: 'Kontakt',

    // Home
    season: 'Zagreb — Sezona 2026',
    heroTitle: 'Okusi tišine.',
    ctaButton: 'Rezervirajte svoj stol',
    philosophy: 'Filozofija',
    philosophyTitle: 'Minimalizam na tanjuru, <br>maksimalizam u okusu.',
    philosophyText: 'Aura nije samo restoran, već putovanje kroz osjetila. Svaka namirnica u sezoni 2026. pažljivo je odabrana s lokalnih OPG-ova, tretirana s poštovanjem i pretvorena u umjetnost.',
    exploreStory: 'Istražite našu priču',
    quote: '"Hrana koja priča priču o zemlji, moru i ljudima."',
    joinUs: 'Pridružite nam se',
    secureSpot: 'Osigurajte termin',
    address: 'Trg Kralja Tomislava 1, Zagreb',
    hours: 'Utorak - Subota, 18:00 - 00:00',
    copyright: '© 2026 Aura Fine Dining. Sva prava pridržana.',

    // Menu
    menuTitle: 'Degustacijski Menu',
    menuSubtitle: 'Sedam sljedova koji slave lokalnu zemlju, more i tradiciju.',
    deliveryAvailable: 'Dostava dostupna',
    orderFavorites: 'Naručite svoja omiljena jela',
    starters: 'Predjela',
    mainCourses: 'Glavna jela',
    desserts: 'Deserti',
    drinks: 'Pića',
    addToCart: 'Dodaj',
    cart: 'Košarica',
    emptyCart: 'Košarica je prazna',
    total: 'Ukupno',
    orderDelivery: 'Naruči dostavu',

    // Reservation
    reservationTitle: 'Rezervacija',
    selectDate: 'Odaberite datum',
    selectTime: 'Odaberite termin',
    guests: 'Broj gostiju',
    specialRequests: 'Posebni zahtjevi (opcionalno)',
    specialRequestsHint: 'Alergije, posebne prigode...',
    pricePerPerson: 'Cijena po osobi',
    totalPrice: 'Ukupno',
    confirmReservation: 'Potvrdi rezervaciju',
    available: 'Dostupno',
    limited: 'Ograničeno',
    full: 'Popunjeno',
    closed: 'Zatvoreno',
    free: 'Slobodno',

    // Auth
    login: 'Prijava',
    register: 'Registracija',
    loginSubtitle: 'Prijavite se za nastavak',
    registerSubtitle: 'Kreirajte račun za rezervacije',
    email: 'Email adresa',
    password: 'Lozinka',
    fullName: 'Ime i prezime',
    phone: 'Telefon',
    passwordHint: 'Lozinka (min 6 znakova)',
    noAccount: 'Nemate račun?',
    hasAccount: 'Imate račun?',

    // Contact
    contactTitle: 'Kontakt',
    visitUs: 'Posjetite nas',
    writeUs: 'Pišite nam',
    callUs: 'Nazovite nas',

    // Checkout
    checkoutTitle: 'Dostava',
    deliveryAddress: 'Adresa dostave',
    street: 'Ulica i kućni broj',
    city: 'Grad',
    note: 'Napomena',
    noteHint: 'Alergije, posebni zahtjevi...',
    order: 'Naruči',

    // Days
    mon: 'Pon', tue: 'Uto', wed: 'Sri', thu: 'Čet', fri: 'Pet', sat: 'Sub', sun: 'Ned',

    // Months
    january: 'Siječanj', february: 'Veljača', march: 'Ožujak', april: 'Travanj',
    may: 'Svibanj', june: 'Lipanj', july: 'Srpanj', august: 'Kolovoz',
    september: 'Rujan', october: 'Listopad', november: 'Studeni', december: 'Prosinac'
  },
  en: {
    // Navigation
    menu: 'Menu',
    reservation: 'Reservation',
    contact: 'Contact',

    // Home
    season: 'Zagreb — Season 2026',
    heroTitle: 'Taste the silence.',
    ctaButton: 'Reserve your table',
    philosophy: 'Philosophy',
    philosophyTitle: 'Minimalism on the plate, <br>maximalism in taste.',
    philosophyText: 'Aura is not just a restaurant, but a journey through the senses. Every ingredient in the 2026 season is carefully selected from local farms, treated with respect and transformed into art.',
    exploreStory: 'Explore our story',
    quote: '"Food that tells a story of land, sea and people."',
    joinUs: 'Join us',
    secureSpot: 'Secure your spot',
    address: 'King Tomislav Square 1, Zagreb',
    hours: 'Tuesday - Saturday, 6:00 PM - 12:00 AM',
    copyright: '© 2026 Aura Fine Dining. All rights reserved.',

    // Menu
    menuTitle: 'Tasting Menu',
    menuSubtitle: 'Seven courses celebrating local land, sea and tradition.',
    deliveryAvailable: 'Delivery available',
    orderFavorites: 'Order your favorite dishes',
    starters: 'Starters',
    mainCourses: 'Main courses',
    desserts: 'Desserts',
    drinks: 'Drinks',
    addToCart: 'Add',
    cart: 'Cart',
    emptyCart: 'Cart is empty',
    total: 'Total',
    orderDelivery: 'Order delivery',

    // Reservation
    reservationTitle: 'Reservation',
    selectDate: 'Select date',
    selectTime: 'Select time',
    guests: 'Number of guests',
    specialRequests: 'Special requests (optional)',
    specialRequestsHint: 'Allergies, special occasions...',
    pricePerPerson: 'Price per person',
    totalPrice: 'Total',
    confirmReservation: 'Confirm reservation',
    available: 'Available',
    limited: 'Limited',
    full: 'Full',
    closed: 'Closed',
    free: 'Free',

    // Auth
    login: 'Login',
    register: 'Register',
    loginSubtitle: 'Log in to continue',
    registerSubtitle: 'Create an account for reservations',
    email: 'Email address',
    password: 'Password',
    fullName: 'Full name',
    phone: 'Phone',
    passwordHint: 'Password (min 6 characters)',
    noAccount: "Don't have an account?",
    hasAccount: 'Already have an account?',

    // Contact
    contactTitle: 'Contact',
    visitUs: 'Visit us',
    writeUs: 'Write to us',
    callUs: 'Call us',

    // Checkout
    checkoutTitle: 'Delivery',
    deliveryAddress: 'Delivery address',
    street: 'Street and number',
    city: 'City',
    note: 'Note',
    noteHint: 'Allergies, special requests...',
    order: 'Order',

    // Days
    mon: 'Mon', tue: 'Tue', wed: 'Wed', thu: 'Thu', fri: 'Fri', sat: 'Sat', sun: 'Sun',

    // Months
    january: 'January', february: 'February', march: 'March', april: 'April',
    may: 'May', june: 'June', july: 'July', august: 'August',
    september: 'September', october: 'October', november: 'November', december: 'December'
  },
  de: {
    // Navigation
    menu: 'Speisekarte',
    reservation: 'Reservierung',
    contact: 'Kontakt',

    // Home
    season: 'Zagreb — Saison 2026',
    heroTitle: 'Schmecke die Stille.',
    ctaButton: 'Reservieren Sie Ihren Tisch',
    philosophy: 'Philosophie',
    philosophyTitle: 'Minimalismus auf dem Teller, <br>Maximalismus im Geschmack.',
    philosophyText: 'Aura ist nicht nur ein Restaurant, sondern eine Reise durch die Sinne. Jede Zutat der Saison 2026 wird sorgfältig von lokalen Bauernhöfen ausgewählt, mit Respekt behandelt und in Kunst verwandelt.',
    exploreStory: 'Entdecken Sie unsere Geschichte',
    quote: '"Essen, das eine Geschichte von Land, Meer und Menschen erzählt."',
    joinUs: 'Besuchen Sie uns',
    secureSpot: 'Sichern Sie sich Ihren Platz',
    address: 'König-Tomislav-Platz 1, Zagreb',
    hours: 'Dienstag - Samstag, 18:00 - 00:00',
    copyright: '© 2026 Aura Fine Dining. Alle Rechte vorbehalten.',

    // Menu
    menuTitle: 'Degustationsmenü',
    menuSubtitle: 'Sieben Gänge, die Land, Meer und Tradition feiern.',
    deliveryAvailable: 'Lieferung verfügbar',
    orderFavorites: 'Bestellen Sie Ihre Lieblingsgerichte',
    starters: 'Vorspeisen',
    mainCourses: 'Hauptgerichte',
    desserts: 'Desserts',
    drinks: 'Getränke',
    addToCart: 'Hinzufügen',
    cart: 'Warenkorb',
    emptyCart: 'Warenkorb ist leer',
    total: 'Gesamt',
    orderDelivery: 'Lieferung bestellen',

    // Reservation
    reservationTitle: 'Reservierung',
    selectDate: 'Datum wählen',
    selectTime: 'Zeit wählen',
    guests: 'Anzahl der Gäste',
    specialRequests: 'Besondere Wünsche (optional)',
    specialRequestsHint: 'Allergien, besondere Anlässe...',
    pricePerPerson: 'Preis pro Person',
    totalPrice: 'Gesamt',
    confirmReservation: 'Reservierung bestätigen',
    available: 'Verfügbar',
    limited: 'Begrenzt',
    full: 'Voll',
    closed: 'Geschlossen',
    free: 'Frei',

    // Auth
    login: 'Anmelden',
    register: 'Registrieren',
    loginSubtitle: 'Melden Sie sich an, um fortzufahren',
    registerSubtitle: 'Erstellen Sie ein Konto für Reservierungen',
    email: 'E-Mail-Adresse',
    password: 'Passwort',
    fullName: 'Vollständiger Name',
    phone: 'Telefon',
    passwordHint: 'Passwort (mind. 6 Zeichen)',
    noAccount: 'Noch kein Konto?',
    hasAccount: 'Bereits ein Konto?',

    // Contact
    contactTitle: 'Kontakt',
    visitUs: 'Besuchen Sie uns',
    writeUs: 'Schreiben Sie uns',
    callUs: 'Rufen Sie uns an',

    // Checkout
    checkoutTitle: 'Lieferung',
    deliveryAddress: 'Lieferadresse',
    street: 'Straße und Hausnummer',
    city: 'Stadt',
    note: 'Anmerkung',
    noteHint: 'Allergien, besondere Wünsche...',
    order: 'Bestellen',

    // Days
    mon: 'Mo', tue: 'Di', wed: 'Mi', thu: 'Do', fri: 'Fr', sat: 'Sa', sun: 'So',

    // Months
    january: 'Januar', february: 'Februar', march: 'März', april: 'April',
    may: 'Mai', june: 'Juni', july: 'Juli', august: 'August',
    september: 'September', october: 'Oktober', november: 'November', december: 'Dezember'
  }
};

// i18n Manager
const i18n = {
  currentLang: 'hr',

  init() {
    // Check localStorage first
    const saved = localStorage.getItem('aura_language');
    if (saved && translations[saved]) {
      this.currentLang = saved;
    } else {
      // Detect from browser
      const browserLang = navigator.language.split('-')[0].toLowerCase();
      if (browserLang === 'hr' || browserLang === 'bs' || browserLang === 'sr') {
        this.currentLang = 'hr';
      } else if (browserLang === 'de' || browserLang === 'at' || browserLang === 'ch') {
        this.currentLang = 'de';
      } else {
        this.currentLang = 'en';
      }
    }

    this.updatePage();
    this.createLanguageSelector();
  },

  setLanguage(lang) {
    if (translations[lang]) {
      this.currentLang = lang;
      localStorage.setItem('aura_language', lang);
      this.updatePage();
    }
  },

  t(key) {
    return translations[this.currentLang][key] || translations['hr'][key] || key;
  },

  updatePage() {
    // Update all elements with data-i18n attribute
    document.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.getAttribute('data-i18n');
      const translation = this.t(key);
      if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
        el.placeholder = translation;
      } else {
        el.innerHTML = translation;
      }
    });

    // Update HTML lang attribute
    document.documentElement.lang = this.currentLang;

    // Update language selector
    document.querySelectorAll('.lang-btn').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.lang === this.currentLang);
    });
  },

  createLanguageSelector() {
    // Find or create language selector container
    let selector = document.getElementById('language-selector');
    if (!selector) {
      selector = document.createElement('div');
      selector.id = 'language-selector';
      selector.className = 'fixed bottom-6 right-6 z-[100] flex gap-2 bg-white/90 backdrop-blur-md p-1.5 rounded-full shadow-lg';
      document.body.appendChild(selector);
    }

    selector.innerHTML = `
      <button class="lang-btn w-8 h-8 rounded-full flex items-center justify-center text-lg transition-all ${this.currentLang === 'hr' ? 'bg-stone-900 scale-110' : ''}" data-lang="hr" onclick="i18n.setLanguage('hr')">🇭🇷</button>
      <button class="lang-btn w-8 h-8 rounded-full flex items-center justify-center text-lg transition-all ${this.currentLang === 'en' ? 'bg-stone-900 scale-110' : ''}" data-lang="en" onclick="i18n.setLanguage('en')">🇬🇧</button>
      <button class="lang-btn w-8 h-8 rounded-full flex items-center justify-center text-lg transition-all ${this.currentLang === 'de' ? 'bg-stone-900 scale-110' : ''}" data-lang="de" onclick="i18n.setLanguage('de')">🇩🇪</button>
    `;
  }
};

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => i18n.init());

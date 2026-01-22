import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/availability_calendar.dart';

// ============================================
// RESERVATION SCREEN - Stranica za rezervacije
// ============================================
class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen>
    with SingleTickerProviderStateMixin {
  // Kontroleri za tekst polja
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _noteController = TextEditingController();

  // Tab controller za animacije
  late TabController _tabController;

  // Varijable stanja
  DateTime _selectedDate = DateTime.now(); // Auto-select danas
  String? _selectedSlotTime;
  int _guests = 2;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _userName;

  // Dinamički slotovi iz API-ja
  bool _isLoadingSlots = false;
  bool _isClosed = false;
  String? _closedReason;
  String? _openTime;
  String? _closeTime;

  // Hrvatski nazivi mjeseci
  final List<String> _monthNames = [
    '', 'Siječanj', 'Veljača', 'Ožujak', 'Travanj', 'Svibanj', 'Lipanj',
    'Srpanj', 'Kolovoz', 'Rujan', 'Listopad', 'Studeni', 'Prosinac'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkLoginStatus();
    _loadAvailableSlots(); // Učitaj slotove za početni datum
  }

  // Svi termini (i zauzeti) za prikaz
  List<Map<String, dynamic>> _allSlots = [];

  // Učitaj dostupne termine za odabrani datum
  Future<void> _loadAvailableSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _allSlots = [];
      _selectedSlotTime = null;
      _isClosed = false;
      _closedReason = null;
    });

    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final response = await ApiService.getAvailableSlots(dateStr);

    if (response.success && response.data != null) {
      final data = response.data as Map<String, dynamic>;

      if (data['isClosed'] == true) {
        setState(() {
          _isClosed = true;
          _closedReason = data['reason'] ?? 'Restoran ne radi ovaj dan';
          _isLoadingSlots = false;
        });
      } else {
        // Dostupni termini
        final slots = (data['slots'] as List<dynamic>?) ?? [];
        // Svi termini (ukljucujuci zauzete)
        final allSlotsData = (data['allSlots'] as List<dynamic>?) ?? slots;

        setState(() {
          _allSlots = allSlotsData.map((s) => {
            'time': s['time'] as String,
            'available': s['available'] as int,
            'maxReservations': s['maxReservations'] as int,
          }).toList();
          _openTime = data['openTime'];
          _closeTime = data['closeTime'];
          _isLoadingSlots = false;
        });
      }
    } else {
      setState(() {
        _isLoadingSlots = false;
        _closedReason = response.error ?? 'Greška pri učitavanju';
      });
    }
  }

  // Provjeri je li korisnik već prijavljen
  Future<void> _checkLoginStatus() async {
    // Prvo provjeri lokalno spremljenu sesiju
    if (ApiService.authToken != null) {
      setState(() {
        _isLoggedIn = true;
        _userName = ApiService.userName ?? 'Korisnik';
      });
      // Zatim verificiraj s backendom (u pozadini)
      final response = await ApiService.verifyToken();
      if (response.success) {
        // Ažuriraj ime ako je promijenjeno
        setState(() {
          _userName = ApiService.userName ?? 'Korisnik';
        });
      } else if (response.error == 'Sesija je istekla') {
        // Samo ako je 401 (sesija istekla) - odlogiraj
        setState(() {
          _isLoggedIn = false;
          _userName = null;
        });
      }
      // Ako je greška mreže ili servera - ostavi prijavljenog s lokalnim podacima
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _noteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'REZERVACIJA',
          style: TextStyle(
            letterSpacing: 8,
            fontWeight: FontWeight.w300,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (_isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1917),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: Text(
                            _userName?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Color(0xFF1C1917),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _userName ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20),
                    onPressed: _logout,
                    tooltip: 'Odjava',
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoggedIn ? _buildReservationForm() : _buildAuthForm(),
      ),
    );
  }

  // ==========================================
  // FORMA ZA PRIJAVU/REGISTRACIJU - UREĐENA
  // ==========================================
  Widget _buildAuthForm() {
    return Column(
      children: [
        const SizedBox(height: 24),

        // Elegantni tab bar - simetrični
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _tabController.animateTo(0),
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      final isSelected = _tabController.index == 0;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1C1917) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          'Registracija',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _tabController.animateTo(1),
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      final isSelected = _tabController.index == 1;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1C1917) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          'Prijava',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRegisterTab(),
              _buildLoginTab(),
            ],
          ),
        ),
      ],
    );
  }

  // Tab za registraciju
  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ikona
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.person_add_outlined, color: Colors.grey[700], size: 28),
            ),
            const SizedBox(height: 20),
            const Text(
              'Kreirajte račun',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unesite svoje podatke za rezervaciju',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 28),
            _buildTextField(
              controller: _nameController,
              label: 'Ime i prezime',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email adresa',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Broj telefona',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: 'Lozinka',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 28),
            _buildSubmitButton('REGISTRIRAJ SE', _register),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Već imate račun? ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                GestureDetector(
                  onTap: () => _tabController.animateTo(1),
                  child: const Text(
                    'Prijavite se',
                    style: TextStyle(
                      color: Color(0xFF1C1917),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tab za prijavu
  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ikona
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.login_outlined, color: Colors.grey[700], size: 28),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dobro došli natrag',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prijavite se za nastavak rezervacije',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 28),
            _buildTextField(
              controller: _emailController,
              label: 'Email adresa',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: 'Lozinka',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 28),
            _buildSubmitButton('PRIJAVI SE', _login),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Nemate račun? ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                GestureDetector(
                  onTap: () => _tabController.animateTo(0),
                  child: const Text(
                    'Registrirajte se',
                    style: TextStyle(
                      color: Color(0xFF1C1917),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // FORMA ZA REZERVACIJU
  // ==========================================
  Widget _buildReservationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pozdrav korisniku
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dobro došli, $_userName!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spremni ste za rezervaciju',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Kalendar s dostupnoscu
          _buildSectionTitle('ODABERITE DATUM'),
          const SizedBox(height: 12),
          AvailabilityCalendar(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
              _loadAvailableSlots();
            },
          ),
          const SizedBox(height: 8),
          // Prikazi odabrani datum
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1917),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_getDayName(_selectedDate.weekday)}, ${_selectedDate.day}. ${_monthNames[_selectedDate.month]} ${_selectedDate.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Vremenski slot
          _buildSectionTitle('ODABERITE TERMIN'),
          const SizedBox(height: 12),
          _buildTimeSlotPicker(),

          const SizedBox(height: 28),

          // Broj gostiju
          _buildSectionTitle('BROJ GOSTIJU'),
          const SizedBox(height: 12),
          _buildGuestSelector(),

          const SizedBox(height: 28),

          // Napomena
          _buildSectionTitle('POSEBNE NAPOMENE'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _noteController,
            label: 'Alergije, posebni zahtjevi...',
            icon: Icons.note_outlined,
            maxLines: 3,
          ),

          const SizedBox(height: 32),

          // Cijena rezervacije
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1917),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CIJENA PO OSOBI',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '95,00 EUR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'UKUPNO',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(_guests * 95).toStringAsFixed(2).replaceAll('.', ',')} EUR',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Gumb za rezervaciju
          _buildSubmitButton('POTVRDI REZERVACIJU', _submitReservation),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ==========================================
  // POMOCNE METODE
  // ==========================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 3,
        color: Colors.grey[500],
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // _buildDatePicker maknuta - koristimo AvailabilityCalendar

  String _getDayName(int weekday) {
    const days = ['', 'Ponedjeljak', 'Utorak', 'Srijeda', 'Četvrtak', 'Petak', 'Subota', 'Nedjelja'];
    return days[weekday];
  }

  Widget _buildTimeSlotPicker() {
    // Loading state
    if (_isLoadingSlots) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                color: Color(0xFF1C1917),
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Ucitavam termine...',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Closed state
    if (_isClosed) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, color: Colors.red[400], size: 40),
            const SizedBox(height: 12),
            Text(
              'Zatvoreno',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _closedReason ?? 'Restoran ne radi ovaj dan',
              style: TextStyle(color: Colors.red[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Ako nema niti jednog slota (ni zauzetog ni slobodnog)
    if (_allSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, color: Colors.grey[400], size: 40),
            const SizedBox(height: 12),
            Text(
              'Nema dostupnih termina',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Show all slots (available and full)
    return Column(
      children: [
        // Working hours info
        if (_openTime != null && _closeTime != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Radno vrijeme: $_openTime - $_closeTime',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
        // Slots grid - prikazi SVE slotove u 3 stupca kao web verzija
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _allSlots.map((slot) {
            final time = slot['time'] as String;
            final available = slot['available'] as int;
            final isAvailable = available > 0;
            final isSelected = _selectedSlotTime == time;

            return GestureDetector(
              onTap: isAvailable ? () => setState(() => _selectedSlotTime = time) : null,
              child: Container(
                width: (MediaQuery.of(context).size.width - 72) / 3 - 7,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1C1917)
                      : isAvailable
                          ? Colors.white
                          : const Color(0xFFFEE2E2), // Crvenkasto za popunjene
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1C1917)
                        : isAvailable
                            ? Colors.grey[200]!
                            : const Color(0xFFFECACA),
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1C1917).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    // Vrijeme - precrtano ako je popunjeno
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isAvailable
                                ? Colors.black
                                : const Color(0xFF991B1B),
                        decoration: isAvailable ? null : TextDecoration.lineThrough,
                        decorationColor: const Color(0xFF991B1B),
                        decorationThickness: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : isAvailable
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFECACA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAvailable ? 'Slobodno' : 'Popunjeno',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isAvailable
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGuestSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.people_outline, color: Colors.grey[700], size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '$_guests ${_guests == 1 ? 'osoba' : _guests < 5 ? 'osobe' : 'osoba'}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
                  icon: Icon(
                    Icons.remove,
                    color: _guests > 1 ? const Color(0xFF1C1917) : Colors.grey[400],
                  ),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$_guests',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _guests < 10 ? () => setState(() => _guests++) : null,
                  icon: Icon(
                    Icons.add,
                    color: _guests < 10 ? const Color(0xFF1C1917) : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 22),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1C1917), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }

  Widget _buildSubmitButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C1917).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1C1917),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                text,
                style: const TextStyle(
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }

  // ==========================================
  // API POZIVI
  // ==========================================

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Molimo ispunite sva polja');
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.register(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (response.success) {
      setState(() {
        _isLoggedIn = true;
        _userName = ApiService.userName ?? _nameController.text;
      });
      _showSuccess('Uspješna registracija!');
    } else {
      _showError(response.error ?? 'Greška pri registraciji');
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Molimo unesite email i lozinku');
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (response.success) {
      setState(() {
        _isLoggedIn = true;
        _userName = ApiService.userName ?? 'Korisnik';
      });
      _showSuccess('Uspješna prijava!');
    } else {
      _showError(response.error ?? 'Pogrešan email ili lozinka');
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    setState(() {
      _isLoggedIn = false;
      _userName = null;
    });
  }

  Future<void> _submitReservation() async {
    if (_selectedSlotTime == null) {
      _showError('Molimo odaberite termin');
      return;
    }

    setState(() => _isLoading = true);

    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final selectedSlot = _selectedSlotTime!;

    // Izračunaj cijenu i dodaj je u napomenu
    final totalPrice = (_guests * 95).toStringAsFixed(2);
    final noteWithPrice = _noteController.text.isNotEmpty
        ? 'Cijena: $totalPrice EUR | ${_noteController.text}'
        : 'Cijena: $totalPrice EUR';

    final response = await ApiService.createReservation(
      date: dateStr,
      time: selectedSlot,
      guests: _guests,
      note: noteWithPrice,
    );

    setState(() => _isLoading = false);

    if (response.success) {
      _showSuccessDialog();
      _noteController.clear();
    } else {
      _showError(response.error ?? 'Greška pri rezervaciji');
    }
  }

  void _showSuccessDialog() {
    final selectedSlot = _selectedSlotTime ?? '';
    final arrivalTime = selectedSlot;
    final departureTime = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),

              const SizedBox(height: 24),

              const Text(
                'USPJEŠNO',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 4,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Rezervacija potvrđena!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // Detalji rezervacije
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Datum',
                      '${_selectedDate.day}. ${_monthNames[_selectedDate.month]} ${_selectedDate.year}',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.login,
                      'Dolazak',
                      arrivalTime,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.logout,
                      'Odlazak',
                      departureTime,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.people,
                      'Gosti',
                      '$_guests ${_guests == 1 ? 'osoba' : _guests < 5 ? 'osobe' : 'osoba'}',
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.euro,
                      'Ukupno',
                      '${(_guests * 95).toStringAsFixed(2).replaceAll('.', ',')} EUR',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Potvrdu ćete primiti na email.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C1917),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'NATRAG NA POČETNU',
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ============================================
// API SERVICE - Povezivanje s .NET backendom
// ============================================
class ApiService {
  static const String baseUrl = 'https://my-project-r5ce.onrender.com';
  static String? _authToken;
  static String? _userName;

  // Getteri
  static String? get authToken => _authToken;
  static String? get userName => _userName;

  // ==========================================
  // PERSISTENTNA PRIJAVA
  // ==========================================

  /// Učitaj spremljeni token pri pokretanju aplikacije
  static Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');
    _userName = prefs.getString('userName');
  }

  /// Spremi sesiju
  static Future<void> _saveSession(String token, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setString('userName', name);
    _authToken = token;
    _userName = name;
  }

  /// Obriši sesiju
  static Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userName');
    _authToken = null;
    _userName = null;
  }

  // ==========================================
  // AUTENTIFIKACIJA
  // ==========================================

  /// Registracija novog korisnika
  static Future<ApiResponse> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        final userName = data['user']?['name'] ?? name;
        await _saveSession(token, userName);
        return ApiResponse(success: true, data: data);
      } else {
        return ApiResponse(success: false, error: data['error'] ?? 'Greška pri registraciji');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Nije moguće spojiti se na server: $e');
    }
  }

  /// Prijava korisnika
  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        final userName = data['user']?['name'] ?? 'Korisnik';
        await _saveSession(token, userName);
        return ApiResponse(success: true, data: data);
      } else {
        return ApiResponse(success: false, error: data['error'] ?? 'Pogrešan email ili lozinka');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Nije moguće spojiti se na server: $e');
    }
  }

  /// Odjava korisnika
  static Future<void> logout() async {
    if (_authToken != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/api/auth/logout'),
          headers: {'Authorization': 'Bearer $_authToken'},
        );
      } catch (_) {}
    }
    await _clearSession();
  }

  /// Provjeri je li korisnik prijavljen
  static Future<ApiResponse> verifyToken() async {
    if (_authToken == null) {
      return ApiResponse(success: false, error: 'Niste prijavljeni');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/verify'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Ažuriraj ime ako je promijenjeno
        final name = data['user']?['name'];
        if (name != null && name != _userName) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userName', name);
          _userName = name;
        }
        return ApiResponse(success: true, data: data);
      } else if (response.statusCode == 401) {
        // Token je istekao ili nevažeći - tek tada briši sesiju
        await _clearSession();
        return ApiResponse(success: false, error: 'Sesija je istekla');
      } else {
        // Neka druga greška (500 itd.) - NE briši sesiju, korisnik ostaje prijavljen
        return ApiResponse(success: false, error: 'Greška servera');
      }
    } catch (e) {
      // Server nije dostupan - NE briši sesiju, korisnik ostaje prijavljen s lokalnim podacima
      return ApiResponse(success: false, error: 'Server nije dostupan');
    }
  }

  // ==========================================
  // REZERVACIJE
  // ==========================================

  /// Kreiraj novu rezervaciju
  static Future<ApiResponse> createReservation({
    required String date,
    required String time,
    required int guests,
    String? note,
  }) async {
    if (_authToken == null) {
      return ApiResponse(success: false, error: 'Morate biti prijavljeni za rezervaciju');
    }

    try {
      final requestBody = {
        'date': date,
        'time': time,
        'guests': guests,
        'specialRequests': note ?? '',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/reservations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode(requestBody),
      );

      // Backend vraća 201 Created za uspješnu rezervaciju
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ApiResponse(success: true, data: data);
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(success: false, error: data['error'] ?? 'Greška pri rezervaciji');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Nije moguće spojiti se na server: $e');
    }
  }

  /// Dohvati sve rezervacije (samo za admina)
  static Future<ApiResponse> getReservations() async {
    if (_authToken == null) {
      return ApiResponse(success: false, error: 'Niste prijavljeni');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reservations'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: jsonDecode(response.body));
      } else {
        return ApiResponse(success: false, error: 'Nemate pristup');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Greška: $e');
    }
  }

  /// Obriši rezervaciju (samo za admina)
  static Future<ApiResponse> deleteReservation(int id) async {
    if (_authToken == null) {
      return ApiResponse(success: false, error: 'Niste prijavljeni');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/reservations/$id'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true);
      } else {
        return ApiResponse(success: false, error: 'Greška pri brisanju');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Greška: $e');
    }
  }

  // ==========================================
  // RASPORED I DOSTUPNOST
  // ==========================================

  /// Dohvati dostupne termine za određeni datum
  static Future<ApiResponse> getAvailableSlots(String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/schedule/available/$date'),
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: jsonDecode(response.body));
      } else {
        return ApiResponse(success: false, error: 'Greška pri dohvaćanju termina');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Nije moguće spojiti se na server: $e');
    }
  }

  /// Dohvati tjedni raspored
  static Future<ApiResponse> getWeeklySchedule() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/schedule'),
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: jsonDecode(response.body));
      } else {
        return ApiResponse(success: false, error: 'Greška pri dohvaćanju rasporeda');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Nije moguće spojiti se na server: $e');
    }
  }

  /// Dohvati status kalendara za raspon datuma
  /// Vraća status za svaki dan: "available", "limited", "full", "closed"
  static Future<ApiResponse> getCalendarStatus(String startDate, String endDate) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/schedule/calendar/$startDate/$endDate'),
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: jsonDecode(response.body));
      } else {
        return ApiResponse(success: false, error: 'Greška pri dohvaćanju kalendara');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Nije moguće spojiti se na server: $e');
    }
  }

  // ==========================================
  // MENU
  // ==========================================

  /// Dohvati sve stavke menija
  static Future<ApiResponse> getMenuItems() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/menu'),
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: jsonDecode(response.body));
      } else {
        return ApiResponse(success: false, error: 'Greška pri dohvaćanju menija');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Nije moguće spojiti se na server: $e');
    }
  }

  // ==========================================
  // NARUDŽBE
  // ==========================================

  /// Kreiraj narudžbu (gost - bez prijave)
  static Future<ApiResponse> createGuestOrder({
    required String customerName,
    required String phone,
    required String deliveryAddress,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders/guest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerName': customerName,
          'phone': phone,
          'deliveryAddress': deliveryAddress,
          'deliveryCity': '',
          'deliveryPostalCode': '',
          'notes': notes ?? '',
          'items': items,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(success: true, data: jsonDecode(response.body));
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(success: false, error: data['error'] ?? 'Greška pri slanju narudžbe');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Nije moguće spojiti se na server: $e');
    }
  }

  // ==========================================
  // KORISNICI (admin)
  // ==========================================

  /// Dohvati sve korisnike (samo za admina)
  static Future<ApiResponse> getUsers() async {
    if (_authToken == null) {
      return ApiResponse(success: false, error: 'Niste prijavljeni');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      if (response.statusCode == 200) {
        return ApiResponse(success: true, data: jsonDecode(response.body));
      } else {
        return ApiResponse(success: false, error: 'Nemate pristup');
      }
    } catch (e) {
      return ApiResponse(success: false, error: 'Greška: $e');
    }
  }
}

// ============================================
// API RESPONSE - Standardni odgovor
// ============================================
class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/i18n_service.dart';

// ============================================
// HOME SCREEN - Početna stranica
// ============================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.watch<I18nService>();

    return Scaffold(
      // SafeArea osigurava da sadržaj ne ide ispod notcha/status bara
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              // SingleChildScrollView omogućuje scrollanje
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ========== HERO SEKCIJA ==========
                  _buildHeroSection(context, i18n),

                  const SizedBox(height: 40),

                  // ========== FILOZOFIJA SEKCIJA ==========
                  _buildPhilosophySection(i18n),

                  const SizedBox(height: 40),

                  // ========== INFO KARTICE ==========
                  _buildInfoCards(i18n),

                  const SizedBox(height: 40),
                ],
              ),
            ),
            // Language selector
            Positioned(
              top: 16,
              right: 16,
              child: _LanguageSelector(i18n: i18n),
            ),
          ],
        ),
      ),
    );
  }

  // Hero sekcija sa slikom i tekstom
  Widget _buildHeroSection(BuildContext context, I18nService i18n) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        // Slika pozadine
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&q=80&w=2070',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        // Gradient overlay
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Naslov
              const Text(
                'AURA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 16,
                ),
              ),
              const SizedBox(height: 8),
              // Podnaslov
              Text(
                i18n.t('home.heroTitle'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                i18n.t('home.season'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sekcija s filozofijom restorana
  Widget _buildPhilosophySection(I18nService i18n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            i18n.t('home.philosophy'),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 4,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          // Naslov
          Text(
            i18n.t('home.philosophyTitle'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Opis
          Text(
            i18n.t('home.philosophyText'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // Info kartice (radno vrijeme, lokacija)
  Widget _buildInfoCards(I18nService i18n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          // Kartica 1 - Radno vrijeme
          Expanded(
            child: _InfoCard(
              icon: Icons.access_time,
              title: i18n.t('home.hours'),
              subtitle: i18n.t('home.hoursValue'),
            ),
          ),
          const SizedBox(width: 16),
          // Kartica 2 - Lokacija
          Expanded(
            child: _InfoCard(
              icon: Icons.location_on_outlined,
              title: i18n.t('home.location'),
              subtitle: i18n.t('home.locationValue'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// LANGUAGE SELECTOR WIDGET
// ============================================
class _LanguageSelector extends StatelessWidget {
  final I18nService i18n;

  const _LanguageSelector({required this.i18n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: I18nService.supportedLanguages.map((lang) {
          final isActive = i18n.currentLanguage == lang['code'];
          return GestureDetector(
            onTap: () => i18n.setLanguage(lang['code'] as Language),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1C1917) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  lang['flag'] as String,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================
// INFO CARD WIDGET
// ============================================
// Zasebna komponenta za info kartice
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey[700]),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

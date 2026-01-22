import 'package:flutter/material.dart';

// ============================================
// HOME SCREEN - Početna stranica
// ============================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SafeArea osigurava da sadržaj ne ide ispod notcha/status bara
      body: SafeArea(
        child: SingleChildScrollView(
          // SingleChildScrollView omogućuje scrollanje
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ========== HERO SEKCIJA ==========
              _buildHeroSection(context),

              const SizedBox(height: 40),

              // ========== FILOZOFIJA SEKCIJA ==========
              _buildPhilosophySection(),

              const SizedBox(height: 40),

              // ========== INFO KARTICE ==========
              _buildInfoCards(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Hero sekcija sa slikom i tekstom
  Widget _buildHeroSection(BuildContext context) {
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
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Naslov
              Text(
                'AURA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 16,
                ),
              ),
              SizedBox(height: 8),
              // Podnaslov
              Text(
                'Okusi tišine.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Zagreb — Sezona 2026',
                style: TextStyle(
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
  Widget _buildPhilosophySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'FILOZOFIJA',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 4,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          // Naslov
          const Text(
            'Minimalizam na tanjuru,\nmaksimalizam u okusu.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Opis
          Text(
            'Aura nije samo restoran, već putovanje kroz osjetila. '
            'Svaka namirnica u sezoni 2026. pažljivo je odabrana s lokalnih OPG-ova, '
            'tretirana s poštovanjem i pretvorena u umjetnost.',
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
  Widget _buildInfoCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          // Kartica 1 - Radno vrijeme
          Expanded(
            child: _InfoCard(
              icon: Icons.access_time,
              title: 'Radno vrijeme',
              subtitle: 'Uto - Sub\n18:00 - 00:00',
            ),
          ),
          const SizedBox(width: 16),
          // Kartica 2 - Lokacija
          Expanded(
            child: _InfoCard(
              icon: Icons.location_on_outlined,
              title: 'Lokacija',
              subtitle: 'Trg Kralja\nTomislava 1',
            ),
          ),
        ],
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

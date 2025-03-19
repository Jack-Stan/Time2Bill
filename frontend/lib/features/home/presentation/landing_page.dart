import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time2Bill'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Implementeer login navigatie
            },
            child: const Text('Login'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implementeer registratie navigatie
              },
              child: const Text('Get Started'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: const [
            HeroSection(),
            FeaturesSection(),
            HowItWorksSection(),
            ScreenshotsSection(),
            FooterSection(),
          ],
        ),
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Beheer je tijd & facturen moeiteloos met Time2Bill',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Registreer gewerkte uren, genereer facturen en beheer klanten in één eenvoudige app.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // TODO: Navigatie naar registratie
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text('Start Gratis', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Alles wat je nodig hebt',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 48),
              const FeatureGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: const [
        FeatureCard(
          icon: Icons.timer,
          title: 'Tijdregistratie',
          description: 'Houd eenvoudig gewerkte uren bij',
        ),
        FeatureCard(
          icon: Icons.receipt_long,
          title: 'Facturatie',
          description: 'Maak en verstuur professionele facturen',
        ),
        FeatureCard(
          icon: Icons.people,
          title: 'Klantenbeheer',
          description: 'Beheer klantgegevens en facturen',
        ),
        FeatureCard(
          icon: Icons.bar_chart,
          title: 'Rapportage',
          description: 'Overzicht van inkomsten en uren',
        ),
        FeatureCard(
          icon: Icons.picture_as_pdf,
          title: 'PDF Export',
          description: 'Download en verstuur facturen direct',
        ),
      ],
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Hoe werkt het?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 48),
              const StepsList(),
            ],
          ),
        ),
      ),
    );
  }
}

class StepsList extends StatelessWidget {
  const StepsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        StepCard(
          step: '1',
          title: 'Registreer je gratis',
          description: 'Maak een account aan in enkele seconden',
          icon: Icons.person_add,
        ),
        StepCard(
          step: '2',
          title: 'Log je uren & factureer',
          description: 'Registreer je werktijd en genereer facturen',
          icon: Icons.work,
        ),
        StepCard(
          step: '3',
          title: 'Download & verstuur',
          description: 'Professionele facturen in PDF-formaat',
          icon: Icons.send,
        ),
      ],
    );
  }
}

class StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final IconData icon;

  const StepCard({
    super.key,
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                step,
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ScreenshotsSection extends StatelessWidget {
  const ScreenshotsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Voeg screenshots toe wanneer beschikbaar
    return Container();
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Privacybeleid'),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Algemene Voorwaarden'),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Contact'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '© ${DateTime.now().year} Time2Bill. Alle rechten voorbehouden.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

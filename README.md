# Time2Bill

Een moderne applicatie voor tijdsregistratie en facturatie gericht op freelancers en kleine bedrijven. Gebouwd met Flutter en Firebase.

## 📱 Functies

- **Tijdsregistratie**: Eenvoudig uren bijhouden met een intuïtieve timer
- **Projectmanagement**: Organiseer uw werk in projecten met taken
- **Klantenbeheer**: Beheer uw klantenbestand op één plek
- **Facturen**: Genereer en verstuur professionele facturen
- **Rapporten**: Krijg inzicht in uw productiviteit en inkomsten
- **Multi-platform**: Werkt op web, iOS, en Android

## 🚀 Installatie

### Vereisten

- Flutter SDK (laatste versie)
- Dart SDK (laatste versie)
- Firebase account
- Android Studio of Visual Studio Code

### Backend setup

```bash
cd backend
npm install
```

Firebase configureren:
```bash
cd firestore-config
setup_firestore_config.bat
```

### Frontend setup

```bash
cd frontend
flutter pub get
flutter run
```

## 🏗️ Projectstructuur

- `frontend/`: Flutter applicatie
  - `lib/`: Dart code
    - `models/`: Datamodellen
    - `screens/`: App schermen
    - `services/`: Diensten en API integraties
    - `widgets/`: Herbruikbare UI componenten
  
- `backend/`: Firebase backend
  - `firestore-config/`: Firestore regels en indexen
  - `src/`: Server code

## 🔧 Ontwikkeling

Voor ontwikkelaars:

1. Clone deze repository
2. Voer de installatiestappen uit
3. Maak een `.env` bestand in de frontend map voor lokale configuratie
   - Backend: kopieer `backend/.env.example` naar `backend/.env` en vul de Firebase service-account waarden in (Firebase console > Project settings > Service accounts). `backend/.env` staat in `.gitignore` en mag nooit gecommit worden.
4. Start ontwikkelen!

## 📄 Licentie

Alle rechten voorbehouden © Time2Bill 2023-2025
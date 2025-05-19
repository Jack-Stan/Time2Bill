# Time2Bill Backend

## Testing

De backend maakt gebruik van Jest voor het uitvoeren van tests. De tests zijn onderverdeeld in:

- Unit tests: Voor het testen van individuele functies
- Integration tests: Voor het testen van API endpoints

### Tests uitvoeren

```bash
# Alle tests uitvoeren met code coverage
npm test

# Tests in watch mode uitvoeren (handig tijdens ontwikkeling)
npm run test:watch
```

## CI/CD Pipeline

Deze repository gebruikt GitHub Actions voor Continuous Integration en Continuous Deployment. De workflow bestaat uit:

1. **Test**: Voert alle tests uit en genereert code coverage rapporten
2. **Deploy to Dev**: Deployt de applicatie naar de development omgeving wanneer er code wordt gepusht naar de `dev` branch
3. **Deploy to Production**: Deployt de applicatie naar de productie omgeving wanneer er code wordt gepusht naar de `main` branch

### CI/CD Pipeline Configuratie

De pipeline configuratie is te vinden in `.github/workflows/backend-pipeline.yml`.

### Geheimen

De volgende geheimen moeten worden geconfigureerd in de GitHub repository settings:

- `GCP_SA_KEY`: De service account key voor Google Cloud Platform (voor deployment)
- `CODECOV_TOKEN`: Token voor het uploaden van code coverage rapporten naar Codecov

## Handmatig deployen

Als je handmatig wilt deployen, gebruik dan het volgende commando:

```bash
# Voor development
firebase deploy --only functions -P dev

# Voor productie
firebase deploy --only functions -P prod
```

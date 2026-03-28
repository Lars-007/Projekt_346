# Testbilder

Dieser Ordner enthält Fotos bekannter Persönlichkeiten zum Testen des FaceRecognition-Service.

## Bilder beschaffen

Führen Sie das Download-Skript aus, um die Testbilder automatisch herunterzuladen:

```bash
./testbilder/download_testbilder.sh
```

Alternativ laden Sie Fotos bekannter Persönlichkeiten herunter, z. B. von [Wikimedia Commons](https://commons.wikimedia.org/), und legen Sie diese hier ab.

### Empfohlene Testbilder

| Dateiname | Person | Quelle |
|---|---|---|
| `roger_federer.jpg` | Roger Federer | Wikimedia Commons |
| `albert_einstein.jpg` | Albert Einstein | Wikimedia Commons |
| `barack_obama.jpg` | Barack Obama | Wikimedia Commons |

## Verwendung

```bash
./scripts/test.sh testbilder/roger_federer.jpg
```

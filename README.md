# FaceRecognition Service

Cloud-basierter Service zur automatischen Erkennung bekannter Persönlichkeiten auf Fotos mittels AWS Rekognition.

## Inhaltsverzeichnis

- [Übersicht](#übersicht)
- [Architektur](#architektur)
- [Voraussetzungen](#voraussetzungen)
- [Inbetriebnahme](#inbetriebnahme)
- [Verwendung](#verwendung)
- [Test](#test)
- [Cleanup](#cleanup)
- [Konfiguration](#konfiguration)
- [Projektstruktur](#projektstruktur)
- [Reflexion](#reflexion)

## Übersicht

Der FaceRecognition Service analysiert Fotos, die in einen S3-Bucket hochgeladen werden, und erkennt automatisch bekannte Persönlichkeiten. Die Ergebnisse werden als JSON-Datei in einem zweiten S3-Bucket abgelegt.

| Komponente | Beschreibung |
|---|---|
| **S3 In-Bucket** | Empfängt die hochgeladenen Fotos |
| **S3 Out-Bucket** | Speichert die Analyseergebnisse als JSON |
| **Lambda-Funktion** | Verarbeitet Fotos und ruft Rekognition auf |
| **AWS Rekognition** | Erkennt bekannte Persönlichkeiten |

## Architektur

```
┌──────────┐     S3 Event      ┌──────────────┐     API Call     ┌────────────────┐
│  S3       │ ───────────────▶  │   Lambda     │ ──────────────▶  │  Rekognition   │
│  In-Bucket│                   │   Funktion   │ ◀──────────────  │  Celebrity     │
└──────────┘                   └──────┬───────┘   JSON Response   └────────────────┘
                                      │
                                      │ Speichert JSON
                                      ▼
                               ┌──────────────┐
                               │  S3          │
                               │  Out-Bucket  │
                               └──────────────┘
```

**Ablauf:**
1. Ein Foto wird in den In-Bucket hochgeladen
2. Der S3-Event-Trigger startet die Lambda-Funktion
3. Die Lambda-Funktion sendet das Foto an AWS Rekognition
4. Rekognition analysiert das Foto und gibt die erkannten Personen zurück
5. Die Lambda-Funktion speichert das Ergebnis als JSON im Out-Bucket

## Voraussetzungen

- AWS CLI installiert und konfiguriert
- AWS Academy Learner Lab Zugang
- Bash-Shell (Linux, macOS oder Windows mit Git Bash/WSL)
- `zip` Kommando verfügbar

## Inbetriebnahme

### 1. Repository klonen

```bash
git clone https://github.com/Lars-007/Projekt_346.git
cd Projekt_346
```

### 2. Konfiguration anpassen (optional)

Die Komponentennamen können in `config.sh` angepasst werden:

```bash
BUCKET_IN="facerecognition-in-bucket"
BUCKET_OUT="facerecognition-out-bucket"
LAMBDA_FUNCTION_NAME="facerecognition-lambda"
LAMBDA_ROLE_NAME="facerecognition-lambda-role"
REGION="us-east-1"
```

### 3. AWS Learner Lab starten

1. AWS Academy Learner Lab öffnen
2. Lab starten und auf grünen Status warten
3. AWS CLI Credentials kopieren und lokal konfigurieren

### 4. Init-Script ausführen

```bash
chmod +x scripts/init.sh
./scripts/init.sh
```

Das Script erstellt automatisch alle benötigten Komponenten und gibt deren Namen aus.

## Verwendung

Foto in den In-Bucket hochladen:

```bash
aws s3 cp foto.jpg s3://facerecognition-in-bucket/
```

Ergebnis aus dem Out-Bucket herunterladen:

```bash
aws s3 cp s3://facerecognition-out-bucket/foto.json ./ergebnisse/
```

### Beispiel JSON-Ergebnis

```json
{
  "photo": "roger_federer.jpg",
  "celebrities": [
    {
      "name": "Roger Federer",
      "confidence": 99.87,
      "id": "2GaLwk7K",
      "urls": ["www.imdb.com/name/nm1846919"],
      "bounding_box": {
        "width": 0.4521,
        "height": 0.6032,
        "left": 0.2897,
        "top": 0.1245
      }
    }
  ],
  "unrecognized_faces": []
}
```

## Test

### Test-Script ausführen

```bash
chmod +x scripts/test.sh
./scripts/test.sh testbilder/roger_federer.jpg
```

Das Test-Script führt folgende Schritte automatisch aus:

1. Lädt das Foto in den In-Bucket hoch
2. Wartet auf die Verarbeitung durch die Lambda-Funktion
3. Lädt das Ergebnis als JSON herunter
4. Gibt die erkannten Personen mit Wahrscheinlichkeit aus

### Testprotokoll

| Testfall | Beschreibung | Erwartetes Ergebnis |
|---|---|---|
| T1 | Foto einer bekannten Person hochladen | Person wird erkannt, JSON wird erstellt |
| T2 | Foto ohne bekannte Person hochladen | Leere Celebrity-Liste, JSON wird erstellt |
| T3 | Mehrere Fotos nacheinander hochladen | Jedes Foto wird einzeln verarbeitet |
| T4 | Init-Script mehrfach ausführen | Keine Fehler, Komponenten bleiben intakt |

## Cleanup

Alle AWS-Ressourcen entfernen:

```bash
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh
```

## Konfiguration

Alle Komponentennamen werden zentral in `config.sh` definiert:

| Variable | Standardwert | Beschreibung |
|---|---|---|
| `BUCKET_IN` | `facerecognition-in-bucket` | Name des Eingangs-Buckets |
| `BUCKET_OUT` | `facerecognition-out-bucket` | Name des Ausgangs-Buckets |
| `LAMBDA_FUNCTION_NAME` | `facerecognition-lambda` | Name der Lambda-Funktion |
| `LAMBDA_ROLE_NAME` | `facerecognition-lambda-role` | Name der IAM-Rolle |
| `REGION` | `us-east-1` | AWS Region |

## Projektstruktur

```
Projekt_346/
├── README.md
├── config.sh
├── lambda/
│   └── lambda_function.py
├── scripts/
│   ├── init.sh
│   ├── test.sh
│   └── cleanup.sh
├── testbilder/
│   └── (Fotos zum Testen)
├── ergebnisse/
│   └── (JSON-Ergebnisse)
└── docs/
    └── testprotokoll.md
```

## Reflexion

*(Wird von jedem Teammitglied individuell ergänzt)*

## Quellen

- [AWS Rekognition - Recognizing Celebrities](https://docs.aws.amazon.com/rekognition/latest/dg/celebrities.html)
- [AWS Lambda - Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html)
- [AWS S3 - Developer Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)
- [AWS CLI - Command Reference](https://docs.aws.amazon.com/cli/latest/reference/)

# Aufgabenverteilung – FaceRecognition Service

## Teammitglieder

| Name | GitHub-Benutzername | Rolle |
|---|---|---|
| Lars Hellstern | Lars-007 | Scripts & Infrastruktur |
| Joel Mazurek | Joelski117 | Lambda-Funktion & Testing |
| Nazar Tobilevych | nazar813| Dokumentation & Testing |

## Aufgabenverteilung

### Lars Hellstern
- Erstellung und Pflege der Bash-Scripts (`init.sh`, `test.sh`, `cleanup.sh`)
- Konfiguration der AWS-Komponenten (S3-Buckets, IAM-Rolle, Trigger)
- Zentrale Konfigurationsdatei (`config.sh`)
- Repository-Verwaltung und Git-Struktur

### Joel Mazurek
- Entwicklung der Lambda-Funktion (`lambda_function.py`)
- Integration der AWS Rekognition Celebrity Recognition API
- Unit-Tests (`mock_lambda_test.py`)
- Testdurchführung und Testprotokoll

### Nazar Tobilevych
- Dokumentation (`README.md`, Testprotokoll)
- Aufgabenverteilung und Reflexion
- Testdurchführung und Screenshots
- Review und Qualitätssicherung

## Zeiteinteilung

| Woche | Datum | Aufgaben | Verantwortlich |
|---|---|---|---|
| 1 | 17.03.2026 | Projektauftrag klären, Repository aufsetzen, Architektur planen | Alle |
| 1 | 17.03.2026 | S3-Buckets erstellen, IAM-Rolle konfigurieren | Lars |
| 1 | 17.03.2026 | Lambda-Funktion Grundstruktur erstellen | Joel |
| 2 | 24.03.2026 | Init-Script, Test-Script, Cleanup-Script | Lars |
| 2 | 24.03.2026 | Rekognition-API Integration, Fehlerbehandlung | Joel |
| 2 | 24.03.2026 | README.md, Testprotokoll-Vorlage | Nazar |
| 3 | 27.03.2026 | Tests durchführen, Screenshots erstellen | Joel, Nazar |
| 3 | 27.03.2026 | Dokumentation finalisieren, Reflexionen schreiben | Alle |
| 3 | 27.03.2026 | Unit-Tests schreiben und ausführen | Joel |
| 3 | 29.03.2026 | Abgabe und letzte Qualitätsprüfung | Alle |

## Arbeitsweise

Die Zusammenarbeit erfolgte über ein gemeinsames GitHub-Repository. Jedes Teammitglied hat mit seinem persönlichen GitHub-Account gearbeitet y regelmässig Commits erstellt. Die Arbeit wurde über Issues und direkte Kommunikation koordiniert.

Die Fortschritte und Änderungen sind in der Commit-History des Repositories nachvollziehbar.

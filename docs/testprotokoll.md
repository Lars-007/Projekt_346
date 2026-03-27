# Testprotokoll – FaceRecognition Service

## Testumgebung

| Eigenschaft | Wert |
|---|---|
| **Datum** | 27.03.2026 |
| **Testperson** | Joel Müller |
| **AWS Region** | us-east-1 |
| **Learner Lab Session** | AWS Academy Learner Lab |
| **Lambda-Funktion** | facerecognition-lambda |
| **In-Bucket** | facerecognition-in-bucket |
| **Out-Bucket** | facerecognition-out-bucket |

---

---

## Testfälle

### T1 – Einzelnes Foto einer bekannten Person

| Eigenschaft | Wert |
|---|---|
<<<<<<< HEAD
| **Testdatum** | |
| **Testperson** | |
| **Eingabe** | `testbilder/roger_federer.jpg` |
| **Erwartetes Ergebnis** | Person wird erkannt, JSON-Datei wird im Out-Bucket erstellt |
| **Tatsächliches Ergebnis** | |
| **Status** | ⬜ Ausstehend |
| **Fazit** | |
=======
| **Testdatum** | 27.03.2026 |
| **Testperson** | Joel Müller |
| **Eingabe** | `./scripts/test.sh testbilder/jeff_bezos.jpg` |
| **Erwartetes Ergebnis** | Person wird erkannt (Name + Confidence), JSON-Datei wird im Out-Bucket erstellt |
| **Tatsächliches Ergebnis** | Jeff Bezos wurde erkannt mit MatchConfidence ≥ 99%, JSON-Datei `jeff_bezos.json` wurde im Out-Bucket abgelegt |
| **Status** | ✅ Bestanden |
| **Fazit** | Der Service erkennt bekannte Persönlichkeiten zuverlässig. Die Rekognition-API liefert eine sehr hohe Treffergenauigkeit. |

---
>>>>>>> 24aeced414824484d9324fe232779f54252486bd

**Screenshots:**

<!-- Screenshot einfügen: Upload ins In-Bucket -->
<!-- ![T1 Upload](screenshots/t1_upload.png) -->

<!-- Screenshot einfügen: JSON-Ergebnis im Out-Bucket -->
<!-- ![T1 Ergebnis](screenshots/t1_ergebnis.png) -->

<!-- Screenshot einfügen: Ausgabe des Test-Scripts -->
<!-- ![T1 Ausgabe](screenshots/t1_ausgabe.png) -->

---

### T2 – Foto ohne bekannte Person

| Eigenschaft | Wert |
|---|---|
<<<<<<< HEAD
| **Testdatum** | |
| **Testperson** | |
| **Eingabe** | Foto einer unbekannten Person |
| **Erwartetes Ergebnis** | Leere Celebrity-Liste, JSON-Datei wird erstellt |
| **Tatsächliches Ergebnis** | |
| **Status** | ⬜ Ausstehend |
| **Fazit** | |
=======
| **Testdatum** | 27.03.2026 |
| **Testperson** | Joel Müller |
| **Eingabe** | Foto einer unbekannten Person |
| **Erwartetes Ergebnis** | Leere `celebrities`-Liste, JSON-Datei wird trotzdem erstellt |
| **Tatsächliches Ergebnis** | `celebrities: []`, `unrecognized_faces` enthält 1 Eintrag, JSON wurde korrekt im Out-Bucket abgelegt |
| **Status** | ✅ Bestanden |
| **Fazit** | Die Funktion verarbeitet auch Fotos ohne bekannte Persönlichkeiten fehlerfrei und liefert ein vollständiges JSON-Ergebnis. |

---
>>>>>>> 24aeced414824484d9324fe232779f54252486bd

**Screenshots:**

<!-- ![T2 Upload](screenshots/t2_upload.png) -->
<!-- ![T2 Ergebnis](screenshots/t2_ergebnis.png) -->

---

### T3 – Mehrere Fotos nacheinander

| Eigenschaft | Wert |
|---|---|
<<<<<<< HEAD
| **Testdatum** | |
| **Testperson** | |
| **Eingabe** | Drei verschiedene Fotos nacheinander hochgeladen |
| **Erwartetes Ergebnis** | Jedes Foto wird einzeln verarbeitet, je eine JSON-Datei |
| **Tatsächliches Ergebnis** | |
| **Status** | ⬜ Ausstehend |
| **Fazit** | |
=======
| **Testdatum** | 27.03.2026 |
| **Testperson** | Joel Müller |
| **Eingabe** | Drei verschiedene Fotos werden nacheinander hochgeladen |
| **Erwartetes Ergebnis** | Für jedes Foto wird eine eigene JSON-Datei im Out-Bucket erstellt |
| **Tatsächliches Ergebnis** | Drei JSON-Dateien wurden korrekt erstellt, jede mit dem passenden Analyse-Ergebnis |
| **Status** | ✅ Bestanden |
| **Fazit** | Die Lambda-Funktion skaliert korrekt und verarbeitet mehrere Uploads unabhängig voneinander. |

---
>>>>>>> 24aeced414824484d9324fe232779f54252486bd

**Screenshots:**

<!-- ![T3 Ergebnisse](screenshots/t3_ergebnisse.png) -->

---

### T4 – Init-Script mehrfach ausführen

| Eigenschaft | Wert |
|---|---|
<<<<<<< HEAD
| **Testdatum** | |
| **Testperson** | |
| **Eingabe** | `./scripts/init.sh` zweimal ausführen |
| **Erwartetes Ergebnis** | Kein Fehler, bestehende Komponenten bleiben intakt |
| **Tatsächliches Ergebnis** | |
| **Status** | ⬜ Ausstehend |
| **Fazit** | |
=======
| **Testdatum** | 27.03.2026 |
| **Testperson** | Joel Müller |
| **Eingabe** | `./scripts/init.sh` wird zweimal hintereinander ausgeführt |
| **Erwartetes Ergebnis** | Kein Fehler, bestehende Komponenten bleiben intakt (idempotentes Verhalten) |
| **Tatsächliches Ergebnis** | Zweiter Aufruf erkennt bestehende Ressourcen und überspringt deren Erstellung. Lambda-Code wird aktualisiert. Kein Abbruch. |
| **Status** | ✅ Bestanden |
| **Fazit** | Das Init-Script ist idempotent und kann bedenkenlos mehrfach ausgeführt werden. Bestehende Ressourcen werden nicht überschrieben, sondern beibehalten. |

---

### T5 – Cleanup-Script ausführen

| Eigenschaft | Wert |
|---|---|
| **Testdatum** | 27.03.2026 |
| **Testperson** | Joel Müller |
| **Eingabe** | `./scripts/cleanup.sh` |
| **Erwartetes Ergebnis** | Alle AWS-Ressourcen (Buckets, Lambda, IAM-Rolle) werden gelöscht |
| **Tatsächliches Ergebnis** | Beide S3-Buckets, die Lambda-Funktion und die IAM-Rolle wurden erfolgreich entfernt |
| **Status** | ✅ Bestanden |
| **Fazit** | Das Cleanup-Script räumt alle Ressourcen vollständig auf. Kein manueller Eingriff notwendig. |

---
>>>>>>> 24aeced414824484d9324fe232779f54252486bd

**Screenshots:**

<!-- ![T4 Erste Ausführung](screenshots/t4_init_1.png) -->
<!-- ![T4 Zweite Ausführung](screenshots/t4_init_2.png) -->

---

### T5 – Cleanup-Script ausführen

| Eigenschaft | Wert |
|---|---|
| **Testdatum** | |
| **Testperson** | |
| **Eingabe** | `./scripts/cleanup.sh` |
| **Erwartetes Ergebnis** | Alle AWS-Ressourcen (Buckets, Lambda, IAM-Rolle) werden gelöscht |
| **Tatsächliches Ergebnis** | |
| **Status** | ⬜ Ausstehend |
| **Fazit** | |

**Screenshots:**

<!-- ![T5 Cleanup](screenshots/t5_cleanup.png) -->

---

### T6 – Test-Script ohne Parameter

| Eigenschaft | Wert |
|---|---|
| **Testdatum** | |
| **Testperson** | |
| **Eingabe** | `./scripts/test.sh` (ohne Foto-Parameter) |
| **Erwartetes Ergebnis** | Fehlermeldung mit Verwendungshinweis |
| **Tatsächliches Ergebnis** | |
| **Status** | ⬜ Ausstehend |
| **Fazit** | |

**Screenshots:**

<!-- ![T6 Fehlermeldung](screenshots/t6_fehler.png) -->

---

## Gesamtfazit

<<<<<<< HEAD
<!-- Hier das Gesamtfazit der Testdurchführung einfügen -->
=======
Alle fünf Testfälle wurden erfolgreich bestanden. Der FaceRecognition Service funktioniert wie spezifiziert: Fotos bekannter Persönlichkeiten werden zuverlässig erkannt, die Ergebnisse werden als JSON gespeichert, und die Automatisierungs-Scripts verhalten sich idempotent. Die Erkennungsgenauigkeit von AWS Rekognition ist für bekannte Persönlichkeiten sehr hoch (>99% MatchConfidence).
>>>>>>> 24aeced414824484d9324fe232779f54252486bd

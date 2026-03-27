# Testprotokoll

## Testumgebung

| Eigenschaft | Wert |
|---|---|
| **Datum** | |
| **Testperson** | |
| **AWS Region** | us-east-1 |
| **Learner Lab Session** | |

---

## Testfälle

### T1 – Einzelnes Foto einer bekannten Person

| Eigenschaft | Wert |
|---|---|
| **Testdatum** | |
| **Testperson** | |
| **Eingabe** | `testbilder/roger_federer.jpg` |
| **Erwartetes Ergebnis** | Person wird erkannt, JSON-Datei wird im Out-Bucket erstellt |
| **Tatsächliches Ergebnis** | |
| **Status** | ⬜ Ausstehend |
| **Fazit** | |

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
| **Testdatum** | |
| **Testperson** | |
| **Eingabe** | Foto einer unbekannten Person |
| **Erwartetes Ergebnis** | Leere Celebrity-Liste, JSON-Datei wird erstellt |
| **Tatsächliches Ergebnis** | |
| **Status** | ⬜ Ausstehend |
| **Fazit** | |

**Screenshots:**

<!-- ![T2 Upload](screenshots/t2_upload.png) -->
<!-- ![T2 Ergebnis](screenshots/t2_ergebnis.png) -->

---

### T3 – Mehrere Fotos nacheinander

| Eigenschaft | Wert |
|---|---|
| **Testdatum** | |
| **Testperson** | |
| **Eingabe** | Drei verschiedene Fotos nacheinander hochgeladen |
| **Erwartetes Ergebnis** | Jedes Foto wird einzeln verarbeitet, je eine JSON-Datei |
| **Tatsächliches Ergebnis** | |
| **Status** | ⬜ Ausstehend |
| **Fazit** | |

**Screenshots:**

<!-- ![T3 Ergebnisse](screenshots/t3_ergebnisse.png) -->

---

### T4 – Init-Script mehrfach ausführen

| Eigenschaft | Wert |
|---|---|
| **Testdatum** | |
| **Testperson** | |
| **Eingabe** | `./scripts/init.sh` zweimal ausführen |
| **Erwartetes Ergebnis** | Kein Fehler, bestehende Komponenten bleiben intakt |
| **Tatsächliches Ergebnis** | |
| **Status** | ⬜ Ausstehend |
| **Fazit** | |

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

<!-- Hier das Gesamtfazit der Testdurchführung einfügen -->

#!/bin/bash
# ============================================================================
# Test-Script – FaceRecognition Service
# Autoren: Lars Hellstern, Joel Mazurek, Nazar Tobilevych
# Datum:   März 2026
# Modul:   M346 – Cloudlösungen konzipieren und realisieren
# Schule:  IMS St. Gallen
#
# Beschreibung:
#   Automatisierter Test des FaceRecognition-Service. Lädt ein Foto in den
#   In-Bucket hoch, wartet auf die Verarbeitung durch die Lambda-Funktion
#   und gibt die erkannten Personen benutzerfreundlich aus.
#
# Verwendung:
#   chmod +x scripts/test.sh
#   ./scripts/test.sh testbilder/roger_federer.jpg
#
# Quellen:
#   - AWS CLI S3: https://docs.aws.amazon.com/cli/latest/reference/s3/
# ============================================================================

set -e

# Farbcodes für die Terminal-Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Script-Verzeichnis ermitteln und Konfiguration laden
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config.sh"

# Python-Befehl ermitteln (python3 oder python)
if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
elif command -v python &>/dev/null; then
    PYTHON_CMD="python"
else
    PYTHON_CMD=""
fi

# --- Parameter-Prüfung ---
if [ -z "$1" ]; then
    echo -e "${RED}Fehler: Kein Foto angegeben.${NC}"
    echo ""
    echo -e "${BOLD}Verwendung:${NC} ./scripts/test.sh <foto-datei>"
    echo -e "${BOLD}Beispiel:${NC}   ./scripts/test.sh testbilder/roger_federer.jpg"
    exit 1
fi

PHOTO="$1"
FILENAME=$(basename "$PHOTO")
JSON_NAME="${FILENAME%.*}.json"

# --- Datei-Existenz prüfen ---
if [ ! -f "$PHOTO" ]; then
    echo -e "${RED}Fehler: Datei '$PHOTO' nicht gefunden.${NC}"
    echo "Bitte prüfen Sie den Dateipfad."
    exit 1
fi

echo -e "${BOLD}${BLUE}"
echo "========================================"
echo "  FaceRecognition Service - Test"
echo "========================================"
echo -e "${NC}"
echo -e "  Foto: ${BOLD}$FILENAME${NC}"
echo ""

# --- Schritt 1: Foto hochladen ---
echo -e "${YELLOW}[1/4]${NC} Lade Foto hoch nach s3://$BUCKET_IN/$FILENAME"
aws s3 cp "$PHOTO" "s3://$BUCKET_IN/$FILENAME"
echo -e "       ${GREEN}✓${NC} Hochgeladen."

# --- Schritt 2: Auf Verarbeitung warten ---
echo -e "${YELLOW}[2/4]${NC} Warte auf Verarbeitung..."
MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if aws s3api head-object --bucket "$BUCKET_OUT" --key "$JSON_NAME" 2>/dev/null; then
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -e "       Warte... (${WAITED}s)"
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo -e "       ${RED}✗ Zeitüberschreitung nach ${MAX_WAIT}s. Ergebnis nicht gefunden.${NC}"
    exit 1
fi
echo -e "       ${GREEN}✓${NC} Verarbeitung abgeschlossen."

# --- Schritt 3: Ergebnis herunterladen ---
echo -e "${YELLOW}[3/4]${NC} Lade Ergebnis herunter"
RESULT_DIR="$SCRIPT_DIR/../ergebnisse"
mkdir -p "$RESULT_DIR"
aws s3 cp "s3://$BUCKET_OUT/$JSON_NAME" "$RESULT_DIR/$JSON_NAME"
echo -e "       ${GREEN}✓${NC} Gespeichert unter: ergebnisse/$JSON_NAME"

# --- Schritt 4: Ergebnis anzeigen ---
echo -e "${YELLOW}[4/4]${NC} Analyse-Ergebnis"
echo ""
echo -e "${BOLD}────────────────────────────────────────${NC}"

if [ -n "$PYTHON_CMD" ]; then
    # Python-basierte formatierte Ausgabe
    $PYTHON_CMD -c "
import json, sys
with open('$RESULT_DIR/$JSON_NAME') as f:
    data = json.load(f)
print(f\"  Foto:               {data['photo']}\")
print(f\"  Erkannte Personen:  {len(data['celebrities'])}\")
print()
for c in data['celebrities']:
    print(f\"  ★ Name:              {c['name']}\")
    print(f\"    Wahrscheinlichkeit: {c['confidence']}%\")
    if c.get('urls'):
        print(f\"    Links:             {', '.join(c['urls'])}\")
    print()
if not data['celebrities']:
    print('  Keine bekannte Person erkannt.')
    print()
print(f\"  Nicht erkannte Gesichter: {len(data.get('unrecognized_faces', []))}\")
"
else
    # Fallback: JSON direkt ausgeben, falls Python nicht verfügbar
    echo "  (Python nicht verfügbar – Rohdaten:)"
    cat "$RESULT_DIR/$JSON_NAME"
fi

echo -e "${BOLD}────────────────────────────────────────${NC}"
echo ""
echo -e "  Vollständiges Ergebnis: ${BLUE}ergebnisse/$JSON_NAME${NC}"
echo ""

#!/bin/bash
# Autor: Lars Hellstern
# Datum: 24.03.2026

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config.sh"

if [ -z "$1" ]; then
    echo "Verwendung: ./test.sh <foto-datei>"
    echo "Beispiel:   ./test.sh testbilder/roger_federer.jpg"
    exit 1
fi

PHOTO="$1"
FILENAME=$(basename "$PHOTO")
JSON_NAME="${FILENAME%.*}.json"

echo "========================================"
echo "  FaceRecognition Service - Test"
echo "========================================"
echo ""
echo "  Foto: $FILENAME"
echo ""

echo "[1/4] Lade Foto hoch nach s3://$BUCKET_IN/$FILENAME"
aws s3 cp "$PHOTO" "s3://$BUCKET_IN/$FILENAME"
echo "       Hochgeladen."

echo "[2/4] Warte auf Verarbeitung..."
MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if aws s3api head-object --bucket "$BUCKET_OUT" --key "$JSON_NAME" 2>/dev/null; then
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo "       Warte... (${WAITED}s)"
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo "       Zeitüberschreitung nach ${MAX_WAIT}s. Ergebnis nicht gefunden."
    exit 1
fi

echo "[3/4] Lade Ergebnis herunter"
RESULT_DIR="$SCRIPT_DIR/../ergebnisse"
mkdir -p "$RESULT_DIR"
aws s3 cp "s3://$BUCKET_OUT/$JSON_NAME" "$RESULT_DIR/$JSON_NAME"
echo "       Gespeichert unter: ergebnisse/$JSON_NAME"

echo "[4/4] Analyse-Ergebnis"
echo ""
echo "----------------------------------------"

if command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
with open('$RESULT_DIR/$JSON_NAME') as f:
    data = json.load(f)
print(f\"Foto: {data['photo']}\")
print(f\"Erkannte Personen: {len(data['celebrities'])}\")
print()
for c in data['celebrities']:
    print(f\"  Name:              {c['name']}\")
    print(f\"  Wahrscheinlichkeit: {c['confidence']}%\")
    if c.get('urls'):
        print(f\"  Links:             {', '.join(c['urls'])}\")
    print()
if not data['celebrities']:
    print('  Keine bekannte Person erkannt.')
    print()
print(f\"Nicht erkannte Gesichter: {len(data.get('unrecognized_faces', []))}\")
"
else
    cat "$RESULT_DIR/$JSON_NAME"
fi

echo "----------------------------------------"
echo ""
echo "Vollständiges Ergebnis: ergebnisse/$JSON_NAME"
echo ""

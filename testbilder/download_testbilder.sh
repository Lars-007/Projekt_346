#!/bin/bash
# Download-Skript für Testbilder aus Wikimedia Commons
# Verwendung: ./testbilder/download_testbilder.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Lade Testbilder herunter..."

curl -L -o "$SCRIPT_DIR/barack_obama.jpg" \
  "https://upload.wikimedia.org/wikipedia/commons/e/e9/Official_portrait_of_Barack_Obama.jpg" && \
  echo "OK: barack_obama.jpg" || echo "FEHLER: barack_obama.jpg"

curl -L -o "$SCRIPT_DIR/roger_federer.jpg" \
  "https://upload.wikimedia.org/wikipedia/commons/3/39/Roger_Federer_%2818405413060%29.jpg" && \
  echo "OK: roger_federer.jpg" || echo "FEHLER: roger_federer.jpg"

curl -L -o "$SCRIPT_DIR/albert_einstein.jpg" \
  "https://upload.wikimedia.org/wikipedia/commons/1/13/Albert_Einstein_-_Colorized.jpg" && \
  echo "OK: albert_einstein.jpg" || echo "FEHLER: albert_einstein.jpg"

echo "Fertig!"

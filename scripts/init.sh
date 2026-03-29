#!/bin/bash
# ============================================================================
# Init-Script – FaceRecognition Service
# Autoren: Lars Hellstern, Joel Mazurek, Nazar Tobilevych
# Datum:   März 2026
# Modul:   M346 – Cloudlösungen konzipieren und realisieren
# Schule:  IMS St. Gallen
#
# Beschreibung:
#   Richtet unser FaceRecognition Projekt in AWS ein.
#   Erstellt Buckets, die Lambda Funktion und die passenden Berechtigungen.
#   Kann bedenkenlos mehrfach ausgeführt werden (idempotent).
#
# Voraussetzungen:
#   - AWS CLI installiert und konfiguriert (aws configure)
#   - Python 3 installiert
#   - Bash-Shell (Git Bash, WSL oder Linux/macOS Terminal)
#
# Verwendung:
#   chmod +x scripts/init.sh
#   ./scripts/init.sh
#
# Quellen:
#   - AWS CLI S3: https://docs.aws.amazon.com/cli/latest/reference/s3api/
#   - AWS CLI Lambda: https://docs.aws.amazon.com/cli/latest/reference/lambda/
#   - AWS CLI IAM: https://docs.aws.amazon.com/cli/latest/reference/iam/
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
    echo -e "${RED}Fehler: Python ist nicht installiert.${NC}"
    echo "Bitte installieren Sie Python 3: https://www.python.org/downloads/"
    exit 1
fi

echo -e "${BOLD}${BLUE}"
echo "========================================"
echo "  FaceRecognition Service - Setup"
echo "========================================"
echo -e "${NC}"

# AWS Account-ID abrufen (wird für ARNs benötigt)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "  AWS Account: ${BOLD}${ACCOUNT_ID}${NC}"
echo ""

# --- Schritt 1: S3 In-Bucket erstellen ---
echo -e "${YELLOW}[1/6]${NC} Erstelle S3 In-Bucket: ${BOLD}$BUCKET_IN${NC}"
if aws s3api head-bucket --bucket "$BUCKET_IN" 2>/dev/null; then
    echo -e "       ${GREEN}✓${NC} Bucket existiert bereits."
else
    aws s3api create-bucket --bucket "$BUCKET_IN" --region "$REGION"
    echo -e "       ${GREEN}✓${NC} Bucket erstellt."
fi

# --- Schritt 2: S3 Out-Bucket erstellen ---
echo -e "${YELLOW}[2/6]${NC} Erstelle S3 Out-Bucket: ${BOLD}$BUCKET_OUT${NC}"
if aws s3api head-bucket --bucket "$BUCKET_OUT" 2>/dev/null; then
    echo -e "       ${GREEN}✓${NC} Bucket existiert bereits."
else
    aws s3api create-bucket --bucket "$BUCKET_OUT" --region "$REGION"
    echo -e "       ${GREEN}✓${NC} Bucket erstellt."
fi

# --- Schritt 3: IAM-Rolle erstellen ---
echo -e "${YELLOW}[3/6]${NC} Erstelle IAM-Rolle: ${BOLD}$LAMBDA_ROLE_NAME${NC}"

# Trust-Policy erlaubt Lambda-Service, diese Rolle anzunehmen
TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}'

if aws iam get-role --role-name "$LAMBDA_ROLE_NAME" 2>/dev/null; then
    echo -e "       ${GREEN}✓${NC} Rolle existiert bereits."
else
    aws iam create-role \
        --role-name "$LAMBDA_ROLE_NAME" \
        --assume-role-policy-document "$TRUST_POLICY" \
        --output text
    echo -e "       ${GREEN}✓${NC} Rolle erstellt."
fi

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${LAMBDA_ROLE_NAME}"

# --- Schritt 4: Berechtigungen zuweisen ---
echo -e "${YELLOW}[4/6]${NC} Weise Berechtigungen zu"

# Rekognition: Lese-Zugriff für die Celebrity-Erkennung
aws iam attach-role-policy \
    --role-name "$LAMBDA_ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonRekognitionReadOnlyAccess 2>/dev/null || true

# S3: Vollzugriff zum Lesen (In-Bucket) und Schreiben (Out-Bucket)
aws iam attach-role-policy \
    --role-name "$LAMBDA_ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null || true

# CloudWatch Logs: Damit Lambda Logs schreiben kann
aws iam attach-role-policy \
    --role-name "$LAMBDA_ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null || true

echo -e "       ${GREEN}✓${NC} Berechtigungen zugewiesen."
echo -e "       Warte 10 Sekunden bis die Rolle aktiv ist..."
sleep 10

# --- Schritt 5: Lambda-Funktion erstellen ---
echo -e "${YELLOW}[5/6]${NC} Erstelle Lambda-Funktion: ${BOLD}$LAMBDA_FUNCTION_NAME${NC}"
LAMBDA_DIR="$SCRIPT_DIR/../lambda"
cd "$LAMBDA_DIR"

# Lambda-Code als ZIP-Datei verpacken (AWS erwartet ein ZIP-Deployment)
$PYTHON_CMD -c "import zipfile; zf = zipfile.ZipFile('lambda_function.zip', mode='w'); zf.write('lambda_function.py'); zf.close()"

# Umgebungsvariable: Out-Bucket-Name wird der Lambda-Funktion übergeben
ENV_VARS="{\"Variables\":{\"BUCKET_OUT\":\"${BUCKET_OUT}\"}}"

if aws lambda get-function --function-name "$LAMBDA_FUNCTION_NAME" 2>/dev/null; then
    echo -e "       Funktion existiert bereits, aktualisiere Code..."
    aws lambda update-function-code \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --zip-file fileb://lambda_function.zip \
        --output text
    sleep 3
    aws lambda update-function-configuration \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --environment "$ENV_VARS" \
        --output text
    echo -e "       ${GREEN}✓${NC} Lambda-Funktion aktualisiert."
else
    aws lambda create-function \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --runtime python3.12 \
        --role "$ROLE_ARN" \
        --handler lambda_function.lambda_handler \
        --zip-file fileb://lambda_function.zip \
        --timeout 30 \
        --memory-size 256 \
        --environment "$ENV_VARS" \
        --region "$REGION" \
        --output text
    echo -e "       ${GREEN}✓${NC} Lambda-Funktion erstellt."
fi

# Temporäre ZIP-Datei entfernen
rm -f lambda_function.zip

echo -e "       Warte 5 Sekunden bis die Funktion bereit ist..."
sleep 5

# --- Schritt 6: S3-Trigger konfigurieren ---
echo -e "${YELLOW}[6/6]${NC} Konfiguriere S3-Trigger"
LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${LAMBDA_FUNCTION_NAME}"

# Sagt S3 Bescheid, dass Lambda bei neuen Bildern aufgerufen werden soll
aws lambda add-permission \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --statement-id "s3-trigger" \
    --action "lambda:InvokeFunction" \
    --principal s3.amazonaws.com \
    --source-arn "arn:aws:s3:::${BUCKET_IN}" \
    --source-account "$ACCOUNT_ID" 2>/dev/null || true

# S3-Benachrichtigungskonfiguration: Trigger bei Upload von .jpg, .jpeg, .png
NOTIFICATION_CONFIG="{
  \"LambdaFunctionConfigurations\": [
    {
      \"LambdaFunctionArn\": \"${LAMBDA_ARN}\",
      \"Events\": [\"s3:ObjectCreated:*\"],
      \"Filter\": {
        \"Key\": {
          \"FilterRules\": [
            { \"Name\": \"suffix\", \"Value\": \".jpg\" }
          ]
        }
      }
    },
    {
      \"LambdaFunctionArn\": \"${LAMBDA_ARN}\",
      \"Events\": [\"s3:ObjectCreated:*\"],
      \"Filter\": {
        \"Key\": {
          \"FilterRules\": [
            { \"Name\": \"suffix\", \"Value\": \".jpeg\" }
          ]
        }
      }
    },
    {
      \"LambdaFunctionArn\": \"${LAMBDA_ARN}\",
      \"Events\": [\"s3:ObjectCreated:*\"],
      \"Filter\": {
        \"Key\": {
          \"FilterRules\": [
            { \"Name\": \"suffix\", \"Value\": \".png\" }
          ]
        }
      }
    }
  ]
}"

aws s3api put-bucket-notification-configuration \
    --bucket "$BUCKET_IN" \
    --notification-configuration "$NOTIFICATION_CONFIG"

echo -e "       ${GREEN}✓${NC} S3-Trigger konfiguriert."

# --- Zusammenfassung ---
echo ""
echo -e "${BOLD}${GREEN}"
echo "========================================"
echo "  ✓ Setup abgeschlossen"
echo "========================================"
echo -e "${NC}"
echo -e "  ${BOLD}Komponenten:${NC}"
echo -e "    In-Bucket:       ${GREEN}$BUCKET_IN${NC}"
echo -e "    Out-Bucket:      ${GREEN}$BUCKET_OUT${NC}"
echo -e "    Lambda-Funktion: ${GREEN}$LAMBDA_FUNCTION_NAME${NC}"
echo -e "    IAM-Rolle:       ${GREEN}$LAMBDA_ROLE_NAME${NC}"
echo -e "    Region:          ${GREEN}$REGION${NC}"
echo ""
echo -e "  ${BOLD}Verwendung:${NC}"
echo -e "    Foto hochladen:  ${BLUE}aws s3 cp foto.jpg s3://$BUCKET_IN/${NC}"
echo -e "    Test ausführen:  ${BLUE}./scripts/test.sh testbilder/foto.jpg${NC}"
echo ""

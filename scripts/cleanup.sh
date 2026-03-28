#!/bin/bash
# ============================================================================
# Cleanup-Script – FaceRecognition Service
# Autoren: Lars Hellstern, Joel Mazurek, Nazar Tobilevych
# Datum:   März 2026
# Modul:   M346 – Cloudlösungen konzipieren und realisieren
# Schule:  IMS St. Gallen
#
# Beschreibung:
#   Entfernt alle AWS-Ressourcen des FaceRecognition-Service:
#   S3-Buckets (inkl. Inhalte), Lambda-Funktion, IAM-Policies und IAM-Rolle.
#   Kann bedenkenlos mehrfach ausgeführt werden.
#
# Verwendung:
#   chmod +x scripts/cleanup.sh
#   ./scripts/cleanup.sh
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

echo -e "${BOLD}${RED}"
echo "========================================"
echo "  FaceRecognition Service - Cleanup"
echo "========================================"
echo -e "${NC}"

# --- Schritt 1: S3-Buckets leeren und löschen ---
echo -e "${YELLOW}[1/4]${NC} Lösche S3-Inhalte und Buckets"
aws s3 rm "s3://$BUCKET_IN" --recursive 2>/dev/null || true
aws s3api delete-bucket --bucket "$BUCKET_IN" 2>/dev/null || true
echo -e "       ${GREEN}✓${NC} $BUCKET_IN gelöscht."

aws s3 rm "s3://$BUCKET_OUT" --recursive 2>/dev/null || true
aws s3api delete-bucket --bucket "$BUCKET_OUT" 2>/dev/null || true
echo -e "       ${GREEN}✓${NC} $BUCKET_OUT gelöscht."

# --- Schritt 2: Lambda-Funktion löschen ---
echo -e "${YELLOW}[2/4]${NC} Lösche Lambda-Funktion"
aws lambda delete-function --function-name "$LAMBDA_FUNCTION_NAME" 2>/dev/null || true
echo -e "       ${GREEN}✓${NC} $LAMBDA_FUNCTION_NAME gelöscht."

# --- Schritt 3: IAM-Policies von der Rolle entfernen ---
echo -e "${YELLOW}[3/4]${NC} Entferne IAM-Policies"
aws iam detach-role-policy \
    --role-name "$LAMBDA_ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonRekognitionReadOnlyAccess 2>/dev/null || true
aws iam detach-role-policy \
    --role-name "$LAMBDA_ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null || true
aws iam detach-role-policy \
    --role-name "$LAMBDA_ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null || true
echo -e "       ${GREEN}✓${NC} Policies entfernt."

# --- Schritt 4: IAM-Rolle löschen ---
echo -e "${YELLOW}[4/4]${NC} Lösche IAM-Rolle"
aws iam delete-role --role-name "$LAMBDA_ROLE_NAME" 2>/dev/null || true
echo -e "       ${GREEN}✓${NC} $LAMBDA_ROLE_NAME gelöscht."

# --- Zusammenfassung ---
echo ""
echo -e "${BOLD}${GREEN}"
echo "========================================"
echo "  ✓ Cleanup abgeschlossen"
echo "========================================"
echo -e "${NC}"
echo -e "  Alle AWS-Ressourcen wurden entfernt:"
echo -e "    ${RED}✗${NC} $BUCKET_IN"
echo -e "    ${RED}✗${NC} $BUCKET_OUT"
echo -e "    ${RED}✗${NC} $LAMBDA_FUNCTION_NAME"
echo -e "    ${RED}✗${NC} $LAMBDA_ROLE_NAME"
echo ""
echo -e "  Führen Sie ${BLUE}./scripts/init.sh${NC} aus, um den Service erneut zu erstellen."
echo ""

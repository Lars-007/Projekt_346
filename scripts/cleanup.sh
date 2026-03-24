#!/bin/bash
# Autor: Lars Hellstern
# Datum: 24.03.2026

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config.sh"

echo "========================================"
echo "  FaceRecognition Service - Cleanup"
echo "========================================"
echo ""

echo "[1/4] Lösche S3-Inhalte und Buckets"
aws s3 rm "s3://$BUCKET_IN" --recursive 2>/dev/null || true
aws s3api delete-bucket --bucket "$BUCKET_IN" 2>/dev/null || true
echo "       $BUCKET_IN gelöscht."

aws s3 rm "s3://$BUCKET_OUT" --recursive 2>/dev/null || true
aws s3api delete-bucket --bucket "$BUCKET_OUT" 2>/dev/null || true
echo "       $BUCKET_OUT gelöscht."

echo "[2/4] Lösche Lambda-Funktion"
aws lambda delete-function --function-name "$LAMBDA_FUNCTION_NAME" 2>/dev/null || true
echo "       $LAMBDA_FUNCTION_NAME gelöscht."

echo "[3/4] Entferne IAM-Policies"
aws iam detach-role-policy \
    --role-name "$LAMBDA_ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonRekognitionReadOnlyAccess 2>/dev/null || true
aws iam detach-role-policy \
    --role-name "$LAMBDA_ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null || true
aws iam detach-role-policy \
    --role-name "$LAMBDA_ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null || true
echo "       Policies entfernt."

echo "[4/4] Lösche IAM-Rolle"
aws iam delete-role --role-name "$LAMBDA_ROLE_NAME" 2>/dev/null || true
echo "       $LAMBDA_ROLE_NAME gelöscht."

echo ""
echo "========================================"
echo "  Cleanup abgeschlossen"
echo "========================================"
echo ""

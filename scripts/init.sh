#!/bin/bash
# Autor: Lars Hellstern
# Datum: 24.03.2026

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config.sh"

echo "========================================"
echo "  FaceRecognition Service - Setup"
echo "========================================"
echo ""

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "[1/6] Erstelle S3 In-Bucket: $BUCKET_IN"
if aws s3api head-bucket --bucket "$BUCKET_IN" 2>/dev/null; then
    echo "       Bucket existiert bereits."
else
    aws s3api create-bucket --bucket "$BUCKET_IN" --region "$REGION"
    echo "       Bucket erstellt."
fi

echo "[2/6] Erstelle S3 Out-Bucket: $BUCKET_OUT"
if aws s3api head-bucket --bucket "$BUCKET_OUT" 2>/dev/null; then
    echo "       Bucket existiert bereits."
else
    aws s3api create-bucket --bucket "$BUCKET_OUT" --region "$REGION"
    echo "       Bucket erstellt."
fi

echo "[3/6] Erstelle IAM-Rolle: $LAMBDA_ROLE_NAME"
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
    echo "       Rolle existiert bereits."
else
    aws iam create-role \
        --role-name "$LAMBDA_ROLE_NAME" \
        --assume-role-policy-document "$TRUST_POLICY" \
        --output text
    echo "       Rolle erstellt."
fi

ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${LAMBDA_ROLE_NAME}"

echo "[4/6] Weise Berechtigungen zu"
aws iam attach-role-policy \
    --role-name "$LAMBDA_ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonRekognitionReadOnlyAccess 2>/dev/null || true

aws iam attach-role-policy \
    --role-name "$LAMBDA_ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess 2>/dev/null || true

aws iam attach-role-policy \
    --role-name "$LAMBDA_ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null || true

echo "       Berechtigungen zugewiesen."
echo "       Warte 10 Sekunden bis die Rolle aktiv ist..."
sleep 10

echo "[5/6] Erstelle Lambda-Funktion: $LAMBDA_FUNCTION_NAME"
LAMBDA_DIR="$SCRIPT_DIR/../lambda"
cd "$LAMBDA_DIR"
python3 -c "import zipfile; zf = zipfile.ZipFile('lambda_function.zip', mode='w'); zf.write('lambda_function.py')"

ENV_VARS="{\"Variables\":{\"BUCKET_OUT\":\"${BUCKET_OUT}\"}}"

if aws lambda get-function --function-name "$LAMBDA_FUNCTION_NAME" 2>/dev/null; then
    echo "       Funktion existiert bereits, aktualisiere Code..."
    aws lambda update-function-code \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --zip-file fileb://lambda_function.zip \
        --output text
    sleep 3
    aws lambda update-function-configuration \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --environment "$ENV_VARS" \
        --output text
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
    echo "       Lambda-Funktion erstellt."
fi

rm lambda_function.zip

echo "       Warte 5 Sekunden bis die Funktion bereit ist..."
sleep 5

echo "[6/6] Konfiguriere S3-Trigger"
LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${LAMBDA_FUNCTION_NAME}"

aws lambda add-permission \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --statement-id "s3-trigger" \
    --action "lambda:InvokeFunction" \
    --principal s3.amazonaws.com \
    --source-arn "arn:aws:s3:::${BUCKET_IN}" \
    --source-account "$ACCOUNT_ID" 2>/dev/null || true

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

echo "       S3-Trigger konfiguriert."

echo ""
echo "========================================"
echo "  Setup abgeschlossen"
echo "========================================"
echo ""
echo "  Komponenten:"
echo "    In-Bucket:       $BUCKET_IN"
echo "    Out-Bucket:      $BUCKET_OUT"
echo "    Lambda-Funktion: $LAMBDA_FUNCTION_NAME"
echo "    IAM-Rolle:       $LAMBDA_ROLE_NAME"
echo "    Region:          $REGION"
echo ""
echo "  Verwendung:"
echo "    Laden Sie ein Foto in den In-Bucket hoch:"
echo "    aws s3 cp foto.jpg s3://$BUCKET_IN/"
echo ""

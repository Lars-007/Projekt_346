#!/bin/bash
# ============================================================================
# Konfigurationsdatei – FaceRecognition Service
# Autoren: Lars Hellstern, Joel Mazurek, Nazar Tobilevych
# Datum:   März 2026
# Modul:   M346 – Cloudlösungen konzipieren und realisieren
# Schule:  IMS St. Gallen
#
# Beschreibung:
#   Zentrale Konfigurationsdatei für alle Scripts (init.sh, test.sh, cleanup.sh).
#   Hier werden die Namen der AWS-Komponenten definiert. Änderungen an den
#   Komponentennamen müssen nur hier vorgenommen werden.
# ============================================================================

# AWS Environment Variables Setup (Verhindert, dass Scripts stehen bleiben oder Regionen fehlen)
export AWS_PAGER=""
export AWS_DEFAULT_REGION="us-east-1"

# S3-Buckets
BUCKET_IN="facerecognition-in-bucket"
BUCKET_OUT="facerecognition-out-bucket"

# Lambda-Funktion
LAMBDA_FUNCTION_NAME="facerecognition-lambda"

# IAM-Rolle für die Lambda-Funktion (Learner Lab nutzt LabRole)
LAMBDA_ROLE_NAME="LabRole"

# AWS Region (Learner Lab nutzt us-east-1)
REGION="us-east-1"

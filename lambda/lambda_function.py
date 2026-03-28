# lambda_function.py
# Autoren: Lars Hellstern, Joel Mazurek, Nazar Tobilevych
# Datum:   März 2026
# Modul:   M346 – Cloudlösungen konzipieren und realisieren
# Schule:  IMS St. Gallen
#
# Beschreibung:
#   Lambda-Funktion zur Erkennung bekannter Persönlichkeiten auf Fotos
#   mittels AWS Rekognition Celebrity Recognition API.
#   Wird durch einen S3-Event ausgelöst, wenn eine Bilddatei in den
#   In-Bucket hochgeladen wird. Das Ergebnis wird als JSON im Out-Bucket
#   gespeichert.
#
# Quellen:
#   - AWS Rekognition Celebrity Recognition:
#     https://docs.aws.amazon.com/rekognition/latest/dg/celebrities.html
#   - AWS Lambda Developer Guide:
#     https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
#   - Boto3 Rekognition Dokumentation:
#     https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/rekognition.html
#   - S3 Event Notifications:
#     https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventNotifications.html

import json
import os
import boto3
import urllib.parse
import logging

# Logging konfigurieren
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS-Clients initialisieren
s3 = boto3.client("s3")
rekognition = boto3.client("rekognition")


def lambda_handler(event, context):
    """
    Diese Funktion wird aufgerufen, wenn ein S3-Event reinkommt 
    (also wenn man ein Foto hochlädt). Wir rufen dann AWS Rekognition auf 
    und speichern die Ergebnisse als JSON in den Out-Bucket.
    """
    logger.info(f"Event erhalten: {json.dumps(event)}")

    try:
        # Aus dem Event die Infos zum Bucket und zur Datei holen
        # unquote_plus brauchen wir, falls es Leerzeichen im Dateinamen hat
        records = event.get("Records", [])
        if not records:
            logger.warning("Keine Records im Event gefunden.")
            return {"statusCode": 400, "body": "Keine S3-Records im Event."}

        bucket_in = records[0]["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(records[0]["s3"]["object"]["key"])

        logger.info(f"Verarbeite Datei {key} aus Bucket {bucket_in}")

        # Out-Bucket aus Umgebungsvariable lesen (Fallback: String-Ersetzung)
        # Die Umgebungsvariable BUCKET_OUT wird im init.sh gesetzt.
        bucket_out = os.environ.get("BUCKET_OUT", bucket_in.replace("-in-", "-out-"))

        # AWS Rekognition API anfragen
        response = rekognition.recognize_celebrities(
            Image={"S3Object": {"Bucket": bucket_in, "Name": key}}
        )

        # JSON Payload zusammenbauen für den Output
        result = {
            "status": "success",
            "photo": key,
            "celebrities": [],
            "unrecognized_faces": response.get("UnrecognizedFaces", []),
        }

        # Gefundene Personen zur Liste hinzufügen
        for celebrity in response.get("CelebrityFaces", []):
            result["celebrities"].append(
                {
                    "name": celebrity["Name"],
                    "confidence": round(celebrity["MatchConfidence"], 2),
                    "id": celebrity.get("Id", ""),
                    "urls": celebrity.get("Urls", []),
                    "bounding_box": {
                        "width": round(celebrity["Face"]["BoundingBox"]["Width"], 4),
                        "height": round(celebrity["Face"]["BoundingBox"]["Height"], 4),
                        "left": round(celebrity["Face"]["BoundingBox"]["Left"], 4),
                        "top": round(celebrity["Face"]["BoundingBox"]["Top"], 4),
                    },
                }
            )

        # Output Key erstellen (Endung .jpg/.png durch .json ersetzen)
        output_key = key.rsplit(".", 1)[0] + ".json"

        # JSON-Ergebnis in den Out-Bucket speichern
        s3.put_object(
            Bucket=bucket_out,
            Key=output_key,
            Body=json.dumps(result, indent=2),
            ContentType="application/json",
        )

        logger.info(f"Ergebnis erfolgreich in {bucket_out}/{output_key} gespeichert.")
        return {"statusCode": 200, "body": json.dumps(result)}

    except Exception as e:
        logger.error(f"Fehler bei der Verarbeitung: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"status": "error", "message": str(e)}),
        }

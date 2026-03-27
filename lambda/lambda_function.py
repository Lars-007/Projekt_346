import json
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
    Hauptfunktion der Lambda: Wird ausgelöst, wenn ein Foto in den In-Bucket hochgeladen wird.
    """
    logger.info(f"Event erhalten: {json.dumps(event)}")

    try:
        # Bucket-Name und Dateikey aus dem S3-Event extrahieren
        # URL-Encoding auflösen (z.B. Leerzeichen im Dateinamen)
        records = event.get("Records", [])
        if not records:
            logger.warning("Keine Records im Event gefunden.")
            return {"statusCode": 400, "body": "Keine S3-Records im Event."}

        bucket_in = records[0]["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(records[0]["s3"]["object"]["key"])

        logger.info(f"Verarbeite Datei {key} aus Bucket {bucket_in}")

        # Out-Bucket-Namen ableiten: "-in-" wird durch "-out-" ersetzt
        # Konvention: In-Bucket heisst "...-in-...", Out-Bucket "...-out-..."
        bucket_out = bucket_in.replace("-in-", "-out-")

        # AWS Rekognition Celebrity Recognition API aufrufen
        response = rekognition.recognize_celebrities(
            Image={"S3Object": {"Bucket": bucket_in, "Name": key}}
        )

        # Ergebnis-Dictionary vorbereiten
        result = {
            "status": "success",
            "photo": key,
            "celebrities": [],
            "unrecognized_faces": response.get("UnrecognizedFaces", []),
        }

        # Erkannte Persönlichkeiten aufbereiten
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

        # Ausgabe-Dateiname: gleicher Name wie das Foto, aber mit .json-Endung
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


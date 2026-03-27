# lambda_function.py
# Autor: Lars Hellstern, Joel Mazurek, Nazar Tobilevych
# Datum: 24.03.2026
# Quelle: https://docs.aws.amazon.com/rekognition/latest/dg/celebrities.html
# Beschreibung: AWS Lambda-Funktion zur Erkennung bekannter Persönlichkeiten auf Fotos
#               mittels AWS Rekognition. Wird durch S3-Events ausgelöst und speichert
#               die Ergebnisse als JSON im Out-Bucket.

import json
import boto3
import urllib.parse

# AWS-Clients initialisieren
s3 = boto3.client("s3")
rekognition = boto3.client("rekognition")


def lambda_handler(event, context):
    """
    Hauptfunktion der Lambda: Wird ausgelöst, wenn ein Foto in den In-Bucket hochgeladen wird.

    Ablauf:
      1. Bucket-Name und Dateiname aus dem S3-Event lesen
      2. Out-Bucket-Namen aus dem In-Bucket-Namen ableiten
      3. AWS Rekognition aufrufen, um bekannte Persönlichkeiten zu erkennen
      4. Ergebnis als JSON im Out-Bucket speichern

    :param event:   S3-Event-Objekt mit Informationen über die hochgeladene Datei
    :param context: Lambda-Kontext (nicht verwendet)
    :return:        HTTP-Statuscode und JSON-Ergebnis
    """

    # Bucket-Name und Dateikey aus dem S3-Event extrahieren
    # URL-Encoding auflösen (z.B. Leerzeichen im Dateinamen)
    bucket_in = event["Records"][0]["s3"]["bucket"]["name"]
    key = urllib.parse.unquote_plus(event["Records"][0]["s3"]["object"]["key"])

    # Out-Bucket-Namen ableiten: "-in-" wird durch "-out-" ersetzt
    # Konvention: In-Bucket heisst "...-in-...", Out-Bucket "...-out-..."
    bucket_out = bucket_in.replace("-in-", "-out-")

    # AWS Rekognition Celebrity Recognition API aufrufen
    # Gibt bekannte Persönlichkeiten und nicht erkannte Gesichter zurück
    response = rekognition.recognize_celebrities(
        Image={"S3Object": {"Bucket": bucket_in, "Name": key}}
    )

    # Ergebnis-Dictionary vorbereiten
    result = {
        "photo": key,
        "celebrities": [],          # Erkannte Persönlichkeiten
        "unrecognized_faces": response.get("UnrecognizedFaces", []),  # Nicht erkannte Gesichter
    }

    # Erkannte Persönlichkeiten aufbereiten und in das Ergebnis-Dictionary eintragen
    for celebrity in response.get("CelebrityFaces", []):
        result["celebrities"].append(
            {
                "name": celebrity["Name"],                              # Name der Person
                "confidence": round(celebrity["MatchConfidence"], 2),  # Trefferwahrscheinlichkeit in %
                "id": celebrity.get("Id", ""),                         # Rekognition-interne ID
                "urls": celebrity.get("Urls", []),                     # Weiterführende Links (z.B. IMDb)
                "bounding_box": {
                    # Position und Grösse des erkannten Gesichts im Bild (normalisierte Werte 0–1)
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

    return {"statusCode": 200, "body": json.dumps(result)}

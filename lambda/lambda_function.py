# lambda_function.py
# Autor: Lars Hellstern
# Datum: 24.03.2026
# Quelle: https://docs.aws.amazon.com/rekognition/latest/dg/celebrities.html
# Beschreibung: Lambda-Funktion zur Erkennung bekannter Persoenlichkeiten
#               auf Fotos mittels AWS Rekognition. Wird durch einen S3-Event
#               ausgeloest und speichert die Ergebnisse als JSON im Out-Bucket.

import json
import os
import boto3
import urllib.parse

s3 = boto3.client("s3")
rekognition = boto3.client("rekognition")


def lambda_handler(event, context):
    bucket_in = event["Records"][0]["s3"]["bucket"]["name"]
    key = urllib.parse.unquote_plus(event["Records"][0]["s3"]["object"]["key"])

    # Out-Bucket aus Umgebungsvariable lesen (Fallback: String-Ersetzung)
    bucket_out = os.environ.get("BUCKET_OUT", bucket_in.replace("-in-", "-out-"))

    response = rekognition.recognize_celebrities(
        Image={"S3Object": {"Bucket": bucket_in, "Name": key}}
    )

    result = {
        "photo": key,
        "celebrities": [],
        "unrecognized_faces": response.get("UnrecognizedFaces", []),
    }

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

    output_key = key.rsplit(".", 1)[0] + ".json"

    s3.put_object(
        Bucket=bucket_out,
        Key=output_key,
        Body=json.dumps(result, indent=2),
        ContentType="application/json",
    )

    return {"statusCode": 200, "body": json.dumps(result)}

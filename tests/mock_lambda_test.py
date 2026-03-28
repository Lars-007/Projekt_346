# mock_lambda_test.py
# Autoren: Lars Hellstern, Joel Mazurek, Nazar Tobilevych
# Datum:   März 2026
# Modul:   M346 – Cloudlösungen konzipieren und realisieren
# Schule:  IMS St. Gallen
#
# Beschreibung:
#   Unit-Tests für die Lambda-Funktion (lambda_function.py).
#   Die Tests verwenden Mocks für die AWS-Services (Rekognition, S3),
#   sodass kein AWS-Zugang für die Ausführung benötigt wird.
#
# Verwendung:
#   python -m pytest tests/mock_lambda_test.py -v
#   oder: python -m unittest tests/mock_lambda_test.py -v
#
# Quellen:
#   - Python unittest.mock: https://docs.python.org/3/library/unittest.mock.html
#   - Boto3 Rekognition: https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/rekognition.html

import json
import unittest
from unittest.mock import MagicMock, patch
import sys
import os

# Mock für boto3 erstellen, damit der Import von lambda_function nicht fehlschlägt,
# auch wenn boto3 nicht lokal installiert ist.
mock_boto3 = MagicMock()
sys.modules['boto3'] = mock_boto3

# Lambda-Verzeichnis zum Suchpfad hinzufügen
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'lambda'))


class TestLambdaFunction(unittest.TestCase):
    """Unit-Tests für die FaceRecognition Lambda-Funktion."""

    def setUp(self):
        """Vor jedem Test: Mock zurücksetzen und lambda_function neu laden."""
        mock_boto3.reset_mock()
        if 'lambda_function' in sys.modules:
            import importlib
            import lambda_function
            importlib.reload(lambda_function)
        import lambda_function
        self.lambda_function = lambda_function

    @patch('lambda_function.rekognition')
    @patch('lambda_function.s3')
    def test_celebrity_erkannt(self, mock_s3, mock_rekognition):
        """Test: Bekannte Person wird korrekt erkannt und JSON gespeichert."""
        # Mock: Rekognition gibt Roger Federer mit 99.87% Confidence zurück
        mock_rekognition.recognize_celebrities.return_value = {
            "CelebrityFaces": [
                {
                    "Name": "Roger Federer",
                    "MatchConfidence": 99.87,
                    "Id": "2GaLwk7K",
                    "Urls": ["www.imdb.com/name/nm1846919"],
                    "Face": {
                        "BoundingBox": {
                            "Width": 0.4521,
                            "Height": 0.6032,
                            "Left": 0.2897,
                            "Top": 0.1245
                        }
                    }
                }
            ],
            "UnrecognizedFaces": []
        }

        # Simuliertes S3-Event (wird normalerweise von AWS ausgelöst)
        event = {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": "test-in-bucket"},
                        "object": {"key": "roger_federer.jpg"}
                    }
                }
            ]
        }

        # Lambda-Handler aufrufen
        response = self.lambda_function.lambda_handler(event, None)

        # Prüfungen
        self.assertEqual(response['statusCode'], 200,
                         f"Erwartet 200, erhalten {response['statusCode']}. Body: {response['body']}")
        body = json.loads(response['body'])
        self.assertEqual(body['status'], 'success')
        self.assertEqual(body['photo'], 'roger_federer.jpg')
        self.assertEqual(len(body['celebrities']), 1)
        self.assertEqual(body['celebrities'][0]['name'], 'Roger Federer')
        self.assertGreaterEqual(body['celebrities'][0]['confidence'], 99.0)

        # Prüfen, ob S3.put_object mit korrekten Parametern aufgerufen wurde
        mock_s3.put_object.assert_called_once()
        call_args = mock_s3.put_object.call_args[1]
        self.assertEqual(call_args['Bucket'], 'test-out-bucket')
        self.assertEqual(call_args['Key'], 'roger_federer.json')

    @patch('lambda_function.rekognition')
    @patch('lambda_function.s3')
    def test_keine_celebrity_erkannt(self, mock_s3, mock_rekognition):
        """Test: Foto ohne bekannte Person ergibt leere Celebrity-Liste."""
        mock_rekognition.recognize_celebrities.return_value = {
            "CelebrityFaces": [],
            "UnrecognizedFaces": [
                {"BoundingBox": {"Width": 0.3, "Height": 0.4, "Left": 0.1, "Top": 0.2}}
            ]
        }

        event = {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": "test-in-bucket"},
                        "object": {"key": "unbekannt.jpg"}
                    }
                }
            ]
        }

        response = self.lambda_function.lambda_handler(event, None)

        self.assertEqual(response['statusCode'], 200)
        body = json.loads(response['body'])
        self.assertEqual(body['status'], 'success')
        self.assertEqual(len(body['celebrities']), 0)
        self.assertEqual(len(body['unrecognized_faces']), 1)

    @patch('lambda_function.rekognition')
    @patch('lambda_function.s3')
    def test_leere_records(self, mock_s3, mock_rekognition):
        """Test: Event ohne Records liefert StatusCode 400."""
        event = {"Records": []}

        response = self.lambda_function.lambda_handler(event, None)

        self.assertEqual(response['statusCode'], 400,
                         "Leeres Records-Array sollte HTTP 400 zurückgeben.")

    @patch('lambda_function.rekognition')
    @patch('lambda_function.s3')
    def test_api_fehler(self, mock_s3, mock_rekognition):
        """Test: Rekognition-API-Fehler wird korrekt abgefangen."""
        mock_rekognition.recognize_celebrities.side_effect = Exception("API Test Error")

        event = {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": "test-in-bucket"},
                        "object": {"key": "error.jpg"}
                    }
                }
            ]
        }

        response = self.lambda_function.lambda_handler(event, None)

        self.assertEqual(response['statusCode'], 500,
                         f"Erwartet 500, erhalten {response['statusCode']}. Body: {response['body']}")
        body = json.loads(response['body'])
        self.assertEqual(body['status'], 'error')
        self.assertIn("API Test Error", body['message'])

    @patch('lambda_function.rekognition')
    @patch('lambda_function.s3')
    def test_url_encoding_im_dateinamen(self, mock_s3, mock_rekognition):
        """Test: URL-kodierte Dateinamen (z.B. Leerzeichen) werden korrekt verarbeitet."""
        mock_rekognition.recognize_celebrities.return_value = {
            "CelebrityFaces": [],
            "UnrecognizedFaces": []
        }

        # '+' steht für Leerzeichen in URL-Encoding (S3-Events)
        event = {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": "test-in-bucket"},
                        "object": {"key": "mein+foto.jpg"}
                    }
                }
            ]
        }

        response = self.lambda_function.lambda_handler(event, None)

        self.assertEqual(response['statusCode'], 200)
        body = json.loads(response['body'])
        # unquote_plus sollte '+' in Leerzeichen umwandeln
        self.assertEqual(body['photo'], 'mein foto.jpg')


if __name__ == '__main__':
    unittest.main()

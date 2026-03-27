import json
import unittest
from unittest.mock import MagicMock, patch
import sys
import os

# Create a temporary mock for boto3 so the import of lambda_function doesn't fail
# even if boto3 wasn't installed (though it is now)
mock_boto3 = MagicMock()
sys.modules['boto3'] = mock_boto3

# Add the lambda directory to sys.path to import the lambda_function
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'lambda'))

class TestLambdaFunction(unittest.TestCase):
    def setUp(self):
        # Reset the mock before each test if needed
        mock_boto3.reset_mock()
        # Ensure lambda_function is reloaded or at least the handler is accessible
        if 'lambda_function' in sys.modules:
            import importlib
            import lambda_function
            importlib.reload(lambda_function)
        import lambda_function
        self.lambda_function = lambda_function

    @patch('lambda_function.rekognition')
    @patch('lambda_function.s3')
    def test_lambda_handler_success(self, mock_s3, mock_rekognition):
        # Mock Rekognition response
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

        # Mock S3 event
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

        # Call the handler
        response = self.lambda_function.lambda_handler(event, None)

        # Assertions
        self.assertEqual(response['statusCode'], 200, f"Expected 200 but got {response['statusCode']}. Body: {response['body']}")
        body = json.loads(response['body'])
        self.assertEqual(body['status'], 'success')
        self.assertEqual(body['photo'], 'roger_federer.jpg')
        self.assertEqual(len(body['celebrities']), 1)
        self.assertEqual(body['celebrities'][0]['name'], 'Roger Federer')

        # Verify S3.put_object was called
        mock_s3.put_object.assert_called_once()
        call_args = mock_s3.put_object.call_args[1]
        self.assertEqual(call_args['Bucket'], 'test-out-bucket')
        self.assertEqual(call_args['Key'], 'roger_federer.json')

    @patch('lambda_function.rekognition')
    @patch('lambda_function.s3')
    def test_lambda_handler_error(self, mock_s3, mock_rekognition):
        # Setup mock to raise an exception
        mock_rekognition.recognize_celebrities.side_effect = Exception("API Test Error")

        # Mock S3 event
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

        # Call the handler
        response = self.lambda_function.lambda_handler(event, None)

        self.assertEqual(response['statusCode'], 500, f"Expected 500 but got {response['statusCode']}. Body: {response['body']}")
        body = json.loads(response['body'])
        self.assertEqual(body['status'], 'error')
        self.assertIn("API Test Error", body['message'])

if __name__ == '__main__':
    unittest.main()

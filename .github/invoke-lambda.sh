#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "Invoking lambda..."

response=$(aws lambda invoke \
  --function-name "$LAMBDA_FUNCTION_NAME" \
  --cli-binary-format raw-in-base64-out \
  --no-paginate \
  --payload '{
    "version": "2.0",
    "routeKey": "GET /api/health",
    "rawPath": "/api/health",
    "rawQueryString": "",
    "headers": {
      "accept": "text/html",
      "x-forwarded-proto": "https"
    },
    "requestContext": {
      "http": {
        "method": "GET",
        "path": "/api/health"
      }
    }
  }' \
  --output json /dev/stdout | tr -d '\0')

status_code=$(echo "$response" | jq -s '.[0].statusCode // empty')

echo "Lambda response:"
echo "$response" | jq .

if [ -z "$status_code" ]; then
  echo "Error: No status code returned from Lambda."
  exit 1
fi

if [ "$status_code" -ne 200 ]; then
  echo "Error: Lambda returned status code: $status_code"
  exit 1
fi

echo "Success: Lambda is healthy!"

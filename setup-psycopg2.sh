#!/bin/bash

# Install psycopg2 using pip (system pip)
/usr/local/bin/pip install psycopg2-binary 2>/dev/null || true

# Run the original entrypoint
exec /app/docker/entrypoint.sh

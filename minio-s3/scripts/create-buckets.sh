#!/bin/sh

# Wait for MinIO to be ready
until /usr/bin/mc alias set minio http://minio:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD; do
  echo "Waiting for MinIO server..."
  sleep 1
done

echo "MinIO is ready. Creating buckets..."

# Create buckets using MinIO Client
mc mb minio/test-bucket
mc mb minio/backups

echo "Buckets created successfully:"
mc ls minio
# MinIO S3 Storage Stack

This setup provides a local S3-compatible object storage using MinIO. It's ideal for development, testing, and as a private S3 alternative.

## What is S3?

Amazon S3 (Simple Storage Service) is an object storage service that offers industry-leading scalability, data availability, security, and performance. This MinIO implementation provides S3-compatible API endpoints.

## Setup

1. Start MinIO:
```bash
cd minio-s3
docker-compose up -d
```

2. Access Points:
- **Console**: http://localhost:9001
- **Browser**: http://localhost:9002
- **API Endpoint**: http://localhost:9000

## Default Credentials

- **Username**: minioadmin
- **Password**: minioadmin123

⚠️ **Important**: Change these credentials in production!

## S3 Usage

### Using AWS CLI

```bash
# Configure AWS CLI to use local MinIO
aws configure
# Set:
#   AWS Access Key ID: minioadmin
#   AWS Secret Access Key: minioadmin123
#   Default region: us-east-1
#   Default output format: json

# List buckets
aws s3 ls --endpoint-url http://localhost:9000

# Create bucket
aws s3 mb s3://test-bucket --endpoint-url http://localhost:9000

# Upload file
aws s3 cp file.txt s3://test-bucket/ --endpoint-url http://localhost:9000

# List files in bucket
aws s3 ls s3://test-bucket/ --endpoint-url http://localhost:9000
```

### Using SDKs

Most AWS SDKs can connect to MinIO by setting the endpoint URL:

**Python (boto3)**
```python
import boto3

s3 = boto3.client(
    's3',
    endpoint_url='http://localhost:9000',
    aws_access_key_id='minioadmin',
    aws_secret_access_key='minioadmin123',
    region_name='us-east-1'
)
```

**Node.js (aws-sdk)**
```javascript
const AWS = require('aws-sdk');

const s3 = new AWS.S3({
  endpoint: 'http://localhost:9000',
  accessKeyId: 'minioadmin',
  secretAccessKey: 'minioadmin123',
  s3ForcePathStyle: true,
  signatureVersion: 'v4'
});
```

## Configuration

### Environment Variables

Edit `.env` file to customize:
- `MINIO_ROOT_USER`: S3 access key
- `MINIO_ROOT_PASSWORD`: S3 secret key
- `MINIO_CONSOLE_PORT`: Console web UI port
- `MINIO_BROWSER_PORT`: Browser web UI port
- `MINIO_API_PORT`: API endpoint port

### Storage Volumes

- `minio_data1` and `minio_data2`: Persistent storage for MinIO data
- Data persists when containers are restarted

## Buckets

Pre-configured buckets:
- `test-bucket`: General purpose storage
- `backups`: Backup storage

## Security Best Practices

1. **Change default credentials** - Update in `.env` file
2. **Use HTTPS in production** - Configure SSL/TLS
3. **Enable bucket policies** - Set access controls
4. **Regular backups** - MinIO supports replication
5. **Monitoring** - Enable MinIO metrics

## Common Commands

```bash
# View logs
docker-compose logs -f minio

# Stop services
docker-compose down

# Remove volumes (data will be lost)
docker-compose down -v

# Update to latest version
docker-compose pull
docker-compose up -d
```

## S3 Compatibility

MinIO is API-compatible with Amazon S3:
- 100% S3 API compatibility
- Supports S3 bucket policies
- Supports S3 lifecycle policies
- Supports versioning
- Supports cross-region replication

Use this setup for:
- Local development
- Testing S3 applications
- Private S3 alternative
- Cost-effective storage
- Data lake storage
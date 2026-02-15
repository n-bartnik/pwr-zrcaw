import boto3
import io
from PIL import Image
s3 = boto3.client('s3')

def lambda_handler(event, context):
    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        key = record['s3']['object']['key']

        print(f"Processing file: {key} from bucket: {bucket_name}")

        try:
            head_response = s3.head_object(Bucket=bucket_name, Key=key)
            metadata = head_response.get('Metadata', {})
            
            if metadata.get('compressed') == 'true':
                print(f"File {key} is already compressed. Skipping.")
                continue

            file_obj = s3.get_object(Bucket=bucket_name, Key=key)
            file_content = file_obj['Body'].read()

            image = Image.open(io.BytesIO(file_content))
            
            if image.mode in ("RGBA", "P"):
                image = image.convert("RGB")

            output_buffer = io.BytesIO()
            image.save(output_buffer, format='JPEG', quality=70, optimize=True)
            output_buffer.seek(0)

            s3.put_object(
                Bucket=bucket_name,
                Key=key,
                Body=output_buffer,
                ContentType='image/jpeg',
                Metadata={'compressed': 'true'}
            )
            print(f"Successfully compressed and uploaded {key}")

        except Exception as e:
            print(f"Error processing {key}: {str(e)}")
            raise e
            
    return {
        'statusCode': 200,
        'body': 'Image processing complete'
    }
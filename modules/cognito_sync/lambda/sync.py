import os
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dr_region = os.environ.get('DR_REGION')
dr_user_pool_id = os.environ.get('DR_USER_POOL_ID')

cognito_client = boto3.client('cognito-idp', region_name=dr_region)

def lambda_handler(event, context):
    logger.info(f"Received event: {event}")
    try:
        user_attributes = event['request']['userAttributes']
        username = event['userName']
        
        # Prepare attributes for DR region
        sync_attributes = []
        for key, value in user_attributes.items():
            if key not in ['sub', 'email_verified', 'phone_number_verified', 'cognito:user_status']:
                sync_attributes.append({'Name': key, 'Value': value})
                
        try:
            # Check if user exists in DR region
            cognito_client.admin_get_user(
                UserPoolId=dr_user_pool_id,
                Username=username
            )
            # User exists, update attributes
            if sync_attributes:
                cognito_client.admin_update_user_attributes(
                    UserPoolId=dr_user_pool_id,
                    Username=username,
                    UserAttributes=sync_attributes
                )
            logger.info(f"Updated user {username} in DR region")
            
        except cognito_client.exceptions.UserNotFoundException:
            # User doesn't exist, create them
            cognito_client.admin_create_user(
                UserPoolId=dr_user_pool_id,
                Username=username,
                UserAttributes=sync_attributes,
                MessageAction='SUPPRESS' # Don't send welcome email
            )
            logger.info(f"Created user {username} in DR region")
            
    except Exception as e:
        logger.error(f"Error syncing user to DR region: {str(e)}")
        # Do not fail the auth flow
        pass
        
    return event

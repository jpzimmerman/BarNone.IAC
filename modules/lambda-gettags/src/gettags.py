import boto3
import logging
import pymysql

#rds settings
rds_host  = "cocktails.ckluxbyrn4cp.us-east-1.rds.amazonaws.com"
username = "dbuser"
db_name = "cocktails"

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('rds',region_name='us-east-1')
token = client.generate_db_auth_token(rds_host,3306, username)
ssl = {'ca': 'us-east-1-bundle.pem'} 


def handler(event, context):
    conn = pymysql.connect(host=rds_host, user=username, passwd=token, db=db_name, connect_timeout=30,ssl=ssl)
    cursor = conn.cursor()
    cursor.execute("call GetTags()")
    final = []
    workinglist = list(cursor.fetchall())
    for item in workinglist:
        final.append(item[0])
    conn.close()
    return final

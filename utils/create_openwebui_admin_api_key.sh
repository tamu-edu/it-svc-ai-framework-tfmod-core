#!/usr/bin/env bash

LOG_FILE="/tmp/create_openwebui_admin_api_key.log"
FAILED=0
rm -f $LOG_FILE

# Authenticate to Cloudflare and get an access token
echo "Authenticating to Cloudflare and getting an access token" >> $LOG_FILE
CF_ACCESS_TOKEN=$(curl -X GET "https://${OPENWEBUI_FQDN}" \
  -H "Accept: application/json" \
  -H "CF-Access-Client-Id: ${CF_ACCESS_CLIENT_ID}" \
  -H "CF-Access-Client-Secret: ${CF_ACCESS_CLIENT_SECRET}" \
 -sS --dump-header - -o /dev/null | grep "CF_Authorization=" | \
 sed 's/set-cookie: //g' | cut -d';' -f1)
 if [ $? -ne 0 ]
then
  echo "Failed to authenticate to Cloudflare and get an access token" >> $LOG_FILE
  FAILED=1
else
  echo "Successfully authenticated to cloudflare and got access token" >> $LOG_FILE
fi
 
 # Sign up for an account
 echo "Signing up for an OpenWebUI account" >> $LOG_FILE
 SIGNUP_RES=$(curl \
  -X POST "https://${OPENWEBUI_FQDN}/api/v1/auths/signup" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -H "cookie: ${CF_ACCESS_TOKEN}" \
  --silent \
  -w "%{http_code}" \
  -d "{ \"email\": \"${OPENWEBUI_EMAIL}\", \"password\": \"${OPENWEBUI_PASSWORD}\", \"name\": \"Admin\" }" 2>&1 | tee -a $LOG_FILE)
  if [[ $? -eq 0 ]] && echo $SIGNUP_RES | egrep '200$|400$' > /dev/null
  then
    echo "" >> $LOG_FILE
    echo "Successfully signed up for an OpenWebUI account" >> $LOG_FILE
  else
    echo "" >> $LOG_FILE
    echo "Failed to sign up for an OpenWebUI account" >> $LOG_FILE
    FAILED=1
  fi

# Start a cloudflared session to access the database
echo "Starting cloudflared session to access the database" >> $LOG_FILE
cloudflared access tcp --hostname ${PSQL_FQDN} \
  --url tcp://127.0.0.1:5432 \
  --logfile $LOG_FILE \
  --service-token-id ${CF_ACCESS_CLIENT_ID} \
  --service-token-secret ${CF_ACCESS_CLIENT_SECRET} 2>&1 >> $LOG_FILE &
CLOUDFLARED_PID=$!
sleep 5

echo "Setting the API key for the admin user" >> $LOG_FILE
SQL="update public.user set api_key='${OPENWEBUI_API_KEY}' where email='admin@admin.com';"
export PGPASSWORD="${PSQL_PASSWORD}"
echo "$SQL" | psql -h localhost -U ${PSQL_USERNAME} -d ${PSQL_DB} 2>&1 >> $LOG_FILE
if [ $? -ne 0 ]
then
  echo "Failed to set the API key for the admin user" >> $LOG_FILE
  FAILED=1
else
  echo "Successfully set the API key for the admin user" >> $LOG_FILE
fi

echo "Killing cloudflared session" >> $LOG_FILE
kill $CLOUDFLARED_PID 2>&1 >> $LOG_FILE
echo "Returning $FAILED" >> $LOG_FILE
exit $FAILED

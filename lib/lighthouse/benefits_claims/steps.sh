# !/bin/sh

# Generate the key pair
#openssl rsa -in key.pem -outform PEM -pubout -out public.pem

# Generate the jwk pair
#step crypto jwk create jwk.pub.json jwk.json --from-pem private.pem --alg RS256

# gdate is part of the 'coreutils' brew package
iat=`gdate +%s`
exp=`expr $iat + 300`

client_id='0oaj7q9k0sGIrkXZC2p7'

# Generate the unsigned json
cat <<EOF > unsigned.json
{
    "aud": "https://deptva-eval.okta.com/oauth2/ausdg7guis2TYDlFe2p7/v1/token",
    "iss": $client_id,
    "sub": $client_id,
    "iat": $iat,
    "exp": $exp
}
EOF

client_assertion=`step crypto jwt sign unsigned.json --alg=RS256 --key=key.pem --subtle`

access_token=`curl -s --location --request POST 'https://sandbox-api.va.gov/oauth2/claims/system/v1/token' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=client_credentials' \
  --data-urlencode 'client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer' \
  --data-urlencode "client_assertion=$client_assertion" \
  --data-urlencode 'scope=claim.read claim.write' | jq -rj '.access_token'`

echo $access_token
echo $access_token | pbcopy

curl -X GET 'https://staging-api.va.gov/services/claims/v2/veterans/1012667145V762142/claims' \
  --header "Authorization: Bearer $access_token"

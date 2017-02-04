#!/bin/bash

# You need a KMS master key and a key alias to run these tests. We don't create
# them automatically because they can take up-to 7 days to delete. Create your
# own and pass it to this script.
#
#  aws kms create-key --query KeyMetadata.KeyId --output text
#  aws kms create-alias --alias-name alias/kms-test --target-key-id <key-id>

key_alias='alias/kms-test'
failed=0
total=0

function assert() {
  local actual=$1
  local expected=$2

  total=$((total + 1))
  if [[ "$actual" == "$expected" ]]; then
    echo -e ' ↳ \033[92mPass\033[0m'
  else
    echo -e ' ↳ \033[31mFail\033[0m'
    echo -e "   Expected: \033[92m$expected\033[0m"
    echo -e "   Actual:   \033[31m$actual\033[0m"
    failed=$((failed + 1))
  fi
}

function testKmsEncryption() {
  local description=$1
  local secret=$2

  echo -e "\033[1m$description\033[0m"

  echo
  echo 'Encrypt with argument, decrypt with stdin'
  local output=$(./kms-encrypt "$key_alias" "$secret" | ./kms-decrypt | base64 --decode)
  assert $output $secret

  echo
  echo 'Encrypt with argument, decrypt with argument'
  local encrypted=$(./kms-encrypt "$key_alias" "$secret")
  local output=$(./kms-decrypt "$encrypted" | base64 --decode)
  assert $output $secret

  echo
  echo 'Encrypt with stdin, decrypt with stdin'
  local output=$(echo -n "$secret" | ./kms-encrypt "$key_alias" | ./kms-decrypt | base64 --decode)
  assert $output $secret

  echo
  echo 'Encrypt with stdin, decrypt with argument'
  local encrypted=$(echo -n "$secret" | ./kms-encrypt "$key_alias")
  local output=$(./kms-decrypt "$encrypted" | base64 --decode)
  assert $output $secret
}

function testEnvelopeEncryption() {
  local description=$1
  local secret=$2
  local output=""

  local data_key=$(./kms-generate-data-key "$key_alias")
  if [ $? -ne 0 ]; then
    echo -e '\033[31mFailed to generate data key\033[0m'
    exit 1
  fi

  echo -e "\033[1m$description\033[0m"

  echo
  echo 'Encrypt with argument, decrypt with stdin'
  local output=$(./kms-envelopeencrypt "$data_key" "$secret" | ./kms-envelopedecrypt "$data_key")
  assert "$output" "$secret"

  echo
  echo 'Encrypt with argument, decrypt with argument'
  local encrypted=$(./kms-envelopeencrypt "$data_key" "$secret")
  local output=$(./kms-envelopedecrypt "$data_key" "$encrypted")
  assert "$output" "$secret"

  echo
  echo 'Encrypt with stdin, decrypt with stdin'
  local output=$(echo -n "$secret" | ./kms-envelopeencrypt "$data_key" | ./kms-envelopedecrypt "$data_key")
  assert "$output" "$secret"

  echo
  echo 'Encrypt with stdin, decrypt with argument'
  local encrypted=$(echo -n "$secret" | ./kms-envelopeencrypt "$data_key")
  local output=$(./kms-envelopedecrypt "$data_key" "$encrypted")
  assert "$output" "$secret"
}

short="y=rCh\""
medium="y=rCh\"ni|Rt<0bp)9K^?Ax%05vugpyIc|"
long="y=rCh\"ni|Rt<0bp)9K^?Ax%05vugpyIc|6ayWM8ju4KG'Cj9dnCy+2?Xl\$4*0*lE1p;oHkC\rm^2GD3@|rMf_?/0p/sK'/|!(1+P7iBlaV3uUq[J]vX@J$:U@Y3uk',7dZ~u:3e6pT(*W[+79!2{FbgQH4fx(+rRcT[YSM#[em^|Yn>%:t*SdU3!*~1hAqBuRT_CQ]XZIs-<X7\`PbS:\`Wr\$d7b$\`5\"Gjc9/i1hcmLAHY#1k%s7ziH\sT}H<=Z|9!/70JE^+%?Wi)^ME8'HoiA/feHRHxThy&\IXX/ClAw4|mx&Q:lrKq6]:L>~}u>?kV@qT^UXM:o\$B?>'w-s}J1BO;+3\W9l~K[Pm)~zncjF[-(Cx%*\`_b@Xv4C}ErfE>/iTraqk5|]yXUG8&it"

echo -e '\033[4mKMS Master Encryption\033[0m'
echo
testKmsEncryption 'Short plaintext' $short
echo
testKmsEncryption 'Medium length plaintext' $short
echo
testKmsEncryption 'Long plaintext' $long

echo
echo -e '\033[4mKMS Envelope Encryption\033[0m'
echo
testEnvelopeEncryption 'Short length plaintext' $short
echo
testEnvelopeEncryption 'Medium length plaintext' $short
echo
testEnvelopeEncryption 'Long length plaintext' $long

echo
echo $((total - failed)) of $total passed, $failed failed
exit $failed

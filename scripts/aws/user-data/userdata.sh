#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Variables to construct host name and assign chef policy/group
PREFIX='svc' # Account code for environment see xcel aws naming standard
OS_CODE='l' # OS code for operating system l=linux, w=windows, b-bsd
UNIQUE_NAME='tfe' # 4 Character unique portion of HOST NAME
NUMBER="$(curl --silent --show-error --retry 3 http://169.254.169.254/latest/meta-data/instance-id | cut -c 3-)" # HOSTNAME incrementing number starting at 001 for prod and 501 for non-pod
POLICY_NAME="xe_base_linux_role" # Chef Policy applied to instance
POLICY_GROUP='non-prod' # Chef Policy Group applied to the instance
CHEF_CLIENT_VERSION="$(curl -L -s https://api.github.com/repos/chef/chef/tags | grep name | sed "s/ *\"name\": *\"v\\(.*\\)\",*/\\1/" | grep -v -E "(alpha|beta|rc)[0-9]$" | sort -t"." -k 1,1 -k 2,2 -k 3,3 -k 4,4 | tail -n 1 | cut -c -2)" # Major version of chef to install

AZ_LONG="$(curl --silent --show-error --retry 3 http://169.254.169.254/latest/meta-data/placement/availability-zone)"
AZ_LETTER=${AZ_LONG: -1}

IFS='-'
read -ra SPLIT <<< "$AZ_LONG"
REGION="a${SPLIT[1]::1}${SPLIT[2]::1}"

NODE_NAME="${PREFIX}${REGION}${AZ_LETTER}${OS_CODE}${UNIQUE_NAME}${NUMBER}"

# Do some chef pre-work
/bin/mkdir -p /etc/chef/trusted_certs
/bin/mkdir -p /var/lib/chef
/bin/mkdir -p /var/log/chef

cd /etc/chef/

# Install chef
curl -L https://omnitruck.chef.io/install.sh | bash -s -- -v "${CHEF_CLIENT_VERSION}" || error_exit 'could not install chef'

# Create first-boot.json
cat <<EOF > "/etc/chef/first-boot.json"
{
  "name": "${NODE_NAME}",
  "chef_environment": null,
  "policy_name": "${POLICY_NAME}",
  "policy_group": "${POLICY_GROUP}"
}
EOF

# Create validator file
cat <<-EOF > /etc/chef/validator.pem
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEA58lUAs+QtoTwl5+UDBwvjkQagEDyYdKos5D+sHkflZPznaPb
DSLGqqn0bnPCoOgrvVsDTkV4PDdpkwuDVYmtUx+2kjkGUV6zylRisWkvTiXpiv2W
bdH6lQmYQpW/dZUVYH4mU5vbv3N3NCr3963Z+ex8DxnPU+fXh4BqGAeUoQLZXvwT
/zLBgG4tcFTEwVA7OPTi7TWT5unV7AabFuGu8+STgHv+pDItvEjDFiflYVXM2OO6
Z4JQuiiyTEPg78xj8QGTchk24OECpLtc+Cly3rPPF1wenm01+/rU26Im+WMw9mGG
rSSLfWzBMLSelikbBQwfgsQXoprTK5t7yA0eDQIDAQABAoIBAHgYu/vc2omHpjWZ
zJbdv9JB/U042Z3QDfNEjIKZr8DL8S1b6jMLMs7Y0rqsJktDIO6zCqpymlLxDzXO
gFVAydrJEsr+2wQsQpHyWVS9QHKIeFK5BEmQw/qXBxpxBswA3BusIWWu2xR+2mPg
Y60kmk3Bt6IHaIJ8HROreM1MmDk4CSMpUeytPnsqBadoGBR8NWfv5R72UDOXKAly
77k2XjSc8AS+vlbCMgmF9GPqwV5BOWmywAx/a2F9tctzXXSl4MQNk4vpQt80z+RT
aiSPhiuRGYxqCfJJUGaRxoxSlmpHkh/yEhfjn8WMBdjFjfZjEflCGyENWOyq0DAC
QYbTY60CgYEA+455aPZxQ5qPCC36Rry7uTO1L0aPausMn+mwQBHhZDDJQc/AxURM
nRXJHazoiAxQCrf63OPR25eS07NNggHFJ7z4lKh23/h3+fYHapuREg5uEWAbIYul
QHnqWtazIFsAl7pa87Zu6TDif1AleYAoYSKUfexun8LrB5S2s+D5nicCgYEA6+F0
W8jqLaSM6X6m4XehOhcfFI7DLR+agln6T64J6JkAKLf0mElA1UOzZtLh06QGtAQn
pN1qD06mXsA3auTdrWiaBHfkCwRtac4+Wcf5ll6bDvd7M5uO6BjfQvJPvMiDTKpA
Sr2sBj3TWhvhTmo2bkvznw99GcXFEFDYkj9R9qsCgYEA5elvuakUGA+ZDobHKgOx
JzHFNTIuPjAZ18YD2mr9L08PgmDY9PLZevDAYaj41e868LD6TQzDbwn3nhlQi7QG
d61VHLlj/IvhS8m7OYp5aqFZo/PMmDpDjMxgjymPidDil8ow+nIQqHyPZoDf305s
mWq7gOOor8e8e69F1N2YBx0CgYEAsMvWK+lmZHl+SJBuQnYo+OJVoFH0xkB2zZbl
P42hzZ3H+b0PbokROAe7UqljK/84KvsmP7LZCMoZdtE5eDw8Tvok3o6B9SQHYhN8
tkxlrSgRrmEeDatdrGbgCEyYKVZc2zyMXbjWVANJA7P75otDat4wppq0WHncX4NJ
ICynoWsCgYEArJ6cHGHq6/DN2BKqJC7JiK/6c2c7bZ1kiZPuM+yBLk3WMivpWyTo
hjqDu5yS32cKte2cucrm938Z+jN2gyoMO9Z5eBj0+BLz2he0U15D4RvaTgVfNhbo
RNQ4QUm4fRgNSta7ug+e4QuU+LgW0MTOwAYteJMlaOeehBM07npOEM4=
-----END RSA PRIVATE KEY-----
EOF

# Create client.rb
cat <<-EOF > /etc/chef/client.rb
chef_license "accept"
log_location STDOUT
chef_server_url "https://chef-server.aws.xcelenergy.net/organizations/xcel"
validation_client_name "xcel-validator"
validation_key "/etc/chef/validator.pem"
node_name "${NODE_NAME}"
verify_api_cert false
ssl_verify_mode :verify_none
trusted_certs_dir "/etc/chef/trusted_certs_dir"
EOF

# Run chef-client
sudo chef-client -c /etc/chef/client.rb -j /etc/chef/first-boot.json

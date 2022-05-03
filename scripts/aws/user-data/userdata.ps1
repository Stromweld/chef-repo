<powershell>
# Variables
$prefix = 'sbx' # Account code for environment see xcel aws naming standard
$osCode = 'w' # OS code for operating system l=linux, w=windows, b-bsd
$uniqueName = 'eksw' # 4 Character unique portion of HOST NAME
$number = "$((Invoke-WebRequest http://169.254.169.254/latest/meta-data/local-ipv4 -UseBasicParsing) -replace '.', '-')" # HOSTNAME incrementing number starting at 001 for prod and 501 for non-pod
$policyName = 'xe_base_windows_role' # Chef Policy applied to instance
$policyGroup = 'non-prod' # Chef Policy Group applied to the instance
$chefClientVersion = '15' # Major version of chef to install

# Get availability zone letter
$azLong = "$(Invoke-WebRequest http://169.254.169.254/latest/meta-data/placement/availability-zone)"
$azLetter = $azLong.Substring($azLong.Length - 1)

# Convert region to short form
$reg = $azLong.Split('-')
$dc = $reg[1].SubString(0,1)
$dcNum = $reg[2].SubString(0,1)
$region = "a$dc$dcNum"

## Create client.rb
$nodeName = "$prefix$region$azLetter$osCode$uniqueName$number"

## Install the Chef Client
. { iwr -useb https://omnitruck.chef.io/install.ps1 } | iex; install -project chef -version "$chefClientVersion"

## Create first-boot.json
$firstboot = @{
  "name" = "$nodeName"
  "chef_environment" = null
  "policy_name" = "$policyName"
  "policy_group" = "$policyGroup"
}
Set-Content -Path c:\chef\first-boot.json -Value ($firstboot | ConvertTo-Json -Depth 10)

# Create validator file
$validator = @"
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
"@
Set-Content -Path c:\chef\validator.pem -Value $validator

# Create client.rb file
$clientrb = @"
chef_license "accept"
log_location STDOUT
chef_server_url "https://chef-server.aws.xcelenergy.net/organizations/xcel"
validation_client_name "xcel-validator"
validation_key "C:\chef\validator.pem"
node_name "$nodeName"
verify_api_cert false
ssl_verify_mode :verify_none
trusted_certs_dir "/etc/chef/trusted_certs_dir"
"@
Set-Content -Path c:\chef\client.rb -Value $clientrb

## Run Chef
C:\opscode\chef\bin\chef-client.bat -j C:\chef\first-boot.json
</powershell>

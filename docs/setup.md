
### Set URL ACL with netsh

The following command must be executed if you want to use the real IP address of your server instead of localhost :

    netsh http add urlacl url='http://_<ipaddress>_:_<port>_/' user=everyone sddl='D:(A;;GA;;;WD)'
    netsh http show urlacl
  

### HTTPS setup

Setting up HTTPS on your server will need to execute the following commands (Windows 2012 R2 and up) :

1. Create a GUID for your app : `$guid = ([guid]::NewGuid()).guid`
2. Create your self-signed certificate and write down the thumbprint : `$certHash = (New-SelfSignedCertificate -DnsName _<yourdnsname>_ -CertStoreLocation Cert:\LocalMachine\My).thumbprint`
3. Copy that certificate to the CA store
4. Attach your certificate to your binding : `Add-NetIPHttpsCertBinding -IpPort "<ipaddress>:<port>" -CertificateHash $certhash -CertificateStoreName "My" -ApplicationId "{$guid}" -NullEncryption $false`
5. Check with `netsh http show sslcert`


### Install PowerXaaS

Just run `.\PowerXaaS.ps1 -setup` and then start service or run `.\PowerXaaS.ps1 -start`

For monitoring purpose in a Production environment, you will have to monitor the Windows service, but you should also check on a "functionnal heartbeat", for example by requesting on given frequency the version of the API with a GET request.


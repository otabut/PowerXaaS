
### Set URL ACL with netsh

The following command must be executed if you want to use the real IP address of your server instead of localhost :

    netsh http add urlacl url='http://<ipaddress>:<port>/' user=everyone sddl='D:(A;;GA;;;WD)'
    netsh http show urlacl
  

### HTTPS setup

Setting up HTTPS on your server will need to execute the following commands (Windows 2012 R2 and up) :

1. Create a GUID for your app : `$guid = ([guid]::NewGuid()).guid`
2. Create your self-signed certificate and write down the thumbprint : `$certHash = (New-SelfSignedCertificate -DnsName <yourdnsname> -CertStoreLocation Cert:\LocalMachine\My).thumbprint`
3. Copy that certificate to the CA store
4. Attach your certificate to your binding : `Add-NetIPHttpsCertBinding -IpPort "<ipaddress>:<port>" -CertificateHash $certhash -CertificateStoreName "My" -ApplicationId "{$guid}" -NullEncryption $false`
5. Check with `netsh http show sslcert`


### Install PowerXaaS

#### Install
Just run `.\PowerXaaS.ps1 -setup -ip <ipaddress> -port <port> [-CustomLogging]`. You can choose to use custom logging function : write your own code in `Start-PXCustomLogging.ps1`

#### Start
Then, start service or run `.\PowerXaaS.ps1 -start`

#### Pause
Sometimes, if you need to modify the configuration without downtime, you may choose to quiesce incoming requests in order to avoid side effects.

In order to do that, just run `.\PowerXaaS.ps1 -pause <delay>` where `<delay>` is a number in seconds.

Server will still communicate with clients, so it will be transparent for them, unless they set a timeout shorter than the paused delay, but generally clients don't set a timeout value.

#### Stop
PowerXaaS will be cleanly stopped if you stop the Windows service or if the computer shuts down.

#### Remove
Just run `.\PowerXaaS.ps1 -remove`

### Monitoring

For monitoring purpose in a Production environment, you will have to monitor the Windows service, but you should also check on a "functionnal heartbeat", for example by requesting on given frequency the version of the API with a GET request.


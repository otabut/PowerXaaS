
### Install PowerXaaS

#### Install
Run `.\PowerXaaS.ps1 -Setup -Ip <ipaddress> -Port <port> [-Protocol <https|http>] [-CertHash <Thumbprint>] [-Start] [-CustomLogging]`.

Default protocol is HTTPS.

If you don't give a certificate thumbprint, a self-signed certificate will be used instead.

You can choose to use custom logging function : write your own code in `Start-CustomLogging.ps1`

The setup will copy files into `C:\Program files\PowerXaaS`, install the `PowerXaaS` service, set some registry keys, configure the HTTP server and copy the Powershell module to `C:\Program files\WindowsPowershell\Modules\PowerXaaS`.

#### Start
Then, start service or run `.\PowerXaaS.ps1 -Start`

#### Quiesce
Sometimes, if you need to modify the configuration without downtime, you may choose to quiesce incoming requests in order to avoid side effects.

In order to do that, just run `.\PowerXaaS.ps1 -Quiesce <delay>` where `<delay>` is a number in seconds.

Server will still communicate with clients, so it will be transparent for them, unless they set a timeout shorter than the paused delay, but generally clients don't set a timeout value.

#### Stop
PowerXaaS will be cleanly stopped if you stop the Windows service or if the computer shuts down.

#### Remove
Just run `.\PowerXaaS.ps1 -Remove`

### Monitoring

For monitoring purpose in a Production environment, you will have to monitor the Windows service, but you should also check on a "functionnal heartbeat", for example by requesting on given frequency the version of the API with a GET request.


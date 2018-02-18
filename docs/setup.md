
### Install module

Well, for that part, I assume you need no instructions :p

### Windows service or scheduled task ?

In order for PowerXaaS to run, you have several options :
  - run it interactively for testing purpose
  - create a scheduled task triggered at computer startup (there will be cmdlet for that in a future release)
  - start it as a Windows service, using SRVANY tool

For monitoring purpose in a Production environment, you will have to monitor the scheduled task or the Windows service, but you should also check on a "functionnal heartbeat", for example by requesting on given frequency the version of the API with a GET request.

### Set ACL with netsh

The following command must be executed if you want to use the real IP address of your server instead of localhost :

netsh http add urlacl url='http://+:8082/' user=everyone sddl='D:(A;;GA;;;WD)'

*where 8082 is the port you want to use, of course.

### HTTPS

`more information will come soon`


### Start

Just start PowerXaaS.ps1 with IP address and port number as parameters.

For logging purpose, you can choose between console output, log file or custom logging function (write your own code in Start-PXCustomLogging.ps1)


### Pause

Sometimes, if you need to modify the configuration without downtime, you may choose to quiesce incoming requests in order to avoid side effects.

In order to do that, just create a file named pause.<delay> in the same directory than PowerXaaS.ps1 and monitor logs. <delay> is a number in seconds. The file will automatically be removed when the delay will be over.

Server will still communicate with clients, so it will be transparent for them, unless they set a timeout shorter than the paused delay, but generally clients don't set a timeout value.


### Stop

To stop the server properly, just create a file named stop in the same directory than PowerXaaS.ps1 and monitor logs. The file will automatically be removed then.


For pausing and stopping, I'm still searching a better way to do that but I don't want to create endpoints for that cause I consider it could be a way for service denial.

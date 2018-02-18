
### What is a feature

A feature is a set of actions that will be performed by a dedicated script (and sub-scripts if needed or wanted) and exposed through one or more endpoints.

Let's say, features are a logical group of endpoints and you can have as many features as you want.


### What is an endpoint

An endpoint is a specific action requested by a client through a combination of a HTTP mehtod (GET, POST, PUT, DELETE, ...) and an URL path.

Examples :  `GET /version` or `POST /echo`


### Configuration file

With PowerXaaS, the web schema that describe features and endpoints is stored in a configuration file : PowerXaaS.conf. The format of the file is JSON. 

You should not edit the configuration file directly : the Powershell module contains cmdlets to perform all the actions you mau need.


### Auto-refresh

Each modification regarding features/endpoints are immediate and doesn't need server restart. It will be applied to next request received. 

But in oder to avoid any troubles, you can quiesce the server. For that you may need to pause requests processing. See [HTTP server commands](https://github.com/otabut/PowerXaaS/blob/master/docs/http-server-commands.md)


### Feature flag

the feature flag is the ability to dynamically activate or deactivate a whole feature. You can to that with `Enable-PXFeature` and `Disable-PXFeature`.



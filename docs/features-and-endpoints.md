
### What is a feature

A feature is a set of actions that will be performed by a dedicated script (and sub-scripts if needed or wanted) and exposed through one or more endpoints.

Let's say, features are a logical group of endpoints and you can have as many features as you want. Rights on features will be granted to users through roles.


### What is an endpoint

An endpoint is a specific action requested by a client through a combination of a HTTP mehtod (GET, POST, PUT, DELETE, ...) and an URL path.

Examples :  `GET /version` or `POST /echo` or `GET /addition/{op}` which allows to have parameters passed within the URL


### API version

When calling an endpoint, the client must also specify the version of the API. For instance : `/api/v1/<myEndpoint>`.

This will allow to manage several versions of your API "side-by-side", so that you can make key users test your new API (Canary testing) or easily rollback to the previous one.


### Configuration file

With PowerXaaS, the web schema that describe features and endpoints is stored in a configuration file : PowerXaaS.conf. The format of the file is JSON. 

You should not edit the configuration file directly. The Powershell module contains cmdlets to perform all the actions you may need :

    Get-PXFeature
    New-PXFeature
    Enable-PXFeature
    Disable-PXFeature
    Remove-PXFeature
    Get-PXEndpoint
    Set-PXEndpoint
    Remove-PXEndpoint

When you create a new feature with `New-PXFeature`, you can specify the `-createfile` switch so that a script template is generated to help you start writing your API code.


### Auto-refresh

Each modification regarding features/endpoints are immediate and doesn't need server restart. It will be applied to next request received but in order to avoid any troubles, you can quiesce the server. 


### Feature flag

the feature flag is the ability to dynamically activate or deactivate a whole feature. You can to that with `Enable-PXFeature` and `Disable-PXFeature`.



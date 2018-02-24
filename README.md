
[![Documentation Status](https://readthedocs.org/projects/powerxaas/badge/?version=latest)](http://powerxaas.readthedocs.io/en/latest/?badge=latest)

# PowerXaaS
Powershell module for exposing features "as a Service" through a HTTP server

## Description

PowerXaas uses .NET HTTP listener (http.sys) to serve user-defined features as standard REST API web service. 

PowerXaaS will allow you to :
  - create features
  - for each feature, create endpoints
  - add, disable (feature-flag) or remove features/endpoints dynamically with no downtime
  - manage authentication and rights
  - manage several versions of your API
  - handle HTTP standard errors
  - and much more...

## More information

### [Setup](https://github.com/otabut/PowerXaaS/blob/master/docs/setup.md)
### [Features and Endpoints](https://github.com/otabut/PowerXaaS/blob/master/docs/features-and-endpoints.md)
### [Custom features scripts](https://github.com/otabut/PowerXaaS/blob/master/docs/custom-features-scripts.md)
### [Authentication with JSON web tokens](https://github.com/otabut/PowerXaaS/blob/master/docs/json-web-tokens.md)


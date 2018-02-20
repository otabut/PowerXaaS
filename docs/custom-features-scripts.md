
### Rules

Here are the main rules to follow in order for custom scripts to run smoothly :

- the script name must be the feature name
- the script will be able to take advantage of all input parameters available in the Inputs object (see further)
- HTTP standard return codes must be managed for all scenario
- return content should be JSON or basic text


### The Inputs object

Inside the Inputs object, you will find :

- the URL path requested
- the HTTP method
- the body (if any)
- the parameters (if any) passed in the URL. Example: value of the `op` parameter for the endpoint /addition/`{op}`


### The returned object

Custom features scripts must return the following Powershell Custom Object :

`[PSCustomObject]@{ReturnCode=<3-digits standard HTTP return code>;Content=<json string>}`


### Examples

You will find an example of a custom feature script with the feature called `demo-feature`.


Function Test-JSON
{
  param(
    [Parameter(Mandatory=$true)][String]$Schema,
    [Parameter(Mandatory=$true)][String]$JSON
  )

  $ErrorActionPreference = 'stop'

  $NewtonsoftJsonPath = Resolve-Path -Path "C:\Program Files\PowerXaaS\JsonSchema\Newtonsoft.Json.dll"
  $NewtonsoftJsonSchemaPath = Resolve-Path -Path "C:\Program Files\PowerXaaS\JsonSchema\Newtonsoft.Json.Schema.dll"

  Add-Type -Path $NewtonsoftJsonPath
  Add-Type -Path $NewtonsoftJsonSchemaPath

  $source = @'
    public class Validator
    {
      public static System.Collections.Generic.IList<string> Validate(Newtonsoft.Json.Linq.JToken token, Newtonsoft.Json.Schema.JSchema schema)
      {
        System.Collections.Generic.IList<string> messages;
        Newtonsoft.Json.Schema.SchemaExtensions.IsValid(token, schema, out messages);
        return messages;
      }
    }
'@

  Add-Type -TypeDefinition $source -ReferencedAssemblies $NewtonsoftJsonPath,$NewtonsoftJsonSchemaPath

  $Token = [Newtonsoft.Json.Linq.JToken]::Parse($JSON)
  $Schema = [Newtonsoft.Json.Schema.JSchema]::Parse($Schema)
  $ErrorMessages = [Validator]::Validate($Token,$Schema)
  $IsValid = $ErrorMessages.Count -eq 0

  $Result = [PSCustomObject]@{
    IsValid = $IsValid
    ErrorCount = $ErrorMessages.Count
    ErrorMessages = $ErrorMessages
  }

  return $Result
}

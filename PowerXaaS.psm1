
# --- Expose each Private function as part of the module
foreach ($PrivateFunction in Get-ChildItem -Path "$($PSScriptRoot)\Functions\Private\*.ps1" -Verbose:$VerbosePreference)
{
    . $PrivateFunction.FullName
}


# --- Expose and export each Public function as part of the module

foreach ($PublicFunction in Get-ChildItem -Path "$($PSScriptRoot)\Functions\*.ps1" -Verbose:$VerbosePreference)
{
  . $PublicFunction.FullName
  $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($PublicFunction)
    
  # --- Support DEPRECATED functions. Ensure that we are exporting only the function name
  $DepricatedKeyword = "DEPRECATED-"
  if ($BaseName.StartsWith($DepricatedKeyword))
  {
    $BaseName = $BaseName.Trim($DepricatedKeyword)
  }

  Export-ModuleMember -Function ($BaseName)
}

# --- Clean up variables on module removal
$ExecutionContext.SessionState.Module.OnRemove = {

}

# --- Expose each function as part of the module

foreach ($function in Get-ChildItem -Path "$($PSScriptRoot)\Functions\*.ps1" -Recurse -Verbose:$VerbosePreference)
{
  . $Function.FullName
  $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($Function)
    
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

function ToArray
{
  begin
  {
    $output = @();
  }
  process
  {
    $output += $_;
  }
  end
  {
    return ,$output;
  }
}

function Test-ErrorNoTermination {
  Write-Error -Message 'Test error message with no termination' -ErrorAction 'Continue'
}

function Test-ErrorTermination {
  Write-Error -Message 'Test error message with termination' -ErrorAction 'Stop'
}

function Test-Exception {
  Throw 'Test error message'
}

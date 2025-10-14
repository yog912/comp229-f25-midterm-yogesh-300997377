Param([string]$Base = 'http://localhost:3000')

$ErrorActionPreference = 'Stop'

function Hit {
  Param(
    [ValidateSet('GET','POST','PUT','DELETE')] [string]$Method,
    [string]$Path,
    $Body
  )
  $uri = "$Base$Path"
  try {
    if ($PSBoundParameters.ContainsKey('Body') -and $null -ne $Body) {
      $resp = Invoke-WebRequest -Method $Method -Uri $uri -Body ($Body | ConvertTo-Json -Depth 8) -ContentType 'application/json' -UseBasicParsing
    } else {
      $resp = Invoke-WebRequest -Method $Method -Uri $uri -UseBasicParsing
    }
    $obj = $null
    try { $obj = $resp.Content | ConvertFrom-Json -ErrorAction Stop } catch {}
    return [pscustomobject]@{
      Method = $Method
      Path   = $Path
      Status = [int]$resp.StatusCode
      Json   = $obj
      Raw    = $resp.Content
    }
  } catch {
    return [pscustomobject]@{
      Method = $Method
      Path   = $Path
      Status = -1
      Json   = $null
      Raw    = $_.Exception.Message
    }
  }
}

# Make logs folder
$logs = Join-Path (Get-Location) 'api-test-logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null

$R = @()

# 01 GET all
$t1 = Hit GET '/api/games'
$t1Count = ($t1.Json | Measure-Object).Count
$R += [pscustomobject]@{ Test='01 GET /api/games'; Expect='200 & count>=7'; Status=$t1.Status; Pass=($t1.Status -eq 200 -and $t1Count -ge 7); Details="count=$t1Count" }
$t1.Raw | Out-File (Join-Path $logs '01_get_all.json') -Encoding utf8

# 02 GET filter
$t2 = Hit GET '/api/games/filter?genre=action'
$R += [pscustomobject]@{ Test='02 GET /api/games/filter'; Expect='200'; Status=$t2.Status; Pass=($t2.Status -eq 200); Details='items=' + ( ($t2.Json | Measure-Object).Count ) }
$t2.Raw | Out-File (Join-Path $logs '02_get_filter.json') -Encoding utf8

# 03 GET by id
$t3 = Hit GET '/api/games/0'
$R += [pscustomobject]@{ Test='03 GET /api/games/0'; Expect='200'; Status=$t3.Status; Pass=($t3.Status -eq 200); Details=($t3.Json.title) }
$t3.Raw | Out-File (Join-Path $logs '03_get_by_id.json') -Encoding utf8

# 04 POST add
$bodyPost = @{ title='Hades'; genre='Roguelike'; platform='PC'; year=2020; developer='Supergiant Games' }
$t4 = Hit POST '/api/games' $bodyPost
$postIndex = if ($t4.Json) { $t4.Json.index } else { $null }
$R += [pscustomobject]@{ Test='04 POST /api/games'; Expect='201 & index'; Status=$t4.Status; Pass=($t4.Status -eq 201 -and $null -ne $postIndex); Details="index=$postIndex" }
$t4.Raw | Out-File (Join-Path $logs '04_post.json') -Encoding utf8

# 05 PUT update
if ($null -ne $postIndex) {
  $bodyPut = @{ title='Hades (Definitive)'; genre='Roguelike'; platform='PC'; year=2020; developer='Supergiant Games' }
  $t5 = Hit PUT "/api/games/$postIndex" $bodyPut
  $R += [pscustomobject]@{ Test="05 PUT /api/games/$postIndex"; Expect='200'; Status=$t5.Status; Pass=($t5.Status -eq 200); Details=($t5.Json.game.title) }
  $t5.Raw | Out-File (Join-Path $logs '05_put.json') -Encoding utf8

  # 06 DELETE
  $t6 = Hit DELETE "/api/games/$postIndex"
  $R += [pscustomobject]@{ Test="06 DELETE /api/games/$postIndex"; Expect='200'; Status=$t6.Status; Pass=($t6.Status -eq 200); Details=($t6.Json.removed.title) }
  $t6.Raw | Out-File (Join-Path $logs '06_delete.json') -Encoding utf8
} else {
  $R += [pscustomobject]@{ Test='05 PUT /api/games/:id'; Expect='200'; Status=-1; Pass=$false; Details='Skipped (POST failed)' }
  $R += [pscustomobject]@{ Test='06 DELETE /api/games/:id'; Expect='200'; Status=-1; Pass=$false; Details='Skipped (POST failed)' }
}

# Final GET
$tf = Hit GET '/api/games'
$R += [pscustomobject]@{ Test='FINAL GET /api/games'; Expect='200'; Status=$tf.Status; Pass=($tf.Status -eq 200); Details='count=' + (($tf.Json | Measure-Object).Count) }
$tf.Raw | Out-File (Join-Path $logs 'final_get_all.json') -Encoding utf8

# Show results & write summary
$R | Format-Table -AutoSize
$R | ConvertTo-Json -Depth 6 | Out-File (Join-Path $logs 'summary.json') -Encoding utf8

# Exit with number of failures (0 = all good)
$fail = ($R | Where-Object { -not $_.Pass }).Count
if ($fail -gt 0) { exit $fail } else { exit 0 }

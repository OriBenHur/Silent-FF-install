Import-Module BitsTransfer
function GetVersion($uri)
{
	$request = Invoke-WebRequest -Uri $uri -MaximumRedirection 0 -ErrorAction Ignore
	$location = $request.Headers.Location
	$output = $location.SubString($location.LastIndexOf('/') + 1)
	$File_name = $output -replace '%20',' '
	$pattern = '[^0-9.]'
	$output = ($File_name) -replace $pattern, ''
	$output = $output.Substring(0,$output.Length-1)
	return $output, $File_name
}

################################# Setting base variables ###################################
$baseDir = Split-Path -Parent ($MyInvocation.MyCommand.Path)
$RootPath = Split-Path $baseDir -Parent
$ff_url = "https://download.mozilla.org/?product=firefox-esr-latest&os=win&lang=en-US"
$input = GetVersion $ff_url

# $firebug_url = "https://addons.mozilla.org/firefox/downloads/latest/firebug/addon-1843-latest.xpi?src=dp-btn-primary"
# $capriza_url = "https://start.capriza.com/capriza.xpi"
# $firebug_xpi = "firebug@software.joehewitt.com.xpi"
# $capriza_xpi = "designer@capriza.com.xpi"
$ff_dir =  "C:\Program Files (x86)\Mozilla Firefox Last"
# $ext_destination = "$ff_dir\browser\extensions"
$ff_exe = $input[1]
$version = $input[0]
$output = "$baseDir\$ff_exe"
$Desktop = ([Environment]::GetEnvironmentVariable("Public"))+"\Desktop"
############################################################################################



############################# Downloading the needed files #################################
$start_time = Get-Date
Start-BitsTransfer -Source $ff_url -Destination $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

# $output = "$baseDir\$firebug_xpi"
# $start_time = Get-Date
# Start-BitsTransfer -Source $firebug_url -Destination $output
# Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

# $output = "$baseDir\$capriza_xpi"
# $start_time = Get-Date
# Start-BitsTransfer -Source $capriza_url -Destination $output
# Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
############################################################################################



#################################### installing FF with custom ini file ####################
$proc = Start-Process "$output" -ArgumentList "-ms /INI=$baseDir\Config.ini" -PassThru
$timeouted = $null
$proc | Wait-Process -Timeout 15 -ea 0 -ev $timeouted
if ($timeouted) {$proc | Stop-Process}
elseif ($proc.ExitCode -ne 0) {Add-Content $RootPath\errlog.txt $_.Exception.Message}

Write-Output "Finish Installing FF"
############################################################################################


##################################### Setting the prefs i need #############################
# $autoconfig = @"
    # //
	# pref(`"general.config.filename`", `"ci.cfg`");
	# pref(`"general.config.obscure_value`", 0);
# "@

# $ci_cfg= @"
	# // Allow extensions to be installed without user prompt
	# pref("extensions.autoDisableScopes", 11);
# "@

# Set-Content -Path "$ff_dir\defaults\pref\autoconfig.js" -Value $autoconfig
# Set-Content -Path "$ff_dir\ci.cfg" -Value $ci_cfg
############################################################################################



####################### Coping the xpi files to ff extensions folder #######################
# $$firebug_sourceDir = "firebug@software.joehewitt.com.xpi"
# $Source_dir = "$baseDir\$$firebug_sourceDir"
# $Destination_dir = "$ext_destination\$$firebug_sourceDir"
# Copy-Item -Path $Source_dir -Destination $Destination_dir -recurse -Force

# $capriza_sourceDir = "designer@capriza.com.xpi"
# $Source_dir = "$baseDir\$capriza_sourceDir"
# $Destination_dir = "$ext_destination\$capriza_sourceDir"
# $CopyErr = Copy-Item -Path $Source_dir -Destination $Destination_dir -recurse -Force 
############################################################################################



########################### Creating desktop shortcut ######################################

$pattern = '[^0-9.()]'
$Names = Get-ChildItem $Desktop | Where-Object { $_.Name -match 'FireFox' }
foreach($name in $Names)
{

	$name = $name.Name
	$Hit = $name -replace $pattern, ''
	$Hit = $Hit.Substring(0,$Hit.Length-1)
	
	if(($Hit -lt $version) -and ($Hit -ne 38))
	{
		Remove-Item "$Desktop\$name" -Force
	}
}

if(-Not (Test-Path "$Desktop\Mozilla Firefox $version.lnk"))
{
	$TargetFile = "$ff_dir\firefox.exe"
	$ShortcutFile = "$Desktop\Mozilla Firefox $version.lnk"
	$WScriptShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
	$Shortcut.TargetPath = $TargetFile
	$Shortcut.Save()
}
############################################################################################
#Remove-Item C:\Scripts\Installer -Force -Recurse
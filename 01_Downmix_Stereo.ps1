##############################################
### Downmix 7.1/5.1 Audio Tracks to Stereo ###
##############################################

param(
    [string]$path,
    [switch]$setdebug

)
$path = Read-Host -Prompt "Please enter the root path the script will run from"
$rootdirectory = $path

Function Write-Exists{
    Write-Host "[EXISTS]" -BackgroundColor Yellow -ForegroundColor Black
}

Function Write-HostPassed{
    Write-Host "[PASSED]" -BackgroundColor Green -ForegroundColor Black
}

Function Set-Debug {
    param(
        [Parameter (Position = 0, Mandatory = $true)] [boolean]$setdebug
    )
    if ($setdebug -eq $true) {
        $Global:core_Debug = $true
    }
    elseif ($setdebug -eq $false) {
        $Global:core_Debug = $false
    }
}

Function Write-HostFailed{
    Param (
        [boolean]$isexception,
        [boolean]$abort,
        [boolean]$showexception,
        [string]$message
        )

    Write-Host "[FAILED!]" -BackgroundColor Red -ForegroundColor Black

    if ($isexception -eq $true) {
        $thrownerror = ($_.Exception -split '\n')[0]
        Show-Exception -thrownexception $thrownerror
    }

    if ($abort -eq $true) {
        Exit-Core
    }
}

Function Write-Info {
    param (
        [string]$message1,
        [string]$message2
    )
    if ($Global:core_Debug -eq $true) {
        Write-Host "[INFO]" -NoNewline -BackgroundColor Cyan -ForegroundColor Black
        Write-Host $message1 -BackgroundColor Black -ForegroundColor Cyan -NoNewline
        Write-Host $message2 -BackgroundColor Black -ForegroundColor Cyan 
    }
}

Function Write-Clean {
    param (
        [Parameter (Position = 0, Mandatory = $true)]$myString
    )
    $numadjust = 90
    $count = $myString.length

    # Write-Host $count
    if (-not($count -ge $numadjust)) {
        $buffer = ($numadjust - $count)
        $filler = "." * $buffer
        Write-Host $mystring -NoNewline
        Write-Host $filler -NoNewline
    }
}



if(Get-ChildItem -name "ffmpegOut\")
    {
    Write-Clean "Checking if output folder exists in $rootdirectory."
    Write-HostPassed
    }
Else{
    Write-Clean "Output folder does not exist. Creating...." 
    New-Item -Name "ffmpegOut" -ItemType "directory" 
    Write-HostPassed
    }


$parentfolderlist = Get-Childitem $rootdirectory -Directory | Select-Object -ExpandProperty FullName
$filteredmovielist = @()

ForEach($parentfolder in $parentfolderlist) {
        $filteredmovielist += Get-ChildItem $parentfolder -Filter "*.mkv" | Where-Object { $_ -notmatch "sample" }
    
}


$filteredmovielist.FullName | Out-File -FilePath "$rootdirectory\ffmpegOut\file_list.txt" 

#foreach($movieEncode in $filteredmovielist.FullName) {
    #ffmpeg -y -i "$movieEncode" -map 0:v -c:v copy -map 0:a:0? -c:a:0 copy -map 0:a:0? -c:a:1 ac3 -b:a:1 384k -ac 2 -metadata:s:a:1 title="2.0 Stereo" -metadata:s:a:1 language=eng -map 0:a:1? -c:a:2 copy -map 0:a:2? -c:a:3 copy -map 0:a:3? -c:a:4 copy -map 0:a:4? -c:a:5 copy -map 0:a:5? -c:a:6 copy -map 0:a:6? -c:a:7 copy -map 0:s? -c:s copy "ffmpegOut/%%~nA.mkv"

#}
#if not exist "ffmpegOut\" MD "ffmpegOut"
#for /r %%A IN ("*.mkv") Do ffmpeg -y -i "%%A" -map 0:v -c:v copy -map 0:a:0? -c:a:0 copy -map 0:a:0? -c:a:1 ac3 -b:a:1 384k -ac 2 -metadata:s:a:1 title="2.0 Stereo" -metadata:s:a:1 language=eng -map 0:a:1? -c:a:2 copy -map 0:a:2? -c:a:3 copy -map 0:a:3? -c:a:4 copy -map 0:a:4? -c:a:5 copy -map 0:a:5? -c:a:6 copy -map 0:a:6? -c:a:7 copy -map 0:s? -c:s copy "ffmpegOut/%%~nA.mkv"
#pause
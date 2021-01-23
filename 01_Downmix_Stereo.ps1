##############################################
### Downmix 7.1/5.1 Audio Tracks to Stereo ###
##############################################

param(
    [System.IO.FileInfo]$path,
    [switch]$setdebug

)

If (!($path)) {
    do {
        $path = Read-Host -Prompt "Please enter the path containing the .mkv files you want to add a stereo track to..."
    } until (Test-Path $path -PathType Container)
}

$Global:core_Debug = $true
$rootdirectory = $path
$FilteredMovieList = @()


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
        Write-Host $message1 -NoNewline -BackgroundColor Black -ForegroundColor Cyan
        Write-Host $message2 -BackgroundColor Black -ForegroundColor Cyan 
    }
}

Function Write-Clean {
    param (
        [Parameter (Position = 0, Mandatory = $true)]$myString
    )
    $numadjust = 200
    $count = $myString.length

    # Write-Host $count
    if (-not($count -ge $numadjust)) {
        $buffer = ($numadjust - $count)
        $filler = "." * $buffer
        Write-Host $mystring -NoNewline
        Write-Host $filler -NoNewline
    }
}


# Add option to name folder as a parameter/prompt
if(Get-ChildItem $rootdirectory -Directory -name "ffmpegOut")
    {
    Write-Clean "Checking if output folder exists in $rootdirectory."
    Write-HostPassed
    }
Else{
    Write-Clean "Output folder does not exist. Creating...." 
    New-Item $rootdirectory -Name "ffmpegOut" -ItemType "directory" | Out-Null
    Write-HostPassed
    }


If($rootdirectory) {
    Write-Clean "Grabbing list of parent folders in specified directory"
    try {
        $parentfolderlist = Get-Childitem $rootdirectory -Directory | Select-Object -ExpandProperty FullName -ErrorAction Stop
        Write-HostPassed
    }
    catch {
        Write-HostFailed
        Write-Clean "Error creating list of parent folders in specified path. Please check the specified root directory for running processes and files in use."
        Write-HostFailed
    }
    
}
    
Write-Clean "Loading parent folder list"
If($parentfolderlist) {
    Write-HostPassed
    Try{
        Write-Clean "Filtering to only .mkv files and excluding sample files.........."
        ForEach($parentfolder in $parentfolderlist) {
            $FilteredMovieList += Get-ChildItem $parentfolder -Filter "*.mkv" | Where-Object { $_ -notmatch "sample" } -ErrorAction Stop
        }
        Write-HostPassed        
    }
    Catch {
        Write-HostFailed
    }
}
Else{
    Write-HostFailed
    Write-Host "There was a problem generating the list of parent folders in the specified root directory. Please try again and ensure there are no running processes using $rootdirectory" -BackgroundColor DarkRed -ForegroundColor Black
}

Write-Clean "Generating text file with a list of movies located within $($rootdirectory)"
If(Test-Path "$rootdirectory\ffmpegOut\file_list.txt"){
    #Run a diff against existing file and append difference into text file
}
Else{
    $FilteredMovieList.FullName | Out-File -FilePath "$rootdirectory\ffmpegOut\file_list.txt" 
}
Write-HostPassed

# Detect all audio streams on the .mkv file, and parse them out by order
# Downmix from the highest audio channel (IE. a:0) which is typically 7 channel atmos or 5.1 DTS, into 2.0 stereo
# Slot 2.0 stereo at the bottom of the audio list we parsed out earlier

foreach($MovieMetadata in $FilteredMovieList) {
    Try{
        $indexarray = @()
        $engAudiolist = @()
        Write-Clean "Grabbing metadata from $($MovieMetadata.Name) "        
        # WIP ffprobe logic to grab only audio streams with title, codec, and index in parseable json formatting
        $metadata = ffprobe -v error -select_streams a -show_entries stream=index,codec_name,codec_type,channels:stream_tags -print_format json $MovieMetadata | ConvertFrom-Json -ErrorAction Stop
        Write-HostPassed
        # Build array of audio indexes
        foreach($track in $metadata.streams){
            # Strip out track based on commentary title in tag metadata
            If($track.tags | Where-Object {$_.title -notmatch "commentary"}){
                Write-Clean "Grabbing audio track from $($Moviemetadata.name)"
                $indexarray += $track.index 
                Write-HostPassed
            }
            Else{
                
                
            }
        }
            # Iterate through audio streams and match to indexarray we built earlier for tracks to include in new .mkv
            Foreach($audiostream in $indexarray){
                $audiotrack = ($metadata.streams | Where-Object {$_.index -eq $audiostream})
                If($audiotrack.tags.language){
                    If($audiotrack.tags.language -match "eng"){
                        Write-Info "Found English audio track"
                        $engAudiolist += $audiotrack
                    }
                    Elseif($audiotrack.tags.language -match "jpn"){
                        Write-Info "Found Japanese audio track. Sugoi."
                    }
                }
                else{
                    Write-Info "Audio track: $($audiotrack.index) does not have a tagged language"
                }
            }
            # This does not account for multi-language releases with both English and Japanese audio
            # Should probably add logic to include both audio lists in the check
            If($engAudiolist) {
                $trackindex = ($engAudiolist | Measure-Object).Count
                # Can we figure out a better way to dynamically run ffmpeg commands
                # This is absolutely not an ideal way of doing this as we'd be hardcoding the command
                # Based on the amount of tracks we grabbed earlier
                # Ideally I'd find some way to dynamically build the ffmpeg command based on the tracks we grabbed earlier
                If($trackindex -eq "1") {
                    Write-Host "1 Audio tracks being kept"
                    #ffmpeg command here?
                }
                elseif ($trackindex -eq "2") {
                    Write-Host "2 Audio tracks being kept"
                    #ffmpeg command here?
                }
                elseif ($trackindex -eq "3") {
                    Write-Host "3 Audio tracks being kept"
                    #ffmpeg command here?
                }
                elseif ($trackindex -eq "4") {
                    Write-Host "4 Audio tracks being kept"
                    #ffmpeg command here?
                }
                elseif ($trackindex -eq "5") {
                    Write-Host "5 Audio tracks being kept"
                    #ffmpeg command here?
                }
                elseif ($trackindex -eq "6") {
                    Write-Host "6 Audio tracks being kept"
                    #ffmpeg command here?
                }
            }


        
    }
    Catch{
        Write-HostFailed
        Write-Clean "Unable to grab $($MovieMetadata.Name) metadata. ¯\_(O_O)_/¯" 
        Write-HostFailed
        

    }

    # If($metadata.{

    # }


}    

# Possibly no longer needed because of how the tracks are sorted from highest quality to lowest anyway.
# May need to revisit

# Pick the highest possible channel width to downmix from. 
# Typically the highest index will contain the highest quality audio file.
# IE.(Index #1= Atmos/7.1, Index #2 = 5.1, Index #3 = etc.)
# This is not totally perfect, but accurate enough based on the scene releases and blu-ray formatting.
If($audiotrack.channels -eq "8"){
    
}
Elseif($audiotrack.channels -eq "6"){

}



#ffmpeg -y -i "$movieEncode" -map 0:v -c:v copy -map 0:a:0? -c:a:0 copy -map 0:a:0? -c:a:1 ac3 -b:a:1 256k -ac 2 -metadata:s:a:1 title="2.0 Stereo" -metadata:s:a:1 language=eng -map 0:a:1? -c:a:2 copy -map 0:a:2? -c:a:3 copy -map 0:a:3? -c:a:4 copy -map 0:a:4? -c:a:5 copy -map 0:a:5? -c:a:6 copy -map 0:a:6? -c:a:7 copy -map 0:s? -c:s copy "ffmpegOut/%%~nA.mkv"
#if not exist "ffmpegOut\" MD "ffmpegOut"
#for /r %%A IN ("*.mkv") Do ffmpeg -y -i "%%A" -map 0:v -c:v copy -map 0:a:0? -c:a:0 copy -map 0:a:0? -c:a:1 ac3 -b:a:1 384k -ac 2 -metadata:s:a:1 title="2.0 Stereo" -metadata:s:a:1 language=eng -map 0:a:1? -c:a:2 copy -map 0:a:2? -c:a:3 copy -map 0:a:3? -c:a:4 copy -map 0:a:4? -c:a:5 copy -map 0:a:5? -c:a:6 copy -map 0:a:6? -c:a:7 copy -map 0:s? -c:s copy "ffmpegOut/%%~nA.mkv"
#pause
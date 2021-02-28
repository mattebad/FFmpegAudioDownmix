# FFmpegAudioDownmix
# The intention of this project is to begin to automate the intake of my media completely from beginning to end.
# This is the first stage of that, by automating the management and creation of selected media files, I'm able to consolidate
# my entire media library without having to do any work other than adding it into Sonarr or Radarr

This script specifically is being built to do the following functions:
1. Be flexible enough to be pointed at any media library and injest all relevant media files. The user is able to use the default of .mkv, but they are also able to override this through the use of a switch for other file extensions (IE. MP4, TS, AVI, etc)
2. Build an array of selected media files and output this to a txt file to be used as a tracker for the script on re-runs. This allows tracking of where the script last left off in terms of remuxing audio everytime it's run so it doesn't start from the beginning
3. Parse through media files and store listed metadata for the file to be used in the downmixing of audio, but also potentially down the road for encoding things like remuxes
4. Be able to discern between multiple different languages and qualities of tracks and always downmix the highest level audio track (7.1/5.1) into a stereo track
5. Include the option to automatically exclude commentary tracks for those of us who don't want them taking space on the relevant media containers
6. Output finalized media to a specified folder location and then give the option to automatically copy over the exisiting media location (Default) or allow for the user to manually copy it over after completion

To run this, make sure that at the bare minimum, Powershell 5.1 is installed. As a note, if you are using Powershell 7, be aware that text and scrolling are open issues as they do not format correctly on Powershell 7, so you may notice some line clipping and the scroll not working for all history. This is expected behavior for now until Microsoft patches this.

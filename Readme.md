Take your existing podcast feed and upload it to Youtube. The script will automatically generate video .mkv files from your audio files with the episode image as a still image. As far as possible metadata from the podcast feed will be added to the Youtube video.

All uploaded videos are private by default, so you can review them before publishing.

**This is very early alpha. Still more a POC. Use with care.**

## Usage

ffmpeg is required to create the video files
```
apt-get install ffmpeg
```

ruby is required to run the script
```
apt-get install ruby ruby-dev zlib1g-dev
```

Install the gem from [Rubygems.org](https://rubygems.org/gems/podcast-to-youtube).
```
gem install podcast-to-youtube
```

Go to [Google Developer Console](https://console.developers.google.com/) and login to create API credentials.

Go to the API section

![](images/goto_api.png)

Go to Youtube API

![](images/goto_youtube_api.png)

Enable the API

![](images/enable_api.png)

Go to the credentials section

![](images/goto_credentials.png)

Add new OAuth2 credentials

![](images/add_oauth2.png)

Configure them

![](images/config_oauth2.png)

Download the credentials file and place it in the same folder you are going to run the script. This folder will also contain all the audio and video files the scripts works with.

![](images/download_json.png)

Rename the credentials file
```bash
mv client_secret_12345678-asdljkahsdlkjasdlkjasd.apps.googleusercontent.com.json client_secret.json
```

Think about your upload limit! Videos with more than 15 minutes can only be uploaded if your Youtube accaunt is linked to your phone numer.

run the script (example)
```
podcast-to-youtube upload -f "http://podcast.funkenstrahlen.de/feed/m4a" -s client_secret.json -c 28
```

Usage:
```
Usage: podcast-to-youtube COMMAND [OPTIONS]

Commands
     upload: upload an existing podcast feed to youtube

Options
    -f, --feedurl URL                podcast feed url
    -s, --clientsecretfile SECRET    path to the client_secret.json
    -c, --videocategoryid ID         youtube video category id for the uploaded vides
    -h, --help                       print this help
``

You will have to open an OAuth2 Url in your browser to allow the script to access your Youtube account. Paste the authentication code you receive into the script prompt. After the first authentication the refresh token is saved in the client_secret.json. By using the refresh token the script can reauthenticate to youtube without user interaction.
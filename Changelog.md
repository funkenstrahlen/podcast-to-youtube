#Changelog

##0.3.4
* Bugfix: Do not crash if an entry does not have a specific coverart image. Use the default feed coverart instead.

##0.3.3
* Bugfix

##0.3.2
* Check if video exists before doing any rendering. This improves cronjob performance because a lot of actions can be skipped in this case.

##0.3.1
* Code refactoring
* Readme update

##0.3.0
* Allow ruby 1.9.3 or higher
* Code refactored
* Completly object oriented Code
* Save refresh token in file. After the first authentication via URL the script can reauthenticate without user interaction. This enabled the script to be run as a cronjob

##0.2.0
* Pass Parameters to PodcastUploader
* Add Commandline Arguments parsing, so it can be used as a nice cli tool

##0.1.2
* Basic functionality
* Published as Rubygem
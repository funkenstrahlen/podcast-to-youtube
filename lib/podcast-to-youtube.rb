# encoding: utf-8

require 'feedjira'
require 'yt'
require 'yaml'
require 'rubygems'
require 'json'

class PodcastUploader

	@client_secret
	@client_secret_file_path
	@account

	def authenticate_youtube(client_secret_file_path = 'client_secret.json')
		load_configuration client_secret_file_path

		puts "connecting to youtube account"
		# check for refresh token in config file
		if !@client_secret['installed']['refresh_token'].nil?
			puts "using refresh token"
			authenticate_youtube_by_refresh_token
		else
			# otherwise authenticate with oauth2
			Yt.configure do |config|
				config.client_id = @client_secret['installed']['client_id']
				config.client_secret = @client_secret['installed']['client_secret']
			end
			redirect_uri = 'urn:ietf:wg:oauth:2.0:oob' # special redirect uri to make the user copy the auth_code to the application
			puts "open this url in a browser"
			puts Yt::Account.new(scopes: ['youtube'], redirect_uri: redirect_uri).authentication_url
			puts "paste the authentication code here and press enter"
			auth_code = STDIN.gets.chomp
			@account = Yt::Account.new authorization_code: auth_code, redirect_uri: redirect_uri

			save_configuration
		end
	end

	def upload(podcast_feed_url, video_category_id, privacy = :private)
		feed = parse_feed

		feed.entries.reverse_each do |entry|

			# Downlaod the audio file
			puts "downloading audio file from #{entry.enclosure_url}"
			downloadAudioCMD_status = system( "wget", "-c", "#{entry.enclosure_url}" )
			audiofile = entry.enclosure_url.split('/').last

			# Download the coverart
			puts "downloading coverart from #{entry.itunes_image}"
			downloadCoverartCMD_status = system( "wget", "-c", "#{entry.itunes_image}" )
			coverart = entry.itunes_image.split('/').last

			if(downloadCoverartCMD_status && downloadAudioCMD_status)
				# convert to mkv format
				videofile = File.basename(audiofile, File.extname(audiofile)) + ".mkv"
				if !File.file?(videofile)
					puts "generating videofile #{videofile}"
					convertCMD_status = system( "ffmpeg", "-loop", "1", "-r", "2", "-i", "#{coverart}", "-i", "#{audiofile}", "-vf", "scale=-1:1080", "-c:v", "libx264", "-preset", "slow", "-tune", "stillimage", "-crf", "18", "-c:a", "copy", "-shortest", "-pix_fmt", "yuv420p", "-threads", "0", "#{videofile}" )
				else
					# file already exists
					puts "videofile #{videofile} already exists. skipping ffmpeg renderning."
					convertCMD_status = true
				end

				if(convertCMD_status)
					# upload to youtube
					video_description = generate_video_description(entry, feed)
					video_title = "#{feed.title} - #{entry.title}"
					if @account.videos.any? {|video| video.title == video_title }
						puts "do not upload video, as it is already online"
					else
						puts "uploading videofile to Youtube"
						# refresh authentication if expired
						if @account.authentication.expired?
							authenticate_youtube_by_refresh_token
						end
						@account.upload_video videofile, privacy_status: privacy, title: video_title, description: video_description, category_id: video_category_id, tags: %w(podcast)
					end
				else
					raise "generating videofile #{videofile} failed"
				end
			else
				raise "downloading audiofile or coverart failed"
			end	
		end
	end

	private

		def authenticate_youtube_by_refresh_token
			puts "reauthenticate youtube with refresh token"
			@account = Yt::Account.new refresh_token: @client_secret['installed']['refresh_token']
			save_configuration
		end


		def parse_feed
			puts "parsing feed"
			return Feedjira::Feed.fetch_and_parse podcast_feed_url
		end

		def load_configuration(file_path)
			puts "loading configuration"
			if File.file?(file_path)
				@client_secret = JSON.parse(File.read(file_path))
				@client_secret_file_path = file_path
			else 
				raise "Could not find config file at #{file_path}. This is required for the Youtube API authentication. More information can be found in the Readme."
			end
		end

		def save_configuration
			puts "saving current configuration"
			@client_secret['installed']['refresh_token'] = @account.authentication.refresh_token
			File.write(@client_secret_file_path, @client_secret.to_json)
		end

		def generate_video_description(entry, feed)
			video_description = "#{entry.itunes_summary}\n\n"
			video_description += "Mehr Infos und Links zur Episode: #{entry.url}\n"
			video_description += "Veröffentlicht: #{entry.published}\n"
			video_description += "Episode herunterladen (Audio): #{entry.url}\n\n"
			video_description += "Podcast Webseite: #{feed.url}\n"
			video_description += "Podcast Abonnieren: #{feed.url}\n"
			video_description += "Podcast Author: #{feed.itunes_author}"
			return video_description
		end
end

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
		Yt.configure do |config|
			config.client_id = @client_secret['installed']['client_id']
			config.client_secret = @client_secret['installed']['client_secret']
		end
		# check for refresh token in config file
		if !@client_secret['installed']['refresh_token'].nil?
			puts "using refresh token"
			authenticate_youtube_by_refresh_token
		else
			# otherwise authenticate with oauth2
			authenticate_youtube_by_access_token
			save_configuration
		end
	end

	def upload(podcast_feed_url, video_category_id, privacy = :private)
		feed = parse_feed podcast_feed_url
		feed.entries.reverse_each do |entry|
			video_title = "#{feed.title} - #{entry.title}"
			if !video_already_exists(video_title)
				audiofile = download_asset entry.enclosure_url
				coverart = download_asset entry.itunes_image
				videofile = generate_videofile(audiofile, coverart)
				video_description = generate_video_description(entry, feed)
				tags = %w(podcast)

				upload_video(video_title, video_description, video_category_id, privacy, tags, videofile)
			else
				puts "video #{video_title} already exists on Youtube. Skipping."
			end
		end
	end

	private

		def refresh_authentication
			if @account.authentication.expired?
				authenticate_youtube_by_refresh_token
			end
		end

		def upload_video(video_title, video_description, video_category_id, privacy, tags, videofile)
			puts "uploading videofile to Youtube"
			refresh_authentication
			@account.upload_video(videofile, privacy_status: privacy, title: video_title, description: video_description, category_id: video_category_id, tags: tags)
		end

		def video_already_exists(video_title)
			refresh_authentication
			return @account.videos.any? {|video| video.title == video_title }
		end

		def generate_videofile(audiofile, coverart)
			videofile = File.basename(audiofile, File.extname(audiofile)) + ".mkv"
			if !File.file?(videofile)
				puts "generating videofile #{videofile}"
				if !system( "ffmpeg", "-loop", "1", "-r", "2", "-i", "#{coverart}", "-i", "#{audiofile}", "-vf", "scale=-1:1080", "-c:v", "libx264", "-preset", "slow", "-tune", "stillimage", "-crf", "18", "-c:a", "copy", "-shortest", "-pix_fmt", "yuv420p", "-threads", "0", "#{videofile}" )
					raise "generating videofile #{videofile} from #{audiofile} and #{coverart} failed"
				end
			else
				# file already exists
				puts "videofile #{videofile} already exists. skipping ffmpeg renderning."
			end
			return videofile
		end

		def download_asset(url)
			puts "downloading asset file from #{url}"
			if !system( "wget", "-c", "#{url}" )
				raise "downloading asset from #{url} failed"
			end
			return url.split('/').last
		end

		def authenticate_youtube_by_refresh_token
			puts "reauthenticate youtube with refresh token"
			begin  
				@account = Yt::Account.new refresh_token: @client_secret['installed']['refresh_token']
			rescue
				puts "authentication with refresh token failed"
				authenticate_youtube_by_access_token
			end 
			save_configuration
		end

		def authenticate_youtube_by_access_token
			puts "authenticate youtube by access token"
			redirect_uri = 'urn:ietf:wg:oauth:2.0:oob' # special redirect uri to make the user copy the auth_code to the application
			puts "open this url in a browser"
			puts Yt::Account.new(scopes: ['youtube'], redirect_uri: redirect_uri).authentication_url
			puts "paste the authentication code here and press enter"
			auth_code = STDIN.gets.chomp
			@account = Yt::Account.new authorization_code: auth_code, redirect_uri: redirect_uri
		end

		def parse_feed(podcast_feed_url)
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

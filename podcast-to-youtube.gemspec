Gem::Specification.new do |spec|
	spec.name        = 'podcast-to-youtube'
	spec.version     = '0.3.2'
	spec.licenses    = ['MIT']
	spec.summary     = "Ruby script to upload an existing podcast feed and to Youtube."
	spec.description = "Take your existing podcast feed and upload it to Youtube. The script will automatically generate video .mkv files from your audio files with the episode image as a still image. As far as possible metadata from the podcast feed will be added to the Youtube video. All uploaded videos are private by default, so you can review them before publishing."
	spec.authors     = ["Stefan Trauth"]
	spec.email       = 'mail@stefantrauth.de'
	spec.homepage    = 'https://github.com/funkenstrahlen/podcast-to-youtube'

	spec.files       = ["lib/podcast-to-youtube.rb"]
	spec.executables << 'podcast-to-youtube'

	spec.required_ruby_version = '>= 1.9.3'
	spec.add_dependency 'feedjira', '~> 2.0'
	spec.add_dependency 'yt', '~> 0.25'
	spec.add_dependency 'json', '~> 1.7'
end
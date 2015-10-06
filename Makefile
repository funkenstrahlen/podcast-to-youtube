gem:
	rm *.gem
	gem build podcast-to-youtube.gemspec

release: gem
	gem push *.gem
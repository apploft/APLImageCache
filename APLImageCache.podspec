Pod::Spec.new do |s|

  s.name         = "APLImageCache"
  s.version      = "1.0.0"
  s.summary      = "A simple wrapper for the FastImageCache."

  s.description  = <<-DESC
                   A simple wrapper for the FastImageCache. 

		   * Easy setup
		   * Provides UIImageView category for requesting and cancelling.
		   * Support for custom image downloader classes.
                   DESC

  s.homepage     = "https://github.com/apploft/APLImageCache"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.authors      = { "Mathias Koehnke" => "mathias.koehnke@apploft.de" }

  s.platform     = :ios, '7.0'

  s.source       = { :git => "https://github.com/apploft/APLImageCache.git", :tag => s.version.to_s }

  s.source_files  = 'Classes', 'Classes/**/*.{h,m}', 'Classes/Private/**/*.{h,m}'
  s.exclude_files = 'Classes/Exclude'

  #s.public_header_files = 'Classes/**/*.h'

  s.requires_arc = true
  s.dependency 'FastImageCache', '1.5.1'
end

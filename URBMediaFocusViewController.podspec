Pod::Spec.new do |s|
	s.name				= 'URBMediaFocusViewController'
	s.version			= '0.9.0'
	s.summary			= 'A view controller that focuses images to their full size with physics similar to Tweetbot 3.'
	s.description		= 'URBMediaFocusViewController is an experiment to recreate the view used to enlarge photos and videos from their thumbnail previews as seen in Tweetbot 3 using the UIDynamics API introduced in iOS 7.'
	s.homepage			= 'https://github.com/u10int/URBMediaFocusViewController'
	s.author = {
		'Nicholas Shipes' => 'nshipes@urban10.com'
	}
	s.source = {
		:git	=> 'https://github.com/u10int/URBMediaFocusViewController.git',
		:tag	=> s.version.to_s
	}
	s.platform			= :ios, '8.0'
	s.license			= { :type => 'MIT', :file => 'LICENSE' }
	s.requires_arc		= true
	s.source_files		= 'URBMediaFocusViewController.{h,m}'
	s.frameworks		= 'UIKit', 'Foundation', 'CoreGraphics', 'QuartzCore', 'AssetsLibrary'
	s.ios.deployment_target = '8.0'
end
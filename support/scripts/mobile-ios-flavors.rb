# One build configuration and one scheme per flavor. Run once after `flutter create`, with the xcodeproj gem; the result
# is committed. flutter build ios --flavor dev uses the scheme "dev" and the configuration "Release-dev".
require "xcodeproj"

root = File.expand_path("../../mobile/ios", __dir__)
project = Xcodeproj::Project.open("#{root}/Runner.xcodeproj")
group = project.main_group["Flutter"]
brand = group.files.find { |f| f.path.end_with?("Brand.xcconfig") } || group.new_file("Flutter/Brand.xcconfig")
{ "dev" => [".dev", " Dev", "HOST_DEV"], "staging" => [".staging", " Staging", "HOST_STAGING"], "prod" => ["", "", "HOST_PROD"] }.each do |flavor, (id, name, host)|
  %w[Debug Profile Release].each do |mode|
    path = "Flutter/#{mode}-#{flavor}.xcconfig"
    File.write("#{root}/#{path}", <<~CONFIG)
      // Written by support/scripts/mobile-ios-flavors.rb.
      #include "#{mode == 'Debug' ? 'Debug' : 'Release'}.xcconfig"
      #include "Brand.xcconfig"
      PRODUCT_BUNDLE_IDENTIFIER = $(BRAND_ID)#{id}
      BRAND_SUFFIX =#{name}
      WEB_HOST = $(#{host})
      CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements
    CONFIG
    file = group.files.find { |f| f.path == path || f.path == File.basename(path) } || group.new_file(path)
    ([project] + project.targets).each do |owner|
      base = owner.build_configurations.find { |c| c.name == mode } or next
      config = owner.build_configurations.find { |c| c.name == "#{mode}-#{flavor}" }
      unless config
        config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
        config.name = "#{mode}-#{flavor}"
        config.build_settings = Marshal.load(Marshal.dump(base.build_settings))
        owner.build_configuration_list.build_configurations << config
      end
      config.base_configuration_reference = base.base_configuration_reference
      next unless owner.respond_to?(:product_type) && owner.name == "Runner"
      config.base_configuration_reference = file
      config.build_settings.delete("PRODUCT_BUNDLE_IDENTIFIER")
    end
  end
end
project.save
target = project.targets.find { |t| t.name == "Runner" }
%w[dev staging prod].each do |flavor|
  scheme = Xcodeproj::XCScheme.new("#{root}/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme")
  scheme.launch_action.build_configuration = "Debug-#{flavor}"
  scheme.test_action.build_configuration = "Debug-#{flavor}"
  scheme.profile_action.build_configuration = "Profile-#{flavor}"
  scheme.analyze_action.build_configuration = "Debug-#{flavor}"
  scheme.archive_action.build_configuration = "Release-#{flavor}"
  scheme.save_as("#{root}/Runner.xcodeproj", flavor, true)
end
puts target.build_configurations.map(&:name).sort.join(" ")

require 'xcodeproj'

project_path = '/Users/sena/Desktop/projeler/vibe/Vibe/Vibe.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Add entitlements file to build settings
target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Vibe/Vibe.entitlements'
  
  # Add Info.plist usage descriptions directly to the target build settings
  config.build_settings['INFOPLIST_KEY_NSHealthShareUsageDescription'] = 'Nabız verinizi okuyarak fırçalarınızı kişiselleştirmek için izninize ihtiyacımız var.'
  config.build_settings['INFOPLIST_KEY_NSHealthUpdateUsageDescription'] = 'Nabız verinizi okuyarak fırçalarınızı kişiselleştirmek için izninize ihtiyacımız var.'
  
  # Also ensure generated Info.plist is enabled just in case
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
end

project.save
puts "Xcode projesi basariyla guncellendi: Info.plist aciklamalari ve Entitlements eklendi."

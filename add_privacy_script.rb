#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Check if script already exists
existing_script = target.shell_script_build_phases.find { |phase| phase.name == 'Add Privacy Manifests' }

unless existing_script
  # Create new run script build phase
  phase = target.new_shell_script_build_phase('Add Privacy Manifests')
  
  phase.shell_script = <<~SCRIPT
# Add Privacy Manifests to frameworks
PRIVACY_MANIFEST='<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array/>
</dict>
</plist>'

# Add to connectivity_plus
if [ -d "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/connectivity_plus.framework" ]; then
    echo "$PRIVACY_MANIFEST" > "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/connectivity_plus.framework/PrivacyInfo.xcprivacy"
    echo "Added PrivacyInfo.xcprivacy to connectivity_plus.framework"
fi

# Add to share_plus
if [ -d "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/share_plus.framework" ]; then
    echo "$PRIVACY_MANIFEST" > "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/share_plus.framework/PrivacyInfo.xcprivacy"
    echo "Added PrivacyInfo.xcprivacy to share_plus.framework"
fi
  SCRIPT
  
  # Move the phase to after "Embed Frameworks"
  embed_phase = target.build_phases.find { |p| p.display_name == 'Embed Frameworks' }
  if embed_phase
    embed_index = target.build_phases.index(embed_phase)
    target.build_phases.delete(phase)
    target.build_phases.insert(embed_index + 1, phase)
  end
  
  project.save
  puts "✅ Added 'Add Privacy Manifests' build phase script"
else
  puts "ℹ️  'Add Privacy Manifests' script already exists"
end

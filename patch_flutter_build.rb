#!/usr/bin/env ruby

# This script patches the Flutter iOS build process to remove the -G flag
# It directly modifies the Xcode build settings and creates a custom build phase

require 'fileutils'
require 'xcodeproj'
require 'json'

# Path to the project root directory
PROJECT_ROOT = File.expand_path('..', __FILE__)
IOS_DIR = File.join(PROJECT_ROOT, 'ios')
XCODE_PROJECT_PATH = File.join(IOS_DIR, 'Runner.xcodeproj')

def setup_compiler_wrappers
  puts "Setting up compiler wrappers..."
  
  # Path to the compiler wrappers directory
  wrapper_dir = File.join(PROJECT_ROOT, 'compiler_wrappers')
  FileUtils.mkdir_p(wrapper_dir)
  
  # Create a clang wrapper script
  clang_wrapper = File.join(wrapper_dir, 'clang')
  File.open(clang_wrapper, 'w') do |f|
    f.puts "#!/bin/bash"
    f.puts ""
    f.puts "# This script wraps the clang compiler to remove the -G flag"
    f.puts ""
    f.puts "ARGS=()"
    f.puts "for arg in \"$@\"; do"
    f.puts "  if [[ \"$arg\" != \"-G\" ]]; then"
    f.puts "    ARGS+=(\"$arg\")"
    f.puts "  else"
    f.puts "    echo \"Removing -G flag from clang arguments\" >&2"
    f.puts "  fi"
    f.puts "done"
    f.puts ""
    f.puts "exec /usr/bin/clang \"${ARGS[@]}\""
  end
  
  # Create a clang++ wrapper script
  clangpp_wrapper = File.join(wrapper_dir, 'clang++')
  File.open(clangpp_wrapper, 'w') do |f|
    f.puts "#!/bin/bash"
    f.puts ""
    f.puts "# This script wraps the clang++ compiler to remove the -G flag"
    f.puts ""
    f.puts "ARGS=()"
    f.puts "for arg in \"$@\"; do"
    f.puts "  if [[ \"$arg\" != \"-G\" ]]; then"
    f.puts "    ARGS+=(\"$arg\")"
    f.puts "  else"
    f.puts "    echo \"Removing -G flag from clang++ arguments\" >&2"
    f.puts "  fi"
    f.puts "done"
    f.puts ""
    f.puts "exec /usr/bin/clang++ \"${ARGS[@]}\""
  end
  
  # Make the wrapper scripts executable
  FileUtils.chmod(0755, clang_wrapper)
  FileUtils.chmod(0755, clangpp_wrapper)
  
  puts "Compiler wrappers created at #{wrapper_dir}"
  return wrapper_dir
end

def create_build_phase_script(wrapper_dir)
  puts "Creating build phase script..."
  
  # Create a script that will be added as a Run Script Phase in Xcode
  script_path = File.join(IOS_DIR, 'remove_g_flag_build_phase.sh')
  File.open(script_path, 'w') do |f|
    f.puts "#!/bin/bash"
    f.puts ""
    f.puts "# This script removes the -G flag from the build process"
    f.puts "# It is executed as a Run Script Phase in Xcode"
    f.puts ""
    f.puts "# Add compiler wrappers to the beginning of PATH"
    f.puts "export PATH=\"#{wrapper_dir}:$PATH\""
    f.puts "echo \"Modified PATH to use compiler wrappers: $PATH\""
    f.puts ""
    f.puts "# Set environment variables to force Xcode to use our compiler wrappers"
    f.puts "export CC=\"#{wrapper_dir}/clang\""
    f.puts "export CXX=\"#{wrapper_dir}/clang++\""
    f.puts "export LDPLUSPLUS=\"#{wrapper_dir}/clang++\""
    f.puts ""
    f.puts "echo \"Compiler environment variables set to use wrappers\""
    f.puts "echo \"CC=$CC\""
    f.puts "echo \"CXX=$CXX\""
    f.puts "echo \"LDPLUSPLUS=$LDPLUSPLUS\""
    f.puts ""
    f.puts "# Remove -G flag from any newly generated xcconfig files"
    f.puts "find \"${SRCROOT}\" -name \"*.xcconfig\" -exec sed -i '' 's/-G//g' {} \\;"
    f.puts "echo \"Removed -G flag from xcconfig files\""
    f.puts ""
    f.puts "# Create a temporary directory for additional compiler wrappers"
    f.puts "TEMP_WRAPPER_DIR=\"${BUILT_PRODUCTS_DIR}/compiler_wrappers\""
    f.puts "mkdir -p \"${TEMP_WRAPPER_DIR}\""
    f.puts ""
    f.puts "# Create temporary clang wrapper"
    f.puts "cat > \"${TEMP_WRAPPER_DIR}/clang\" << 'EOF'"
    f.puts "#!/bin/bash"
    f.puts "ARGS=()"
    f.puts "for arg in \"$@\"; do"
    f.puts "  if [[ \"$arg\" != \"-G\" ]]; then"
    f.puts "    ARGS+=(\"$arg\")"
    f.puts "  fi"
    f.puts "done"
    f.puts "exec /usr/bin/clang \"${ARGS[@]}\""
    f.puts "EOF"
    f.puts ""
    f.puts "# Create temporary clang++ wrapper"
    f.puts "cat > \"${TEMP_WRAPPER_DIR}/clang++\" << 'EOF'"
    f.puts "#!/bin/bash"
    f.puts "ARGS=()"
    f.puts "for arg in \"$@\"; do"
    f.puts "  if [[ \"$arg\" != \"-G\" ]]; then"
    f.puts "    ARGS+=(\"$arg\")"
    f.puts "  fi"
    f.puts "done"
    f.puts "exec /usr/bin/clang++ \"${ARGS[@]}\""
    f.puts "EOF"
    f.puts ""
    f.puts "# Make the wrapper scripts executable"
    f.puts "chmod +x \"${TEMP_WRAPPER_DIR}/clang\" \"${TEMP_WRAPPER_DIR}/clang++\""
    f.puts ""
    f.puts "# Add the temporary wrappers to PATH as well"
    f.puts "export PATH=\"${TEMP_WRAPPER_DIR}:$PATH\""
    f.puts "echo \"Added temporary compiler wrappers to PATH: $PATH\""
  end
  
  FileUtils.chmod(0755, script_path)
  puts "Build phase script created at #{script_path}"
  return script_path
end

def create_custom_xcconfig
  puts "Creating custom xcconfig files..."
  
  # Create a custom xcconfig file to override any remaining -G flags
  custom_xcconfig = File.join(IOS_DIR, 'Flutter', 'NoGFlag.xcconfig')
  File.open(custom_xcconfig, 'w') do |f|
    f.puts "// This file is generated by patch_flutter_build.rb"
    f.puts "// It removes the -G flag from the build process"
    f.puts ""
    f.puts "OTHER_CFLAGS = $(inherited)"
    f.puts "OTHER_CXXFLAGS = $(inherited)"
    f.puts "OTHER_SWIFT_FLAGS = $(inherited)"
    f.puts ""
    f.puts "// Force the compiler to ignore the -G flag"
    f.puts "GCC_PREPROCESSOR_DEFINITIONS = $(inherited) DISABLE_G_FLAG=1"
  end
  
  # Update Debug.xcconfig and Release.xcconfig to include our custom xcconfig
  debug_config = File.join(IOS_DIR, 'Flutter', 'Debug.xcconfig')
  release_config = File.join(IOS_DIR, 'Flutter', 'Release.xcconfig')
  
  if File.exist?(debug_config)
    content = File.read(debug_config)
    unless content.include?('NoGFlag.xcconfig')
      File.open(debug_config, 'a') do |f|
        f.puts '#include "NoGFlag.xcconfig"'
      end
      puts "Updated Debug.xcconfig to include NoGFlag.xcconfig"
    end
  end
  
  if File.exist?(release_config)
    content = File.read(release_config)
    unless content.include?('NoGFlag.xcconfig')
      File.open(release_config, 'a') do |f|
        f.puts '#include "NoGFlag.xcconfig"'
      end
      puts "Updated Release.xcconfig to include NoGFlag.xcconfig"
    end
  end
  
  puts "Custom xcconfig files created and updated"
end

def remove_g_flag_from_files
  puts "Removing -G flag from xcconfig and project files..."
  
  # Remove -G flag from xcconfig files
  Dir.glob(File.join(IOS_DIR, '**', '*.xcconfig')).each do |file|
    content = File.read(file)
    modified_content = content.gsub(/-G/, '')
    if content != modified_content
      File.write(file, modified_content)
      puts "Removed -G flag from #{file}"
    end
  end
  
  # Remove -G flag from project files
  Dir.glob(File.join(IOS_DIR, '**', '*.pbxproj')).each do |file|
    content = File.read(file)
    modified_content = content.gsub(/-G/, '')
    if content != modified_content
      File.write(file, modified_content)
      puts "Removed -G flag from #{file}"
    end
  end
  
  puts "Removed -G flag from all xcconfig and project files"
end

def modify_xcode_project(build_phase_script)
  puts "Modifying Xcode project..."
  
  begin
    # Open the Xcode project
    project = Xcodeproj::Project.open(XCODE_PROJECT_PATH)
    
    # Find the Runner target
    target = project.targets.find { |t| t.name == 'Runner' }
    if target.nil?
      puts "Error: Could not find Runner target"
      return false
    end
    
    # Add a Run Script Phase to remove the -G flag
    phase_name = "Remove -G Flag"
    existing_phase = target.build_phases.find { |p| p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && p.name == phase_name }
    
    if existing_phase.nil?
      puts "Adding Run Script Phase to remove -G flag"
      phase = target.new_shell_script_build_phase(phase_name)
      phase.shell_script = "\"#{build_phase_script}\""
      
      # Move the phase to be before the Compile Sources phase
      compile_phase_index = target.build_phases.find_index { |p| p.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase) }
      if compile_phase_index
        target.build_phases.move_from(target.build_phases.count - 1, compile_phase_index)
      end
    else
      puts "Updating existing Run Script Phase"
      existing_phase.shell_script = "\"#{build_phase_script}\""
    end
    
    # Modify build settings to remove -G flag
    target.build_configurations.each do |config|
      # Remove -G flag from OTHER_CFLAGS and OTHER_CXXFLAGS
      ['OTHER_CFLAGS', 'OTHER_CXXFLAGS'].each do |setting|
        if config.build_settings[setting]
          config.build_settings[setting] = config.build_settings[setting].gsub(/-G/, '')
          puts "Removed -G flag from #{setting} in #{config.name} configuration"
        end
      end
    end
    
    # Save the project
    project.save
    puts "Xcode project modified successfully"
    return true
  rescue => e
    puts "Error modifying Xcode project: #{e.message}"
    puts e.backtrace
    return false
  end
end

def create_flutter_build_script(wrapper_dir)
  puts "Creating Flutter build script..."
  
  # Create a script to build the Flutter app with our compiler wrappers
  script_path = File.join(PROJECT_ROOT, 'build_ios_without_g_flag.sh')
  File.open(script_path, 'w') do |f|
    f.puts "#!/bin/bash"
    f.puts ""
    f.puts "# This script builds the Flutter app with compiler wrappers to remove the -G flag"
    f.puts ""
    f.puts "set -e  # Exit on error"
    f.puts ""
    f.puts "# Get the absolute path to the project root directory"
    f.puts "PROJECT_ROOT=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\""
    f.puts "echo \"Project root: $PROJECT_ROOT\""
    f.puts ""
    f.puts "# Add compiler wrappers to the beginning of PATH"
    f.puts "export PATH=\"#{wrapper_dir}:$PATH\""
    f.puts "echo \"Modified PATH to use compiler wrappers: $PATH\""
    f.puts ""
    f.puts "# Set environment variables to force Xcode to use our compiler wrappers"
    f.puts "export CC=\"#{wrapper_dir}/clang\""
    f.puts "export CXX=\"#{wrapper_dir}/clang++\""
    f.puts "export LDPLUSPLUS=\"#{wrapper_dir}/clang++\""
    f.puts ""
    f.puts "echo \"Compiler environment variables set to use wrappers\""
    f.puts "echo \"CC=$CC\""
    f.puts "echo \"CXX=$CXX\""
    f.puts "echo \"LDPLUSPLUS=$LDPLUSPLUS\""
    f.puts ""
    f.puts "# Run flutter pub get to ensure Flutter configuration files exist"
    f.puts "echo \"Running flutter pub get...\""
    f.puts "flutter pub get"
    f.puts ""
    f.puts "# Run pod install with our compiler wrappers"
    f.puts "echo \"Running pod install with compiler wrappers...\""
    f.puts "cd \"$PROJECT_ROOT/ios\""
    f.puts "pod install"
    f.puts ""
    f.puts "# Build the Flutter app for iOS simulator"
    f.puts "echo \"Building Flutter app with modified compiler settings...\""
    f.puts "cd \"$PROJECT_ROOT\""
    f.puts "flutter build ios --simulator --no-codesign"
    f.puts ""
    f.puts "echo \"Build completed!\""
  end
  
  FileUtils.chmod(0755, script_path)
  puts "Flutter build script created at #{script_path}"
  return script_path
end

def create_flutter_run_script(wrapper_dir)
  puts "Creating Flutter run script..."
  
  # Create a script to run the Flutter app with our compiler wrappers
  script_path = File.join(PROJECT_ROOT, 'run_ios_without_g_flag.sh')
  File.open(script_path, 'w') do |f|
    f.puts "#!/bin/bash"
    f.puts ""
    f.puts "# This script runs the Flutter app with compiler wrappers to remove the -G flag"
    f.puts ""
    f.puts "set -e  # Exit on error"
    f.puts ""
    f.puts "# Get the absolute path to the project root directory"
    f.puts "PROJECT_ROOT=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\""
    f.puts "echo \"Project root: $PROJECT_ROOT\""
    f.puts ""
    f.puts "# Add compiler wrappers to the beginning of PATH"
    f.puts "export PATH=\"#{wrapper_dir}:$PATH\""
    f.puts "echo \"Modified PATH to use compiler wrappers: $PATH\""
    f.puts ""
    f.puts "# Set environment variables to force Xcode to use our compiler wrappers"
    f.puts "export CC=\"#{wrapper_dir}/clang\""
    f.puts "export CXX=\"#{wrapper_dir}/clang++\""
    f.puts "export LDPLUSPLUS=\"#{wrapper_dir}/clang++\""
    f.puts ""
    f.puts "echo \"Compiler environment variables set to use wrappers\""
    f.puts "echo \"CC=$CC\""
    f.puts "echo \"CXX=$CXX\""
    f.puts "echo \"LDPLUSPLUS=$LDPLUSPLUS\""
    f.puts ""
    f.puts "# Run flutter pub get to ensure Flutter configuration files exist"
    f.puts "echo \"Running flutter pub get...\""
    f.puts "flutter pub get"
    f.puts ""
    f.puts "# Remove -G flag from xcconfig files"
    f.puts "echo \"Removing -G flag from xcconfig files...\""
    f.puts "find \"$PROJECT_ROOT/ios\" -name \"*.xcconfig\" -exec sed -i '' 's/-G//g' {} \\;"
    f.puts ""
    f.puts "# Remove -G flag from project files"
    f.puts "echo \"Removing -G flag from project files...\""
    f.puts "find \"$PROJECT_ROOT/ios\" -name \"*.pbxproj\" -exec sed -i '' 's/-G//g' {} \\;"
    f.puts ""
    f.puts "# Run the Flutter app with our compiler wrappers"
    f.puts "echo \"Running Flutter app with modified compiler settings...\""
    f.puts "cd \"$PROJECT_ROOT\""
    f.puts "flutter run --simulator"
    f.puts ""
    f.puts "echo \"Run completed!\""
  end
  
  FileUtils.chmod(0755, script_path)
  puts "Flutter run script created at #{script_path}"
  return script_path
end

def create_xcode_patch_script
  puts "Creating Xcode patch script..."
  
  # Create a script to patch the Xcode build process
  script_path = File.join(PROJECT_ROOT, 'patch_xcode_build_process.sh')
  File.open(script_path, 'w') do |f|
    f.puts "#!/bin/bash"
    f.puts ""
    f.puts "# This script patches the Xcode build process to remove the -G flag"
    f.puts ""
    f.puts "set -e  # Exit on error"
    f.puts ""
    f.puts "# Get the absolute path to the project root directory"
    f.puts "PROJECT_ROOT=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\""
    f.puts "echo \"Project root: $PROJECT_ROOT\""
    f.puts ""
    f.puts "# Create a directory to store the original Xcode tools"
    f.puts "TOOLS_DIR=\"$PROJECT_ROOT/xcode_tools_backup\""
    f.puts "mkdir -p \"$TOOLS_DIR\""
    f.puts ""
    f.puts "# Find the Xcode Developer directory"
    f.puts "XCODE_PATH=$(xcode-select -p)"
    f.puts "echo \"Xcode path: $XCODE_PATH\""
    f.puts ""
    f.puts "# Backup the original clang and clang++ if not already backed up"
    f.puts "CLANG_PATH=\"$XCODE_PATH/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang\""
    f.puts "CLANGPP_PATH=\"$XCODE_PATH/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++\""
    f.puts ""
    f.puts "if [ ! -f \"$TOOLS_DIR/clang\" ]; then"
    f.puts "  echo \"Backing up original clang\""
    f.puts "  cp \"$CLANG_PATH\" \"$TOOLS_DIR/clang\""
    f.puts "fi"
    f.puts ""
    f.puts "if [ ! -f \"$TOOLS_DIR/clang++\" ]; then"
    f.puts "  echo \"Backing up original clang++\""
    f.puts "  cp \"$CLANGPP_PATH\" \"$TOOLS_DIR/clang++\""
    f.puts "fi"
    f.puts ""
    f.puts "# Create wrapper scripts for clang and clang++"
    f.puts "echo \"Creating wrapper scripts for clang and clang++\""
    f.puts ""
    f.puts "cat > \"$PROJECT_ROOT/compiler_wrappers/clang\" << 'EOF'"
    f.puts "#!/bin/bash"
    f.puts ""
    f.puts "ARGS=()"
    f.puts "for arg in \"$@\"; do"
    f.puts "  if [[ \"$arg\" != \"-G\" ]]; then"
    f.puts "    ARGS+=(\"$arg\")"
    f.puts "  else"
    f.puts "    echo \"Removing -G flag from clang arguments\" >&2"
    f.puts "  fi"
    f.puts "done"
    f.puts ""
    f.puts "exec /usr/bin/clang \"${ARGS[@]}\""
    f.puts "EOF"
    f.puts ""
    f.puts "cat > \"$PROJECT_ROOT/compiler_wrappers/clang++\" << 'EOF'"
    f.puts "#!/bin/bash"
    f.puts ""
    f.puts "ARGS=()"
    f.puts "for arg in \"$@\"; do"
    f.puts "  if [[ \"$arg\" != \"-G\" ]]; then"
    f.puts "    ARGS+=(\"$arg\")"
    f.puts "  else"
    f.puts "    echo \"Removing -G flag from clang++ arguments\" >&2"
    f.puts "  fi"
    f.puts "done"
    f.puts ""
    f.puts "exec /usr/bin/clang++ \"${ARGS[@]}\""
    f.puts "EOF"
    f.puts ""
    f.puts "chmod +x \"$PROJECT_ROOT/compiler_wrappers/clang\" \"$PROJECT_ROOT/compiler_wrappers/clang++\""
    f.puts ""
    f.puts "echo \"Wrapper scripts created\""
    f.puts ""
    f.puts "# Create a script to restore the original Xcode tools"
    f.puts "cat > \"$PROJECT_ROOT/restore_xcode_tools.sh\" << 'EOF'"
    f.puts "#!/bin/bash"
    f.puts ""
    f.puts "# This script restores the original Xcode tools"
    f.puts ""
    f.puts "set -e  # Exit on error"
    f.puts ""
    f.puts "# Get the absolute path to the project root directory"
    f.puts "PROJECT_ROOT=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\""
    f.puts "echo \"Project root: $PROJECT_ROOT\""
    f.puts ""
    f.puts "# Find the Xcode Developer directory"
    f.puts "XCODE_PATH=$(xcode-select -p)"
    f.puts "echo \"Xcode path: $XCODE_PATH\""
    f.puts ""
    f.puts "# Restore the original clang and clang++"
    f.puts "TOOLS_DIR=\"$PROJECT_ROOT/xcode_tools_backup\""
    f.puts "CLANG_PATH=\"$XCODE_PATH/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang\""
    f.puts "CLANGPP_PATH=\"$XCODE_PATH/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++\""
    f.puts ""
    f.puts "if [ -f \"$TOOLS_DIR/clang\" ]; then"
    f.puts "  echo \"Restoring original clang\""
    f.puts "  sudo cp \"$TOOLS_DIR/clang\" \"$CLANG_PATH\""
    f.puts "fi"
    f.puts ""
    f.puts "if [ -f \"$TOOLS_DIR/clang++\" ]; then"
    f.puts "  echo \"Restoring original clang++\""
    f.puts "  sudo cp \"$TOOLS_DIR/clang++\" \"$CLANGPP_PATH\""
    f.puts "fi"
    f.puts ""
    f.puts "echo \"Original Xcode tools restored\""
    f.puts "EOF"
    f.puts ""
    f.puts "chmod +x \"$PROJECT_ROOT/restore_xcode_tools.sh\""
    f.puts ""
    f.puts "echo \"Restore script created\""
    f.puts ""
    f.puts "echo \"Xcode build process patched successfully\""
  end
  
  FileUtils.chmod(0755, script_path)
  puts "Xcode patch script created at #{script_path}"
  return script_path
end

# Main execution starts here
puts "Starting Flutter iOS build process patching..."

# Setup compiler wrappers
wrapper_dir = setup_compiler_wrappers

# Create build phase script
build_phase_script = create_build_phase_script(wrapper_dir)

# Create custom xcconfig files
create_custom_xcconfig

# Remove -G flag from xcconfig and project files
remove_g_flag_from_files

# Modify Xcode project to add the build phase script
modify_xcode_project(build_phase_script)

# Create Flutter build script
build_script = create_flutter_build_script(wrapper_dir)

# Create Flutter run script
run_script = create_flutter_run_script(wrapper_dir)

# Create Xcode patch script
xcode_patch_script = create_xcode_patch_script

puts "Flutter iOS build process patching completed successfully!"
puts ""
puts "To build the app without the -G flag, run:"
puts "  #{build_script}"
puts ""
puts "To run the app without the -G flag, run:"
puts "  #{run_script}"
puts ""
puts "To patch the Xcode build process (requires sudo), run:"
puts "  #{xcode_patch_script}"
puts ""
puts "Note: You may need to install the xcodeproj gem if it's not already installed:"
puts "  gem install xcodeproj"

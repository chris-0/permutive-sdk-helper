require 'xcodeproj'
require "./PermutiveTools"

# Find the target directory for the Swift code.
jsonSource = "./"
xcodeProject = ""
xcodeTarget = ""

def usage
  puts("Usage: permutive-sdk-helper [json directory] <your.xcodeproj> <xcode target>")
end

if ARGV.count == 3
  jsonSource = ARGV[0]
  xcodeProject = ARGV[1].chomp("/")
  xcodeTarget = ARGV[2]
elsif ARGV.count == 2
  xcodeProject = ARGV[0].chomp("/")
  xcodeTarget = ARGV[1]
else
  usage()
  return
end

if !File.directory?(jsonSource) || !File.exist?("#{xcodeProject}/project.pbxproj")
    usage()
    return
end

puts("permutive-sdk-helper. Searching '#{jsonSource}'")
jsonSource = jsonSource.chomp("/")
swiftDirectory = File.dirname(xcodeProject).chomp("/") + "/Permutive"
Dir.mkdir(swiftDirectory) unless File.exists?(swiftDirectory)

# Generate swift code from JSON
PermutiveTools.generateSwift(jsonSource, swiftDirectory)

# Delete any existing generated file
PermutiveTools.deleteExistingGlue("#{swiftDirectory}/PermutiveHelper.swift")

swiftFiles = Dir["#{swiftDirectory}/*.swift"]
# Remove unwanted code from Swift files
PermutiveTools.sanitiseSwift(swiftFiles)

# Find the structures which need extensions
structures = PermutiveTools.buildStructureList(swiftFiles)
puts("Found #{structures.count} structs to extend")

# Generate the PermutiveHelper.swift glue file
PermutiveTools.generateGlueFile("#{swiftDirectory}/PermutiveHelper.swift", structures)
puts("Generated #{swiftDirectory}/PermutiveHelper.swift")
swiftFiles = Dir["#{swiftDirectory}/*.swift"]

# Add all swift files to project
project = Xcodeproj::Project.open(xcodeProject)
targetObject = nil
project.targets.each { |target|
    if target.name == xcodeTarget
        targetObject = target
    end
}

if targetObject == nil
    puts("Failed: No such target '#{xcodeTarget}' in Xcode project '#{xcodeProject}'")
    return
end

PermutiveTools.addFilesToProject(project, swiftFiles, targetObject)
puts("Success: Added #{swiftFiles.count} files to project '#{xcodeProject}'")

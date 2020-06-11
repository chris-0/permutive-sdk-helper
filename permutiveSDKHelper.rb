require 'xcodeproj'
require "./PermutiveTools"

# Find the target directory for the Swift code.
source = "./"
xcodeProject = ""
xcodeTarget = ""

def usage
  puts("Usage: permutive-sdk-helper [src directory] <your.xcodeproj> <xcode target>")
end

if ARGV.count == 3
  source = ARGV[0]
  xcodeProject = ARGV[1].chomp("/")
  xcodeTarget = ARGV[2]
elsif ARGV.count == 2
  xcodeProject = ARGV[0].chomp("/")
  xcodeTarget = ARGV[1]
else
  usage()
  return
end

if !File.directory?(source) || !File.exist?("#{xcodeProject}/project.pbxproj")
    usage()
    return
end

puts("permutive-sdk-helper. Searching '#{source}'")
source = source.chomp("/")

# Delete any existing generated file
PermutiveTools.deleteExistingGlue("#{source}/PermutiveHelper.swift")

# Find the structures which need extensions
structures = PermutiveTools.buildStructureList(source)
puts("Found #{structures.count} structs to extend")

# Generate the PermutiveHelper.swift glue file
PermutiveTools.generateGlueFile("#{source}/PermutiveHelper.swift", structures)
puts("Generated #{source}/PermutiveHelper.swift")

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

swiftFiles = Dir["#{source}/*.swift"]
PermutiveTools.addFilesToProject(project, swiftFiles, targetObject)
puts("Success: Added #{swiftFiles.count} files to project '#{xcodeProject}'")

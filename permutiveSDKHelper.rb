require "./PermutiveTools"

# Find the target directory for the Swift code.
source = "./"
if ARGV.count == 1
    source = ARGV[0]
end

puts("permutive-sdk-helper. Searching '#{source}'")
source = source.chomp("/")

# Delete any existing generated file
PermutiveTools.deleteExistingGlue("#{source}/PermutiveHelper.swift")

# Find the structures which need extensions
structures = PermutiveTools.buildStructureList(source)
puts("Found #{structures.count} structs to extend\n")

# Generate the PermutiveHelper.swift glue file
PermutiveTools.generateGlueFile("#{source}/PermutiveHelper.swift", structures)
puts("Generated #{source}/PermutiveHelper.swift")

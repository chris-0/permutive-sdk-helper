require 'xcodeproj'

module PermutiveTools
    def PermutiveTools.generateSwift(jsonDirectory, swiftDirectory)
        jsonFiles = Dir["#{jsonDirectory}/*.json"]
        jsonFiles.each { |file|
            swiftFilename = File.basename(file, ".json") + ".swift"
            swiftFilename = swiftDirectory + "/" + swiftFilename
            `quicktype --lang swift #{file} > #{swiftFilename}`
        }
    end
    
    def PermutiveTools.sanitiseSwift(files)
        files.each { |file|
            codeText = File.read(file)

            in_struct = false
            in_enum = false
            result = ""
            codeText.each_line do |line|
                if line.start_with? "struct "
                    in_struct = true
                elsif line.lstrip.start_with? "enum "
                    in_enum = true
                end
                
                if in_struct && !in_enum
                    result.concat(line)
                end
                
                if line.start_with? "}"
                    in_struct = false
                elsif line.lstrip.start_with? "}"
                    in_enum = false
                end
            end
            
            # Write sanitised content back
            begin
              orginalFile = File.open(file, "w")
              orginalFile.write(result)
            rescue IOError => e
              #some error occur, dir not writable etc.
            ensure
              orginalFile.close unless orginalFile.nil?
            end
        }
    end
    
    def PermutiveTools.deleteExistingGlue(filename)
        begin
          File.open(filename, 'r') do |f| File.delete(f)
        end
        rescue Errno::ENOENT
        end
    end
    
    def PermutiveTools.buildStructureList(swiftFiles)
        names = []
        swiftFiles.each { |file|
            structDeclaration = `swiftc -dump-parse #{file} | grep "struct_decl"`.split("\n")
            declNames = []
            structDeclaration.each { |decl|
                indent = (decl.index(/[^ ]/) / 2) - 1
                name = decl[/"(.*)"/, 1]
                          
                declNames = declNames.first(indent)
                declNames << name
                          
                names << declNames.join(".")
            }
        }
        names
    end
    
    def PermutiveTools.generateGlueFile(filename, structureList)
        # Generate Swift file boilerplate
        glueFileContent = [
          "//",
          "// Copyright 2020 Permutive Ltd.",
          "//",
          "",
          "",
          "import Permutive_iOS",
          "",
        ].join("\n") + "\n"
        
        eventNames = []
        # Generate required extension for each defined structure
        structureList.each { |structure|
            if !structure.include?(".") && structure.end_with?("Event")
                # If the structure name is top-level, keep as event name
                eventNames << structure
            end
        }
        
        # Generate track function for each defined event name
        eventNames.each { |eventName|
            eventFunction = [
            "func track(event: #{eventName}) throws {",
            "    guard let encoded = try? JSONEncoder().encode(event),",
            "        let dictionary = try? JSONSerialization.jsonObject(with: encoded) as? [String: AnyHashable]",
            "        else { return }",
            "",
            "    let properties = try EventProperties(dictionary)",
            "    try Permutive.track(event: \"#{eventName}\", properties: properties)",
            "}"
            ].join("\n") + "\n"
            glueFileContent.concat(eventFunction)
        }
        
        # Write content to file
        File.open(filename, 'w') { |file|
            file.write(glueFileContent)
        }
        
    end
                          
    def PermutiveTools.addFilesToProject(project, files, target)
      # Find a root folder in the users Xcode Project called Pods, or make one
      permutiveGroup = project.main_group["Permutive"]
      unless permutiveGroup
        puts("Creating group Permutive")
        permutiveGroup = project.main_group.new_group("Permutive")
      end

      # Add the files to the found Permutive group
      fileReferences = files.map { |file|
        filePath = Pathname.new(File.expand_path(file))
        puts("Processing #{filePath}")
                          
        fileRef = permutiveGroup.files.find { |groupFile| groupFile.real_path == filePath }
        unless fileRef
          fileRef = permutiveGroup.new_file(filePath)
        end
        fileRef
      }
                          
      # Ensure that the file is added to target
      unless target.source_build_phase.files_references.include?(fileReferences)
        target.add_file_references(fileReferences)
      end

      project.save
    end
end

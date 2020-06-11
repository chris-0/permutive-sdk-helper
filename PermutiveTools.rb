module PermutiveTools
    def PermutiveTools.deleteExistingGlue(filename)
        begin
          File.open(filename, 'r') do |f| File.delete(f)
        end
        rescue Errno::ENOENT
        end
    end
    
    def PermutiveTools.buildStructureList(directory)
        fileList = Dir["#{directory}/*.swift"]
        
        names = []
        fileList.each { |file|
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
          ""
        ].join("\n") + "\n"
        
        eventNames = []
        # Generate required extension for each defined structure
        structureList.each { |structure|
            glueFileContent.concat("extension #{structure}: Codable {}\n")
            if !structure.include? "."
                # If the structure name is top-level, keep as event name
                eventNames << structure
            end
        }
        
        # Generate track function for each defined event name
        eventNames.each { |eventName|
            eventFunction = [
            "\n",
            "func track(event: #{eventName}) {",
            "    guard let encoded = try? JSONEncoder().encode(event),",
            "        let dictionary = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any]",
            "        else { return }",
            "",
            "    let properties = EventProperties(dictionary)",
            "    Permutive.track(event: \"#{eventName}\", properties: properties)",
            "}"
            ].join("\n") + "\n"
            glueFileContent.concat(eventFunction)
        }
        
        # Write content to file
        File.open(filename, 'w') { |file|
            file.write(glueFileContent)
        }
        
    end
end

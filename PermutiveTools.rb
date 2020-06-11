module PermutiveTools
    
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
          "",
          "protocol EventType: Codable {}",
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

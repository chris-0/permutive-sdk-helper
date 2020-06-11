module PermutiveTools
    
    def PermutiveTools.generateGlueFile(filename, structureList)
        
        glueFileContent = [
          "import Permutive_iOS",
          "",
          "",
          "protocol EventType: Codable {}",
          "",
          ""
        ].join("\n") + "\n"
        
        eventNames = []
        structureList.each { |structure|
            glueFileContent.concat("extension #{structure}: Codable {}\n")
            if !structure.include? "."
                eventNames << structure
            end
        }
        
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

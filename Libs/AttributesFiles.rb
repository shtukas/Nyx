
# encoding: UTF-8

class AttributesFiles

    # AttributesFiles::loadInstructions(filepath)
    # return value: Array[Instruction]
    # Instruction = {:name, :value}
    def self.loadInstructions(filepath)
        return [] if !File.exists?(filepath)
        contents = IO.read(filepath)
        return [] if contents == ""
        contents
            .lines
            .map{|line| line.strip }
            .select{|line| line.size > 0 }
            .map{|line|
                i = line.index(":")
                if i.nil? then
                    nil
                else
                    {
                        "name" => line[0, i].strip,
                        "value" => line[i+1, line.size].strip
                    }
                end
            }
            .compact
    end

    # AttributesFiles::commitInstructions(filepath, instructions)
    def self.commitInstructions(filepath, instructions)
        contents = instructions.map{|instr| "#{instr["name"]}:#{instr["value"]}" }.join("\n")
        File.open(filepath, "w"){|f| f.puts(contents) }
    end

    # -------------------------------------------------------------
    # Getters

    # AttributesFiles::getOrNull(filepath, attrName)
    def self.getOrNull(filepath, attrName)
        instruction = AttributesFiles::loadInstructions(filepath)
                        .select{|instr| instr["name"] == attrName }
                        .first
        return nil if instruction.nil?
        instruction["value"]
    end

    # AttributesFiles::getMandatory(filepath, attrName)
    def self.getMandatory(filepath, attrName)
        value = AttributesFiles::getOrNull(filepath, attrName)
        if value.nil? then
            raise "[5e914588fefb3b68771d8f5ecd1e1f44: missing mandatory value for attribute name: #{attrName} at file: #{filepath}]"
        end
        value
    end

    # AttributesFiles::getArray(filepath, attrName)
    def self.getArray(filepath, attrName)
        AttributesFiles::loadInstructions(filepath)
            .select{|instr| instr["name"] == attrName }
            .map{|instr| instr["value"] }
    end

    # -------------------------------------------------------------
    # Setters

   # AttributesFiles::set(filepath, attrName, value)
    def self.set(filepath, attrName, value)
        instructions = AttributesFiles::loadInstructions(filepath)
        instructions = instructions.reject{|instr| instr["name"] == attrName }
        instruction = {
            "name" => attrName,
            "value" => value
        }
        instructions = instructions + [ instruction ]
        AttributesFiles::commitInstructions(filepath, instructions)
    end
end

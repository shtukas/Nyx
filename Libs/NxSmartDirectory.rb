
# encoding: UTF-8

class NxSmartDirectory

    # NxSmartDirectory::getUniqueStringOrNull(str)
    def self.getUniqueStringOrNull(str)
        # See NxSmartDirectory.txt for the assumptions we can work with
        return nil if !str.include?('[')
        return nil if !str.include?(']')
        while str[0,1] != "[" do
            str = str[1, str.size]
        end
        str = str[1, str.size]
        str = str[0, str.size-1]
        str
    end

    # NxSmartDirectory::getDescriptionFromFilename(filename)
    def self.getDescriptionFromFilename(filename)
        filename
    end
end

raise "138f15e4-b62d-01" if NxSmartDirectory::getUniqueStringOrNull("something [1234567]") != "1234567"
raise "138f15e4-b62d-02" if !NxSmartDirectory::getUniqueStringOrNull("something [1234567").nil?


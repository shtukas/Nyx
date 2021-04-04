
# encoding: UTF-8

class NX141FilenameReaderWriter

    # NX141FilenameReaderWriter::extractNX141MarkerFromFilenameOrNull(filename)
    def self.extractNX141MarkerFromFilenameOrNull(filename)
        # From the convention 
        # NX141-[*], where [*] is a string of unspecified length with no space and no dot.
        correction = lambda {|str|
            if str.include?(' ') then
                return correction.call(str[0, str.size-1])
            end
            if str.include?('.') then
                return correction.call(str[0, str.size-1])
            end
            str
        }
        if filename.include?('NX141-') then
            extraction = filename[filename.index('NX141-'), filename.size]
            return correction.call(extraction)
        end
        nil
    end

    # NX141FilenameReaderWriter::extractNX141MarkerFromLocationOrNull(location)
    def self.extractNX141MarkerFromLocationOrNull(location)
        NX141FilenameReaderWriter::extractNX141MarkerFromFilenameOrNull(File.basename(location))
    end

    # NX141FilenameReaderWriter::extractDescriptionFromFilename(filename)
    def self.extractDescriptionFromFilename(filename)
        nx141 = NX141FilenameReaderWriter::extractNX141MarkerFromFilenameOrNull(filename)
        if nx141 then
            filename = filename.gsub(nx141, "")
        end
        while filename.include?('.') do
            filename = filename[0, filename.size-1]
        end
        filename.strip
    end

    # NX141FilenameReaderWriter::extractDescriptionFromLocation(location)
    def self.extractDescriptionFromLocation(location)
        NX141FilenameReaderWriter::extractDescriptionFromFilename(File.basename(location))
    end

    # NX141FilenameReaderWriter::extractFileExtensionOrNull(filename)
    def self.extractFileExtensionOrNull(filename)
        File.extname(filename)
    end

    # NX141FilenameReaderWriter::makeLocationname(description, nx141mark, extension)
    def self.makeLocationname(description, nx141mark, extension)
        "#{description} #{nx141mark}#{extension ? extension : ""}"
    end

    # NX141FilenameReaderWriter::ensureLocationname(location, description, nx141mark, extension)
    def self.ensureLocationname(location, description, nx141mark, extension)
        raise "7fa0acb3-02cc-4c36-9ff7-a85a747bad94" if !File.exists?(location)
        return if (File.basename(location) == NX141FilenameReaderWriter::makeLocationname(description, nx141mark, extension))
        location2 = "#{File.dirname(location)}/#{NX141FilenameReaderWriter::makeLocationname(description, nx141mark, extension)}"
        FileUtils.mv(location, location2)
    end

    # NX141FilenameReaderWriter::ensureDescriptionAtLocation(location, description)
    def self.ensureDescriptionAtLocation(location, description)
        nx141mark = NX141FilenameReaderWriter::extractNX141MarkerFromLocationOrNull(location)
        return if nx141mark.nil?
        extension = NX141FilenameReaderWriter::extractFileExtensionOrNull(File.basename(location))
        NX141FilenameReaderWriter::ensureLocationname(location, description, nx141mark, extension)
    end

    # NX141FilenameReaderWriter::getFSChildrenWhichAreNX141(location)
    def self.getFSChildrenWhichAreNX141(location)
        return [] if File.file?(location)
        LucilleCore::locationsAtFolder(location).select{|l| NX141FilenameReaderWriter::extractNX141MarkerFromLocationOrNull(l) }
    end

    # NX141FilenameReaderWriter::selfTest()
    def self.selfTest()
        raise "[01]" if NX141FilenameReaderWriter::extractNX141MarkerFromFilenameOrNull("NX141 1234567.txt")    != nil
        raise "[02]" if NX141FilenameReaderWriter::extractNX141MarkerFromFilenameOrNull("NX141-1234567")        != "NX141-1234567"
        raise "[03]" if NX141FilenameReaderWriter::extractNX141MarkerFromFilenameOrNull("00 NX141-1234567")     != "NX141-1234567"
        raise "[04]" if NX141FilenameReaderWriter::extractNX141MarkerFromFilenameOrNull("NX141-1234567 00")     != "NX141-1234567"
        raise "[05]" if NX141FilenameReaderWriter::extractNX141MarkerFromFilenameOrNull("00 NX141-1234567.txt") != "NX141-1234567"

        raise "[06]" if NX141FilenameReaderWriter::extractDescriptionFromFilename("NX141 1234567.txt")          != "NX141 1234567"
        raise "[07]" if NX141FilenameReaderWriter::extractDescriptionFromFilename("NX141-1234567")              != ""
        raise "[08]" if NX141FilenameReaderWriter::extractDescriptionFromFilename("00 NX141-1234567")           != "00"
        raise "[09]" if NX141FilenameReaderWriter::extractDescriptionFromFilename("NX141-1234567 00")           != "00"
        raise "[10]" if NX141FilenameReaderWriter::extractDescriptionFromFilename("00 NX141-1234567 AA.txt")    != "00  AA"
    end
end

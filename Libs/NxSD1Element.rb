
# encoding: UTF-8

class NxSD1Element

    # NxSD1Element::toString(element)
    def self.toString(element)
        "[smart/e] #{element["locationName"]}"
    end

    # NxSD1Element::nx19s(nxSmartD1)
    def self.nx19s(nxSmartD1)
        NxSmartDirectory1::getNxSD1Elements(nxSmartD1).map{|element|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxSD1Element::toString(element)}",
                "type"     => "NxSD1Element",
                "payload"  => element
            }
        }
    end

    # NxSD1Element::getLocationForNxSD1ElementOrNull(element)
    def self.getLocationForNxSD1ElementOrNull(element)
        parentDirectory = NxSmartDirectory1::getDirectoryOrNull(element["mark"])
        return nil if parentDirectory.nil?
        "#{parentDirectory}/#{element["locationName"]}"
    end

    # NxSD1Element::landing(element)
    def self.landing(element)
        location = NxSD1Element::getLocationForNxSD1ElementOrNull(element)
        if location.nil? then
            puts "Interesting, I could not land on"
            puts JSON.pretty_generate(element)
            LucilleCore::pressEnterToContinue()
        end
        puts "opening: #{location}"
        if File.directory?(location) then
            system("open '#{location}'")
            LucilleCore::pressEnterToContinue()
        end
        if File.file?(location) then
            if Utils::fileByFilenameIsSafelyOpenable(File.basename(location)) then
                system("open '#{location}'")
            else
                system("open '#{File.dirname(location)}'")
            end
        end
    end

end

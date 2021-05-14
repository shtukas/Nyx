
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

    # NxSD1Element::landing(element)
    def self.landing(element)
        puts "You are landing on a NxSD1Element: '#{NxSD1Element::toString(element)}'"
        LucilleCore::pressEnterToContinue()
    end

end

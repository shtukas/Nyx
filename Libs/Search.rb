
# encoding: UTF-8

class Search

    # Search::nx19s()
    def self.nx19s()
        # NxSmartDirectory1::nx19s() also returns the NxSD1Elements
        NxListings::nx19s() + Nx27s::nx19s() + NxEvent1::nx19s() + NxSmartDirectory1::nx19s()
    end

    # Search::mx19Landing(mx19)
    def self.mx19Landing(mx19)
        if mx19["type"] == "NxListing" then
            NxListings::landing(mx19["payload"])
            return
        end
        if mx19["type"] == "Nx27" then
            Nx27s::landing(mx19["payload"])
            return
        end
        if mx19["type"] == "NxEvent1" then
            NxEvent1::landing(mx19["payload"])
            return
        end
        if mx19["type"] == "NxSmartDirectory" then
            NxSmartDirectory1::landing(mx19["payload"])
            return
        end
        if mx19["type"] == "NxSD1Element" then
            NxSD1Element::landing(mx19["payload"])
            return
        end
        raise "3a35f700-153a-484b-b4ac-c9489982b52b"
    end

    # Search::interactivelySelectOneNx19OrNull()
    def self.interactivelySelectOneNx19OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(Search::nx19s(), lambda{|item| item["announce"] })
    end

    # Search::searchLoop()
    def self.searchLoop()
        loop {
            mx19 = Search::interactivelySelectOneNx19OrNull()
            break if mx19.nil?
            Search::mx19Landing(mx19)
        }
    end
end

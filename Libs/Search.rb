
# encoding: UTF-8

class Search

    # Search::nx19s()
    def self.nx19s()
        NxListings::nx19s() + Nx27s::nx19s() # + Galaxy::mx19sAtRoot(root)
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
        if mx19["type"] == "GalaxyLocation" then
            puts mx19["location"]
            LucilleCore::pressEnterToContinue()
            return
        end
        raise "3a35f700-153a-484b-b4ac-c9489982b52b"
    end

    # Search::selectOneNx19OrNull()
    def self.selectOneNx19OrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(Search::nx19s(), lambda{|item| item["announce"] })
    end

    # Search::searchLoop()
    def self.searchLoop()
        loop {
            mx19 = Search::selectOneNx19OrNull()
            break if mx19.nil?
            Search::mx19Landing(mx19)
        }
    end

end

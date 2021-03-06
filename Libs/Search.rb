
# encoding: UTF-8

class Search

    # Search::nx19s()
    def self.nx19s()
        NxAsteroid::nx19s() +
        NxUniqueString::nx19s() +
        NxNode::nx19s() +
        NxDirectory2::nx19s() +
        NxTag::nx19s() +
        NxListing::nx19s() +
        NxEvent::nx19s() +
        NxTimelinePoint::nx19s()
    end

    # Search::mx19Landing(mx19)
    def self.mx19Landing(mx19)
        if mx19["type"] == "Nx27" then
            NxUniqueString::landing(mx19["payload"])
            return
        end
        if mx19["type"] == "Nx45" then
            NxAsteroid::landing(mx19["payload"])
            return
        end
        if mx19["type"] == "Nx10" then
            NxNode::landing(mx19["payload"])
            return
        end
        if mx19["type"] == "NxTag" then
            NxTag::landing(mx19["payload"])
            return
        end
        if mx19["type"] == "NxListing" then
            NxListing::landing(mx19["payload"])
            return
        end
        if mx19["type"] == "NxEvent" then
            NxEvent::landing(mx19["payload"])
            return
        end
        if mx19["type"] == "NxDirectory2" then
            NxDirectory2::landing(mx19["payload"])
            return
        end
        if mx19["type"] == "NxDirectoryElement" then
            NxDirectoryElement::landing(mx19["payload"])
            return
        end
        if mx19["type"] == "NxTimelinePoint" then
            NxTimelinePoint::landing(mx19["payload"])
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

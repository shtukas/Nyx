
# encoding: UTF-8

class Patricia

    # Patricia::isQuarks(quark)
    def self.isQuarks(quark)
        !quark["payload"].nil?
    end

    # -------------------------------------------------------

    # Patricia::selectOneNx19OrNull()
    def self.selectOneNx19OrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(Patricia::nx19s(), lambda{|item| item["announce"] })
    end

    # -------------------------------------------------------

    # Patricia::networkNodesInOrder()
    def self.networkNodesInOrder()
        Quarks::getQuarks().sort{|n1, n2| n1["unixtime"]<=>n2["unixtime"] }
    end

    # Patricia::nx19s()
    def self.nx19s()
        searchItems = [
            Tags::nx19s(),
            Quarks::nx19s(),
        ]
        .flatten
    end

    # Patricia::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            nx19 = Patricia::selectOneNx19OrNull()
            break if nx19.nil? 
            if nx19["nx15"]["type"] == "quark" then
                Quarks::landing(nx19["nx15"]["payload"])
            end
            if nx19["nx15"]["type"] == "tag" then
                Tags::landing(nx19["nx15"]["payload"])
            end
        }
    end
end

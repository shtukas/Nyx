
# encoding: UTF-8

class Patricia

    # -------------------------------------------------------

    # Patricia::selectOneMx19OrNull()
    def self.selectOneMx19OrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(Patricia::mx19s(), lambda{|item| item["announce"] })
    end

    # -------------------------------------------------------

    # Patricia::networkNodesInOrder()
    def self.networkNodesInOrder()
        NxPods::getNxPods().sort{|n1, n2| n1["unixtime"]<=>n2["unixtime"] }
    end

    # Patricia::mx19s()
    def self.mx19s()
        searchItems = [
            Tags::mx19s(),
            NxPods::mx19s(),
        ]
        .flatten
    end

    # Patricia::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            mx19 = Patricia::selectOneMx19OrNull()
            break if mx19.nil? 
            if mx19["mx15"]["type"] == "nxpod" then
                NxPods::landing(mx19["mx15"]["payload"])
            end
            if mx19["mx15"]["type"] == "tag" then
                Tags::landing(mx19["mx15"]["payload"])
            end
        }
    end
end

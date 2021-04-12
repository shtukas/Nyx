
# encoding: UTF-8

class Patricia

    # Patricia::isNxPods(nxpod)
    def self.isNxPods(nxpod)
        !nxpod["payload"].nil?
    end

    # -------------------------------------------------------

    # Patricia::selectOneSx19OrNull()
    def self.selectOneSx19OrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(Patricia::sx19s(), lambda{|item| item["announce"] })
    end

    # -------------------------------------------------------

    # Patricia::networkNodesInOrder()
    def self.networkNodesInOrder()
        NxPods::getNxPods().sort{|n1, n2| n1["unixtime"]<=>n2["unixtime"] }
    end

    # Patricia::sx19s()
    def self.sx19s()
        searchItems = [
            Tags::sx19s(),
            NxPods::sx19s(),
        ]
        .flatten
    end

    # Patricia::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            sx19 = Patricia::selectOneSx19OrNull()
            break if sx19.nil? 
            if sx19["sx15"]["type"] == "nxpod" then
                NxPods::landing(sx19["sx15"]["payload"])
            end
            if sx19["sx15"]["type"] == "tag" then
                Tags::landing(sx19["sx15"]["payload"])
            end
        }
    end
end

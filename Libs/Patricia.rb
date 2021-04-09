
# encoding: UTF-8

class Patricia

    # Patricia::isNereidElement(element)
    def self.isNereidElement(element)
        !element["payload"].nil?
    end

    # -------------------------------------------------------

    # Patricia::selectOneNx19OrNull()
    def self.selectOneNx19OrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(Patricia::nx19s(), lambda{|item| item["announce"] })
    end

    # -------------------------------------------------------

    # Patricia::networkNodesInOrder()
    def self.networkNodesInOrder()
        Olivia::getElements().sort{|n1, n2| n1["unixtime"]<=>n2["unixtime"] }
    end

    # Patricia::nx19s()
    def self.nx19s()
        searchItems = [
            Classification::nx19s(),
            Olivia::nx19s(),
        ]
        .flatten
    end

    # Patricia::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            nx19 = Patricia::selectOneNx19OrNull()
            break if nx19.nil? 
            if nx19["nx15"]["type"] == "neiredElement" then
                Olivia::landing(nx19["nx15"]["payload"])
            end
            if nx19["nx15"]["type"] == "classificationValue" then
                Classification::landing(nx19["nx15"]["payload"])
            end
        }
    end
end

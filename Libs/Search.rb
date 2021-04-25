
# encoding: UTF-8

class Search

    # Search::nodesMx19s()
    def self.nodesMx19s()
        Nodes::ids()
            .map{|id|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{Nodes::description(id)}",
                    "type"     => "node",
                    "id"       => id
                }
            }
    end

    # Search::selectOneNodeMx19OrNull()
    def self.selectOneNodeMx19OrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(Search::nodesMx19s(), lambda{|item| item["announce"] })
    end

    # Search::selectOneNodeIdOrNull()
    def self.selectOneNodeIdOrNull()
        mx19 = Search::selectOneNodeMx19OrNull()
        return if mx19.nil?
        mx19["id"]
    end

    # Search::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            mx19 = Search::selectOneNodeMx19OrNull()
            break if mx19.nil?
            if mx19["type"] == "node" then
                Nodes::landing(mx19["id"])
            end
        }
    end
end

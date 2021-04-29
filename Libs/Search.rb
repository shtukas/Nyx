
# encoding: UTF-8

class Search

    # Search::selectOneMx19OrNull()
    def self.selectOneMx19OrNull()
        mx19s = Nodes::nodesMx19s() + Galaxy::galaxyFileHierarchiesMx19s()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(mx19s, lambda{|item| item["announce"] })
    end

    # Search::selectOneMx19OrNullUsingPreFilter(pattern)
    def self.selectOneMx19OrNullUsingPreFilter(pattern)
        mx19s = Nodes::nodesMx19s() + Galaxy::galaxyFileHierarchiesMx19s()
        mx19s = mx19s.select{|mx19| mx19["announce"].downcase.include?(pattern.downcase) }
        Utils::selectOneObjectOrNullUsingInteractiveInterface(mx19s, lambda{|item| item["announce"] })
    end

    # Search::nodesSearchLoop()
    def self.nodesSearchLoop()
        loop {
            mx19 = Nodes::selectOneNodeMx19OrNull()
            break if mx19.nil?
            Nodes::preLandingAirSpaceController(mx19["id"])
        }
    end

    # Search::deepSearchLoop()
    def self.deepSearchLoop()
        loop {
            pattern = LucilleCore::askQuestionAnswerAsString("pattern: ")
            mx19 = Search::selectOneMx19OrNullUsingPreFilter(pattern)
            break if mx19.nil?
            if mx19["type"] == "node" then
                Nodes::preLandingAirSpaceController(mx19["id"])
            end
            if mx19["type"] == "galaxy-location" then
                puts mx19["location"]
                LucilleCore::pressEnterToContinue()
            end
        }
    end
end

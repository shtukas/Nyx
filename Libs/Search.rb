
# encoding: UTF-8

class Search

    # Search::mx19Landing(mx19)
    def self.mx19Landing(mx19)
        if mx19["type"] == "node" then
            Nodes::landing(mx19["id"])
            return
        end
        if mx19["type"] == "galaxy-location" then
            puts mx19["location"]
            LucilleCore::pressEnterToContinue()
            return
        end
        raise "3a35f700-153a-484b-b4ac-c9489982b52b"
    end

    # Search::searchLoopNetworkNodes()
    def self.searchLoopNetworkNodes()
        loop {
            mx19 = Nodes::selectOneNodeMx19OrNull()
            break if mx19.nil?
            Nodes::landing(mx19["id"])
        }
    end

    # Search::searchLoopFileHierarchyAtFolder(folderpath)
    def self.searchLoopFileHierarchyAtFolder(folderpath)
        mx19s = Galaxy::mx19sAtRoot(folderpath)
        loop {
            mx19 = Utils::selectOneObjectOrNullUsingInteractiveInterface(mx19s, lambda{|item| item["announce"] })
            return if mx19.nil?
            Search::mx19Landing(mx19)
        }
    end

    # Search::deepSearch()
    def self.deepSearch()
        loop {
            pattern = LucilleCore::askQuestionAnswerAsString("pattern (empty to exit): ")
            return if pattern == ""
            mx20s = Nodes::mx20s()
            mx20s = mx20s.select{|mx20| mx20["deep-searcheable"].downcase.include?(pattern.downcase) }
            loop {
                mx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("mx20", mx20s, lambda{|mx20| mx20["announce"] })
                break if mx20.nil?
                Search::mx19Landing(mx20)
            }
        }
    end
end

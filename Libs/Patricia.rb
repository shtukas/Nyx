
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

    # Patricia::importFolderInteractively()
    def self.importFolderInteractively()
        classificationValue = LucilleCore::askQuestionAnswerAsString("classification value for folder items: ")

        folderpath = LucilleCore::askQuestionAnswerAsString("parent folderpath: ")

        LucilleCore::locationsAtFolder(folderpath).each{|location|
            element = NereidInterface::issueAionPointElement(location)
            puts "Created element: #{NereidInterface::toString(element)}"
            Classification::insertRecord(SecureRandom.hex, element["uuid"], classificationValue)
        }
    end

    # -------------------------------------------------------

    # Patricia::networkNodesInOrder()
    def self.networkNodesInOrder()
        NereidInterface::getElements().sort{|n1, n2| n1["unixtime"]<=>n2["unixtime"] }
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

    # -------------------------------------------------------

    # Patricia::parentsChains(node)
    def self.parentsChains(node)
        chains = [
            {
                "objects" => [node]
            }
        ]

        chainIsComplete = lambda{|chain|
            Links::getLinkedObjectsParents(chain["objects"][0]).empty?
        }

        allChainsAreComplete = lambda{|chains|
            chains.all?{|chain| chainIsComplete.call(chain) }
        }

        updateChain = lambda{|chain|
            parents = Links::getLinkedObjectsParents(chain["objects"][0])
            return chain if parents.empty?
            parents.map{|parent|
                {
                    "objects" => [parent] + chain["objects"].clone
                }
                
            }
        }

        while !allChainsAreComplete.call(chains) do
            chains = chains.map{|chain| updateChain.call(chain) }.flatten
        end

        chains
    end

end

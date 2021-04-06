
# encoding: UTF-8

class Patricia

    # Patricia::isNereidElement(element)
    def self.isNereidElement(element)
        !element["payload"].nil?
    end

    # Patricia::isNavigationPoint(item)
    def self.isNavigationPoint(item)
        item["identifier1"] == "103df1ac-2e73-4bf1-a786-afd4092161d4"
    end

    # -------------------------------------------------------

    # Patricia::getNodeByUUIDOrNull(uuid)
    def self.getNodeByUUIDOrNull(uuid)
        item = NereidInterface::getElementOrNull(uuid)
        return item if item

        item = NavigationPoints::getNavigationPointByUUIDOrNull(uuid)
        return item if item

        nil
    end

    # Patricia::toString(item)
    def self.toString(item)
        if Patricia::isNereidElement(item) then
            return NereidInterface::toString(item)
        end
        if Patricia::isNavigationPoint(item) then
            return NavigationPoints::toString(item)
        end
        puts item
        raise "[error: d4c62cad-0080-4270-82a9-81b518c93c0e]"
    end

    # Patricia::landing(item)
    def self.landing(item)
        if Patricia::isNereidElement(item) then
            Olivia::landing(item)
            return
        end
        if Patricia::isNavigationPoint(item) then
            NavigationPoints::landing(item)
            return
        end
        puts item
        raise "[error: fb2fb533-c9e5-456e-a87f-0523219e91b7]"
    end

    # -------------------------------------------------------

    # Patricia::selectOneNodeOrNull()
    def self.selectOneNodeOrNull()
        searchItem = Utils::selectOneObjectOrNullUsingInteractiveInterface(Patricia::nyxSearchItemsAll(), lambda{|item| item["announce"] })
        return nil if searchItem.nil?
        searchItem["payload"]
    end

    # Patricia::achitectureNodeOrNull()
    def self.achitectureNodeOrNull()
        node = Patricia::selectOneNodeOrNull()
        return node if node
        choice = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["nereid element", "navigation point"])
        return nil if choice.nil?
        if choice == "nereid element" then
            return NereidInterface::interactivelyIssueNewElementOrNull()
        end
        if choice == "navigation point" then
            return NavigationPoints::interactivelyIssueNewNavigationPointOrNull()
        end
    end

    # Patricia::architectureZeroOrMoreNodes()
    def self.architectureZeroOrMoreNodes()
        nodes = []
        loop {
            node = Patricia::achitectureNodeOrNull()
            if node then
                nodes << node
            end
            if nodes.size > 0 then
                puts "Currently selected: "
                nodes.each{|node|
                    puts "    - #{Patricia::toString(node)}"
                }
                if LucilleCore::askQuestionAnswerAsBoolean("Make another one ? ") then
                    next
                else
                    break
                end
            end
        }
        nodes 
    end

    # Patricia::importFolderInteractively()
    def self.importFolderInteractively()
        # First we select the nodes we are going to attach the data to
        # Then we ask for the folder path
        # Then we import each location as aion point

        puts "First we architecture the nodes we are going to attach the data to"
        LucilleCore::pressEnterToContinue()
        nodes = Patricia::architectureZeroOrMoreNodes()
        return if nodes.empty?

        folderpath = LucilleCore::askQuestionAnswerAsString("parent folderpath: ")

        LucilleCore::locationsAtFolder(folderpath).each{|location|
            element = NereidInterface::issueAionPointElement(location)
            puts "Created element: #{Patricia::toString(element)}"
            nodes.each{|node|
                puts "    Linking to: #{Patricia::toString(node)} "
                Links::linkObjects(node, element)
            }
        }
    end

    # -------------------------------------------------------

    # Patricia::networkNodesInOrder()
    def self.networkNodesInOrder()
        (NereidInterface::getElements() + NavigationPoints::getNavigationPoints()).sort{|n1, n2| n1["unixtime"]<=>n2["unixtime"] }
    end

    # Patricia::nyxSearchItemsAll()
    def self.nyxSearchItemsAll()
        searchItems = [
            Olivia::nyxSearchItems(),
            NavigationPoints::nyxSearchItems()
        ]
        .flatten
    end

    # Patricia::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            dx7 = Patricia::selectOneNodeOrNull()
            break if dx7.nil? 
            Patricia::landing(dx7)
        }
    end

    # -------------------------------------------------------
end


# encoding: UTF-8

class Patricia

    # Patricia::isNereidElement(element)
    def self.isNereidElement(element)
        !element["payload"].nil?
    end

    # Patricia::isWave(object)
    def self.isWave(object)
        object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4"
    end

    # Patricia::isQuark(object)
    def self.isQuark(object)
        object["nyxNxSet"] == "d65674c7-c8c4-4ed4-9de9-7c600b43eaab"
    end

    # Patricia::isNavigationPoint(item)
    def self.isNavigationPoint(item)
        item["identifier1"] == "103df1ac-2e73-4bf1-a786-afd4092161d4"
    end

    # -------------------------------------------------------

    # Patricia::getNyxNetworkNodeByUUIDOrNull(uuid)
    def self.getNyxNetworkNodeByUUIDOrNull(uuid)
        item = NereidInterface::getElementOrNull(uuid)
        return item if item

        item = NyxNavigationPoints::getNavigationPointByUUIDOrNull(uuid)
        return item if item

        nil
    end

    # Patricia::toString(item)
    def self.toString(item)
        if Patricia::isNereidElement(item) then
            return NereidInterface::toString(item)
        end
        if Patricia::isNavigationPoint(item) then
            return NyxNavigationPoints::toString(item)
        end
        if Patricia::isQuark(item) then
            return Quarks::toString(item)
        end
        if Patricia::isWave(item) then
            return Waves::toString(item)
        end
        puts item
        raise "[error: d4c62cad-0080-4270-82a9-81b518c93c0e]"
    end

    # Patricia::landing(item)
    def self.landing(item)
        if Patricia::isNereidElement(item) then
            NereidNyxExt::landing(item)
            return
        end
        if Patricia::isNavigationPoint(item) then
            NyxNavigationPoints::landing(item)
            return
        end
        if Patricia::isQuark(item) then
            Quarks::landing(item)
            return
        end
        if Patricia::isWave(item) then
            Waves::landing(item)
            return 
        end
        puts item
        raise "[error: fb2fb533-c9e5-456e-a87f-0523219e91b7]"
    end

    # -------------------------------------------------------

    # Patricia::selectOneNodeOrNull()
    def self.selectOneNodeOrNull()
        searchItem = CatalystUtils::selectOneObjectOrNullUsingInteractiveInterface(Patricia::nyxSearchItemsAll(), lambda{|item| item["announce"] })
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
            return NyxNavigationPoints::interactivelyIssueNewNavigationPointOrNull()
        end
    end

    # Patricia::selectOneOfTheLinkedNodeOrNull(node)
    def self.selectOneOfTheLinkedNodeOrNull(node)
        related = Network::getLinkedObjectsInTimeOrder(node)
        return if related.empty?
        LucilleCore::selectEntityFromListOfEntitiesOrNull("related", related, lambda{|node| Patricia::toString(node) })
    end

    # -------------------------------------------------------

    # Patricia::nyxSearchItemsAll()
    def self.nyxSearchItemsAll()
        searchItems = [
            NereidNyxExt::nyxSearchItems(),
            NyxNavigationPoints::nyxSearchItems()
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

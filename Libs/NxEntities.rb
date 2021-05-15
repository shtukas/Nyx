
# encoding: UTF-8

class NxEntities

    # NxEntities::getEntityByIdOrNull(uuid)
    def self.getEntityByIdOrNull(uuid)
        entity = Nx27s::getNx27ByIdOrNull(uuid)
        return entity if entity
        entity = NxListings::getListingByIdOrNull(uuid)
        return entity if entity
        entity = NxEvent1::getNxEvent1ByIdOrNull(uuid)
        return entity if entity
        entity = NxSmartDirectory1::getNxSmartDirectory1ByIdOrNull(uuid)
        return entity if entity
        entity = NxTag::getTagByIdOrNull(uuid)
        return entity if entity
        nil
    end

    # NxEntities::toString(entity)
    def self.toString(entity)
        if entity["entityType"] == "Nx27" then
            return Nx27s::toString(entity)
        end
        if entity["entityType"] == "NxListing" then
            return NxListings::toString(entity)
        end
        if entity["entityType"] == "NxEvent1" then
            return NxEvent1::toString(entity)
        end
        if entity["entityType"] == "NxSmartDirectory" then
            return NxSmartDirectory1::toString(entity)
        end
        if entity["entityType"] == "NxSD1Element" then
            return NxSD1Element::toString(entity)
        end
        if entity["entityType"] == "NxTag" then
            return NxTag::toString(entity)
        end
        raise "1f4f2950-acf2-4136-ba09-7a180338393f"
    end

    # NxEntities::landing(entity)
    def self.landing(entity)
        if entity["entityType"] == "Nx27" then
            return Nx27s::landing(entity)
        end
        if entity["entityType"] == "NxListing" then
            return NxListings::landing(entity)
        end
        if entity["entityType"] == "NxEvent1" then
            return NxEvent1::landing(entity)
        end
        if entity["entityType"] == "NxSmartDirectory" then
            return NxSmartDirectory1::landing(entity)
        end
        if entity["entityType"] == "NxSD1Element" then
            return NxSD1Element::landing(entity)
        end
        if entity["entityType"] == "NxTag" then
            return NxTag::landing(entity)
        end
        raise "252103a9-c5f5-4206-92d7-c01fc91f8a06"
    end

    # NxEntities::entities()
    def self.entities()
        Nx27s::nx27s() + NxListings::nxListings() + NxEvent1::nxEvent1s() + NxSmartDirectory1::nxSmartDirectories() + NxTag::nxTags()
    end

    # NxEntities::selectExistingEntityOrNull()
    def self.selectExistingEntityOrNull()
        nx19 = Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxEntities::entities(), lambda{|entity| NxEntities::toString(entity) })
        return nil if nx19.nil?
    end

    # NxEntities::interactivelyCreateNewEntityOrNull()
    def self.interactivelyCreateNewEntityOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("entity type", ["(nx27)", "listing", "event"])
        return nil if type.nil?
        if type == "(nx27)" then
            return Nx27s::interactivelyCreateNewNx27OrNull()
        end
        if type == "listing" then
            return NxListings::interactivelyCreateNewNxListingOrNull()
        end
        if type == "event" then
            return NxEvent1::interactivelyCreateNewNxEvent1OrNull()
        end
        raise "1902268c-f5e3-45fb-bcf5-573f4c14f160"
    end

    # NxEntities::architectEntityOrNull()
    def self.architectEntityOrNull()
        entity = NxEntities::selectExistingEntityOrNull()
        return entity if entity
        NxEntities::interactivelyCreateNewEntityOrNull()
    end

    # NxEntities::connectToOtherArchitectured(entity)
    def self.connectToOtherArchitectured(entity)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("connection type", ["parent -> child", "related", "child -> parent"])
        return if type.nil?
        other = NxEntities::architectEntityOrNull()
        return if other.nil?
        if type == "parent -> child" then
            Arrows::insert(entity["uuid"], other["uuid"])
        end
        if type == "related" then
            Links::insert(entity["uuid"], other["uuid"])
        end
        if type == "child -> parent" then
            Arrows::insert(other["uuid"], entity["uuid"])
        end
    end

    # NxEntities::connected(entity)
    def self.connected(entity)
         Arrows::parents(entity["uuid"]) + Links::entities(entity["uuid"]) + Arrows::children(entity["uuid"])
    end

    # NxEntities::disconnectFromOther(entity)
    def self.disconnectFromOther(entity)
        other = LucilleCore::selectEntityFromListOfEntitiesOrNull("connected", NxEntities::connected(entity))
        return if other.nil?
        Links::delete(entity["uuid"], other["uuid"])
        Arrows::delete(entity["uuid"], other["uuid"])
        Arrows::delete(other["uuid"], entity["uuid"])
    end
end

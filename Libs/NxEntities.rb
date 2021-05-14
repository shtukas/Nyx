
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
        raise "252103a9-c5f5-4206-92d7-c01fc91f8a06"
    end

    # NxEntities::entities()
    def self.entities()
        Nx27s::nx27s() + NxListings::nxListings() + NxEvent1::nxEvent1s()
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
end

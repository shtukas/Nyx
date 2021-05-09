
# encoding: UTF-8

class NxEntities

    # NxEntities::getEntityByIdOrNull(uuid)
    def self.getEntityByIdOrNull(uuid)
        entity = NxListings::getListingByIdOrNull(uuid)
        return entity if entity
        entity = Nx27s::getNx27ByIdOrNull(uuid)
        return entity if entity
        nil
    end

    # NxEntities::toString(entity)
    def self.toString(entity)
        if entity["entityType"] == "Nx21" then
            return NxListings::toString(entity)
        end
        if entity["entityType"] == "Nx27" then
            return Nx27s::toString(entity)
        end
        raise "1f4f2950-acf2-4136-ba09-7a180338393f"
    end

    # NxEntities::landing(entity)
    def self.landing(entity)
        if entity["entityType"] == "Nx21" then
            return NxListings::landing(entity)
        end
        if entity["entityType"] == "Nx27" then
            return Nx27s::landing(entity)
        end
        raise "252103a9-c5f5-4206-92d7-c01fc91f8a06"
    end

    # NxEntities::entities()
    def self.entities()
        NxListings::nx21s() + Nx27s::nx27s()
    end

    # NxEntities::selectExistingEntityOrNull()
    def self.selectExistingEntityOrNull()
        nx19 = Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxEntities::entities(), lambda{|entity| NxEntities::toString(entity) })
        return nil if nx19.nil?
    end

    # NxEntities::interactivelyCreateNewEntityOrNull()
    def self.interactivelyCreateNewEntityOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("entity type", ["listing (nx21)", "entry (nx27)"])
        return nil if type.nil?
        if type == "listing (nx21)" then
            return NxListings::interactivelyCreateNewListingNx21OrNull()
        end
        if type == "entry (nx27)" then
            return Nx27s::interactivelyCreateNewNx27OrNull()
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

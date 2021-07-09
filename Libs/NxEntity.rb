
# encoding: UTF-8

class NxEntity

    # NxEntity::getEntityByIdOrNull(uuid)
    def self.getEntityByIdOrNull(uuid)
        entity = Nx27::getNx27ByIdOrNull(uuid)
        return entity if entity
        entity = Nx10::getNx10ByIdOrNull(uuid)
        return entity if entity
        entity = Nx45AstPointer::getNx45ByIdOrNull(uuid)
        return entity if entity
        entity = NxTag::getTagByIdOrNull(uuid)
        return entity if entity
        entity = NxListing::getListingByIdOrNull(uuid)
        return entity if entity
        entity = NxEvent::getNxEventByIdOrNull(uuid)
        return entity if entity
        entity = NxSmartDirectory::getNxSmartDirectoryByIdOrNull(uuid)
        return entity if entity
        entity = NxFSPermaPoint::getPointByIdOrNull(uuid)
        return entity if entity
        entity = NxTimelinePoint::getNxTimelinePointByIdOrNull(uuid)
        return entity if entity
        nil
    end

    # NxEntity::toString(entity)
    def self.toString(entity)
        if entity["entityType"] == "Nx27" then
            return Nx27::toString(entity)
        end
        if entity["entityType"] == "Nx10" then
            return Nx10::toString(entity)
        end
        if entity["entityType"] == "Nx45" then
            return Nx45AstPointer::toString(entity)
        end
        if entity["entityType"] == "NxTag" then
            return NxTag::toString(entity)
        end
        if entity["entityType"] == "NxListing" then
            return NxListing::toString(entity)
        end
        if entity["entityType"] == "NxEvent" then
            return NxEvent::toString(entity)
        end
        if entity["entityType"] == "NxSmartDirectory" then
            return NxSmartDirectory::toString(entity)
        end
        if entity["entityType"] == "NxFSPermaPoint" then
            return NxFSPermaPoint::toString(entity)
        end
        if entity["entityType"] == "NxTimelinePoint" then
            return NxTimelinePoint::toString(entity)
        end
        raise "1f4f2950-acf2-4136-ba09-7a180338393f"
    end

    # NxEntity::landing(entity)
    def self.landing(entity)
        if entity["entityType"] == "Nx27" then
            return Nx27::landing(entity)
        end
        if entity["entityType"] == "Nx10" then
            return Nx10::landing(entity)
        end
        if entity["entityType"] == "Nx45" then
            return Nx45AstPointer::landing(entity)
        end
        if entity["entityType"] == "NxTag" then
            return NxTag::landing(entity)
        end
        if entity["entityType"] == "NxListing" then
            return NxListing::landing(entity)
        end
        if entity["entityType"] == "NxEvent" then
            return NxEvent::landing(entity)
        end
        if entity["entityType"] == "NxSmartDirectory" then
            return NxSmartDirectory::landing(entity)
        end
        if entity["entityType"] == "NxFSPermaPoint" then
            return NxFSPermaPoint::landing(entity)
        end
        if entity["entityType"] == "NxTimelinePoint" then
            return NxTimelinePoint::landing(entity)
        end
        raise "252103a9-c5f5-4206-92d7-c01fc91f8a06"
    end

    # NxEntity::entities()
    def self.entities()
        Nx27::nx27s() + 
        Nx10::nx10s() + 
        Nx45AstPointer::nx45s() + 
        NxTag::nxTags() + 
        NxListing::nxListings() + 
        NxEvent::events() + 
        NxSmartDirectory::nxSmartDirectories() + 
        NxFSPermaPoint::getAll() +
        NxTimelinePoint::points()
    end

    # NxEntity::selectExistingEntityOrNull()
    def self.selectExistingEntityOrNull()
        nx19 = Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxEntity::entities(), lambda{|entity| NxEntity::toString(entity) })
        return nil if nx19.nil?
        nx19
    end

    # NxEntity::interactivelyCreateNewEntityOrNull()
    def self.interactivelyCreateNewEntityOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("entity type", ["url", "text", "aion-point", "unique-string", "node", "tag", "listing", "event", "timeline point"])
        return nil if type.nil?
        if type == "url" then
            return Nx45AstPointer::interactivelyCreateNewUrlOrNull()
        end
        if type == "text" then
            return Nx27::interactivelyCreateNewTextOrNull()
        end
        if type == "aion-point" then
            return Nx27::interactivelyCreateNewAionPointOrNull()
        end
        if type == "unique-string" then
            return Nx27::interactivelyCreateNewUniqueStringOrNull()
        end
        if type == "node" then
            return Nx10::interactivelyCreateNewNx10OrNull()
        end
        if type == "tag" then
            return NxTag::interactivelyCreateNewNxTagOrNull()
        end
        if type == "listing" then
            return NxListing::interactivelyCreateNewNxListingOrNull()
        end
        if type == "event" then
            return NxEvent::interactivelyCreateNewNxEventOrNull()
        end
        if type == "timeline point" then
            return NxTimelinePoint::interactivelyCreateNewPointOrNull()
        end
        raise "1902268c-f5e3-45fb-bcf5-573f4c14f160"
    end

    # NxEntity::architectEntityOrNull()
    def self.architectEntityOrNull()
        operations = ["existing || new", "new"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "existing || new" then
            puts "-> existing"
            sleep 1
            entity = NxEntity::selectExistingEntityOrNull()
            return entity if entity
            puts "-> new"
            sleep 1
            return NxEntity::interactivelyCreateNewEntityOrNull()
        end
        if operation == "new" then
            return NxEntity::interactivelyCreateNewEntityOrNull()
        end
    end

    # NxEntity::linkToOtherArchitectured(entity)
    def self.linkToOtherArchitectured(entity)
        other = NxEntity::architectEntityOrNull()
        return if other.nil?
        Links::insert(entity["uuid"], other["uuid"])
    end

    # NxEntity::linked(entity)
    def self.linked(entity)
         Links::entities(entity["uuid"])
    end

    # NxEntity::unlinkFromOther(entity)
    def self.unlinkFromOther(entity)
        other = LucilleCore::selectEntityFromListOfEntitiesOrNull("connected", NxEntity::linked(entity))
        return if other.nil?
        Links::delete(entity["uuid"], other["uuid"])
    end
end

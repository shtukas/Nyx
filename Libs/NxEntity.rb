
# encoding: UTF-8

class NxEntity

    # NxEntity::getEntityByIdOrNull(uuid)
    def self.getEntityByIdOrNull(uuid)
        entity = NxUniqueString::getNx27ByIdOrNull(uuid)
        return entity if entity
        entity = NxNode::getNx10ByIdOrNull(uuid)
        return entity if entity
        entity = NxAsteroid::getAsteroidByUUIDOrNull(uuid)
        return entity if entity
        entity = NxTag::getTagByIdOrNull(uuid)
        return entity if entity
        entity = NxListing::getListingByIdOrNull(uuid)
        return entity if entity
        entity = NxEvent::getNxEventByIdOrNull(uuid)
        return entity if entity
        entity = NxDirectory2::directoryIdToNxDirectory2OrNull(uuid)
        return entity if entity
        entity = NxTimelinePoint::getNxTimelinePointByIdOrNull(uuid)
        return entity if entity
        nil
    end

    # NxEntity::toString(entity)
    def self.toString(entity)
        if entity["entityType"] == "Nx27" then
            return NxUniqueString::toString(entity)
        end
        if entity["entityType"] == "Nx10" then
            return NxNode::toString(entity)
        end
        if entity["entityType"] == "Nx45" then
            return NxAsteroid::toString(entity)
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
        if entity["entityType"] == "NxDirectory2" then
            return NxDirectory2::toString(entity)
        end
        if entity["entityType"] == "NxTimelinePoint" then
            return NxTimelinePoint::toString(entity)
        end
        raise "1f4f2950-acf2-4136-ba09-7a180338393f"
    end

    # NxEntity::landing(entity)
    def self.landing(entity)
        if entity["entityType"] == "Nx27" then
            return NxUniqueString::landing(entity)
        end
        if entity["entityType"] == "Nx10" then
            return NxNode::landing(entity)
        end
        if entity["entityType"] == "Nx45" then
            return NxAsteroid::landing(entity)
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
        if entity["entityType"] == "NxDirectory2" then
            return NxDirectory2::landing(entity)
        end
        if entity["entityType"] == "NxTimelinePoint" then
            return NxTimelinePoint::landing(entity)
        end
        raise "252103a9-c5f5-4206-92d7-c01fc91f8a06"
    end

    # NxEntity::entities()
    def self.entities()
        NxUniqueString::nx27s() + 
        NxNode::nx10s() + 
        NxAsteroid::nx45s() + 
        NxTag::nxTags() + 
        NxListing::nxListings() + 
        NxEvent::events() + 
        NxDirectory2::directories() +
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
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("entity type", ["url", "text", "aion-point", "unique-string", "node", "NxDirectory2", "tag", "listing", "event", "timeline point"])
        return nil if type.nil?
        if type == "url" then
            return NxAsteroid::interactivelyCreateNewUrlOrNull()
        end
        if type == "text" then
            return NxAsteroid::interactivelyCreateNewTextOrNull()
        end
        if type == "aion-point" then
            return NxAsteroid::interactivelyCreateNewAionPointOrNull()
        end
        if type == "unique-string" then
            return NxUniqueString::interactivelyCreateNewUniqueStringOrNull()
        end
        if type == "node" then
            return NxNode::interactivelyCreateNewNx10OrNull()
        end
        if type == "NxDirectory2" then
            return NxDirectory2::interactivelyRegisterNewNxDirectoryOrNull()
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

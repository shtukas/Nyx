
# encoding: UTF-8

# -----------------------------------------------------------------------

class Fsck

    # Fsck::checkEntity(object)
    def self.checkEntity(object)
        if object["entityType"] == "Nx27" then
            if object["type"] == "unique-string" then
                # Nothing to do
                return true
            end
            if object["type"] == "url" then
                # Nothing to do
                return true
            end
            if object["type"] == "text" then
                status = !BinaryBlobsService::getBlobOrNull(object["nhash"]).nil?
                return status
            end
            if object["type"] == "aion-point" then
                return AionFsck::structureCheckAionHash(Elizabeth.new(), object["nhash"])
            end
            raise "be51fe9f-f41e-4616-9dcd-3d58acf03f98: #{object}"
        end
        if object["entityType"] == "Nx10" then
    
        end
        if object["entityType"] == "NxTag" then

        end
        if object["entityType"] == "NxListing" then

        end
        if object["entityType"] == "NxEvent" then

        end
        if object["entityType"] == "NxSmartDirectory" then

        end
        if object["entityType"] == "NxFSPermaPoint" then

        end
        if object["entityType"] == "NxTimelinePoint" then

        end
        raise "cd97f89c-5fad-4b21-a365-65a0ad9228a9: #{object}"
    end

    # Fsck::fsckEntities()
    def self.fsckEntities()
        NxEntity::entities().each{|entity|
            puts "checking: uuid: #{entity["uuid"]}, #{entity["entityType"]}"
            status = Fsck::checkEntity(entity)
            if !status then
                puts "Failed".red
                LucilleCore::pressEntryToContinue()
            end
        }
    end

end


# encoding: UTF-8

class NxTag

    # NxTag::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/NxTag.sqlite3"
    end

    # NxTag::insertTag(uuid, description)
    def self.insertTag(uuid, description)
        db = SQLite3::Database.new(NxTag::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _tags_ (_uuid_, _description_) values (?,?)", [uuid, description]
        db.close
    end

    # NxTag::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(NxTag::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _tags_ where _uuid_=?", [uuid]
        db.close
    end

    # NxTag::getTagByIdOrNull(id): null or NxTag
    def self.getTagByIdOrNull(id)
        db = SQLite3::Database.new(NxTag::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _tags_ where _uuid_=?" , [id] ) do |row|
            answer = {
                "entityType"  => "NxTag",
                "uuid"        => row["_uuid_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # NxTag::interactivelyCreateNewNxTagOrNull()
    def self.interactivelyCreateNewNxTagOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxTag::createNewTag(uuid, description)
        NxTag::getTagByIdOrNull(uuid)
    end

    # NxTag::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(NxTag::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _tags_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # NxTag::nxTags(): Array[NxTag]
    def self.nxTags()
        db = SQLite3::Database.new(NxTag::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _tags_" , [] ) do |row|
            answer << {
                "entityType"  => "NxTag",
                "uuid"        => row["_uuid_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # NxTag::toString(nxTag)
    def self.toString(nxTag)
        "[tag] #{nxTag["description"]}"
    end

    # NxTag::selectOneNxTagOrNull()
    def self.selectOneNxTagOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxTag::nxTags(), lambda{|nxTag| nxTag["description"] })
    end

    # NxTag::architectOneNxTagOrNull()
    def self.architectOneNxTagOrNull()
        nxTag = NxTag::selectOneNxTagOrNull()
        return nxTag if nxTag
        NxTag::interactivelyCreateNewNxTagOrNull()
    end

    # NxTag::landing(nxTag)
    def self.landing(nxTag)
        loop {
            nxTag = NxTag::getTagByIdOrNull(nxTag["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nxTag.nil?
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            puts NxTag::toString(nxTag).green
            puts ""
            Links::entities(nxTag["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item("[linked] #{NxEntities::toString(entity)}", lambda {
                        NxEntities::landing(entity)
                    })
                }
            puts ""
            mx.item("update description".yellow, lambda {
                description = Utils::editTextSynchronously(nxTag["description"]).strip
                return if description == ""
                NxTag::updateDescription(nxTag["uuid"], description)
            })
            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    NxTag::destroyTag(nxTag["uuid"])
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NxTag::nx19s()
    def self.nx19s()
        NxTag::nxTags().map{|nxTag|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxTag::toString(nxTag)}",
                "type"     => "NxTag",
                "payload"  => nxTag
            }
        }
    end
end

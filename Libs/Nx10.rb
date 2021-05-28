
# encoding: UTF-8

class Nx10s

    # Nx10s::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/Nx10s.sqlite3"
    end

    # Nx10s::createNewNx10(uuid, datetime, description)
    def self.createNewNx10(uuid, datetime, description)
        db = SQLite3::Database.new(Nx10s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _nx10s_ (_uuid_, _datetime_, _description_) values (?,?,?)", [uuid, datetime, description]
        db.close
    end

    # Nx10s::destroyNx10(uuid)
    def self.destroyNx10(uuid)
        db = SQLite3::Database.new(Nx10s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _nx10s_ where _uuid_=?", [uuid]
        db.close
    end

    # Nx10s::getNx10ByIdOrNull(id): null or Nx10
    def self.getNx10ByIdOrNull(id)
        db = SQLite3::Database.new(Nx10s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _nx10s_ where _uuid_=?" , [id] ) do |row|
            answer = {
                "uuid"        => row["_uuid_"],
                "entityType"  => "Nx10",
                "datetime"    => row["_datetime_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # Nx10s::interactivelyCreateNewNx10OrNull()
    def self.interactivelyCreateNewNx10OrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Nx10s::createNewNx10(uuid, Time.new.utc.iso8601, description)
        Nx10s::getNx10ByIdOrNull(uuid)
    end

    # Nx10s::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(Nx10s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _nx10s_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # Nx10s::nx10s(): Array[Nx10]
    def self.nx10s()
        db = SQLite3::Database.new(Nx10s::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _nx10s_" , [] ) do |row|
            answer << {
                "uuid"        => row["_uuid_"],
                "entityType"  => "Nx10",
                "datetime"    => row["_datetime_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # Nx10s::toString(nx10)
    def self.toString(nx10)
        "[node] #{nx10["description"]}"
    end

    # Nx10s::selectOneNx10OrNull()
    def self.selectOneNx10OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(Nx10s::nx10s(), lambda{|nx10| Nx10s::toString(nx10) })
    end

    # Nx10s::architectOneNx10OrNull()
    def self.architectOneNx10OrNull()
        nx10 = Nx10s::selectOneNx10OrNull()
        return nx10 if nx10
        Nx10s::interactivelyCreateNewNx10OrNull()
    end

    # Nx10s::landing(nx10)
    def self.landing(nx10)
        loop {
            nx10 = Nx10s::getNx10ByIdOrNull(nx10["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx10.nil?
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            puts Nx10s::toString(nx10).green
            puts ""
            Links::entities(nx10["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each{|entity|
                    mx.item("[linked] #{NxEntities::toString(entity)}", lambda {
                        NxEntities::landing(entity)
                    })
                }
            puts ""
            mx.item("update description".yellow, lambda {
                description = Utils::editTextSynchronously(nx10["description"]).strip
                return if description == ""
                Nx10s::updateDescription(nx10["uuid"], description)
            })
            mx.item("connect to other".yellow, lambda {
                NxEntities::linkToOtherArchitectured(nx10)
            })
            mx.item("unlink from other".yellow, lambda {
                NxEntities::unlinkFromOther(nx10)
            })
            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy node ? : ") then
                    Nx10s::destroyNx10(nx10["uuid"])
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Nx10s::nx19s()
    def self.nx19s()
        Nx10s::nx10s().map{|nx10|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{Nx10s::toString(nx10)}",
                "type"     => "Nx10",
                "payload"  => nx10
            }
        }
    end
end

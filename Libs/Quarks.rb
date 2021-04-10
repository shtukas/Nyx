
# encoding: UTF-8

class Quarks

    # Quarks::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = SecureRandom.hex
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # Quarks::openUrl(url)
    def self.openUrl(url)
        system("open -a Safari '#{url}'")
    end

    # --------------------------------------------------------------------

    # Quarks::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Nyx/Quarks.sqlite3"
    end

    # Quarks::commitToDatabase(uuid, unixtime, description)
    def self.commitToDatabase(uuid, unixtime, description)
        db = SQLite3::Database.new(Quarks::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _datacarrier_ where _uuid_=?", [uuid]
        db.execute "insert into _datacarrier_ (_uuid_, _unixtime_, _description_) values (?,?,?)", [uuid, unixtime, description]
        db.commit 
        db.close
    end

    # Quarks::getQuarks()
    def self.getQuarks()
        db = SQLite3::Database.new(Quarks::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _datacarrier_", []) do |row|
            answer << {
                "uuid"        => row['_uuid_'], 
                "unixtime"    => row['_unixtime_'],
                "description" => row['_description_']
            }
        end
        db.close
        answer
    end

    # Quarks::getQuarkOrNull(uuid)
    def self.getQuarkOrNull(uuid)
        db = SQLite3::Database.new(Quarks::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _datacarrier_ where _uuid_=?", [uuid]) do |row|
            answer = {
                "uuid"        => row['_uuid_'], 
                "unixtime"    => row['_unixtime_'],
                "description" => row['_description_'],
                "type"        => row['_type_'],
                "payload"     => row['_payload_']
            }
        end
        db.close
        answer
    end

    # Quarks::destroyQuark(uuid)
    def self.destroyQuark(uuid)
        FileSystemAdapter::destroyQuarkOnDisk(uuid)

        db = SQLite3::Database.new(Quarks::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _datacarrier_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end

    # --------------------------------------------------------------------

    # Quarks::toString(quark)
    def self.toString(quark)
        quark["description"]
    end

    # Quarks::interactivelyIssueNewQuarkOrNull()
    def self.interactivelyIssueNewQuarkOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Line" | "Url" | "Text" | "UniqueFileClickable" | "FSLocation" | "FSUniqueString"])
        return nil if type.nil?
        if type == "Line" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return nil if description == ""
            payload = ""
            Quarks::commitToDatabase(uuid, unixtime, description)
            FileSystemAdapter::makeNewQuark(uuid, description, "Line", description)
            return Quarks::getQuarkOrNull(uuid)
        end
        if type == "Url" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url == ""
            description = LucilleCore::askQuestionAnswerAsString("description (optional): ")
            if description == "" then
                description = url
            end
            Quarks::commitToDatabase(uuid, unixtime, description)
            FileSystemAdapter::makeNewQuark(uuid, description, "Url", url)
            return Quarks::getQuarkOrNull(uuid)
        end
        if type == "Text" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            text = Utils::editTextSynchronously("")
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
            Quarks::commitToDatabase(uuid, unixtime, description)
            FileSystemAdapter::makeNewQuark(uuid, description, "Text", text)
            return Quarks::getQuarkOrNull(uuid)
        end
        if type == "UniqueFileClickable" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i

            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            filepath = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            return nil if !File.exists?(filepath)

            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""

            Quarks::commitToDatabase(uuid, unixtime, description)
            FileSystemAdapter::makeNewQuark(uuid, description, "UniqueFileClickable", filepath)
            return Quarks::getQuarkOrNull(uuid)
        end
        if type == "FSLocation" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i

            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            return nil if !File.exists?(location)

            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""

            Quarks::commitToDatabase(uuid, unixtime, description)
            FileSystemAdapter::makeNewQuark(uuid, description, "FSLocation", location)
            return Quarks::getQuarkOrNull(uuid)
        end
        if type == "FSUniqueString" then
            raise "FSUniqueString not implemented yet"
        end
        nil
    end

    # Quarks::landing(quark)
    def self.landing(quark)

        loop {

            puts "-- Quark -----------------------------"

            quark = Quarks::getQuarkOrNull(quark["uuid"]) # could have been deleted or transmuted in the previous loop
            return if quark.nil?

            puts Quarks::toString(quark).green

            puts "uuid: #{quark["uuid"]}".yellow
            puts "type: #{FileSystemAdapter::getQuarkType(quark["uuid"])}".yellow

            mx = LCoreMenuItemsNX1.new()

            puts ""

            mx.item("access".yellow, lambda { 
                FileSystemAdapter::access(quark["uuid"])
            })

            mx.item("update/set description".yellow, lambda {
                description = Utils::editTextSynchronously(quark["description"])
                return if description == ""
                raise "not implemented yet"
            })

            mx.item("attach".yellow, lambda { 

            })

            mx.item("detach".yellow, lambda {

            })

            mx.item("transmute".yellow, lambda { 
                FileSystemAdapter::transmute(quark["uuid"])
            })

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(quark)
                LucilleCore::pressEnterToContinue()
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    Quarks::destroyQuark(quark["uuid"])
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # --------------------------------------------------------------------

    # Quarks::nx19s()
    def self.nx19s()
        Quarks::getQuarks()
            .map{|quark|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{Quarks::toString(quark)}",
                    "nx15"     => {
                        "type"    => "neiredQuark",
                        "payload" => quark
                    }
                }
            }
    end
end

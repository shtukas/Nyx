
# encoding: UTF-8

class NxPods

    # NxPods::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Nyx/NxPods.sqlite3"
    end

    # NxPods::commitNxPodAttributesToDatabase(uuid, unixtime, description)
    def self.commitNxPodAttributesToDatabase(uuid, unixtime, description)
        db = SQLite3::Database.new(NxPods::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _datacarrier_ where _uuid_=?", [uuid]
        db.execute "insert into _datacarrier_ (_uuid_, _unixtime_, _description_) values (?,?,?)", [uuid, unixtime, description]
        db.commit 
        db.close
    end

    # NxPods::commitNxPodToDatabase(nxpod)
    def self.commitNxPodToDatabase(nxpod)
        NxPods::commitNxPodAttributesToDatabase(nxpod["uuid"], nxpod["unixtime"], nxpod["description"])
    end

    # NxPods::getNxPods()
    def self.getNxPods()
        db = SQLite3::Database.new(NxPods::databaseFilepath())
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

    # NxPods::getNxPodOrNull(uuid)
    def self.getNxPodOrNull(uuid)
        db = SQLite3::Database.new(NxPods::databaseFilepath())
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

    # NxPods::destroyNxPod(uuid)
    def self.destroyNxPod(uuid)
        FileSystemAdapter::destroyNxPodOnDisk(uuid)

        puts "Destroy database record for nxpod uuid '#{uuid}'"

        db = SQLite3::Database.new(NxPods::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _datacarrier_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end

    # --------------------------------------------------------------------

    # NxPods::toString(nxpod)
    def self.toString(nxpod)
        map = {
            "Line" => "lne",
            "Url"  => "url",
            "Text" => "txt",
            "UniqueFileClickable" => "clk",
            "FSLocation" => "loc",
            "FSUniqueString" => "ust"
        }
        "[#{map[FileSystemAdapter::getNxPodType(nxpod["uuid"])]}] #{nxpod["description"]}"
    end

    # NxPods::interactivelyIssueNewNxPodOrNull()
    def self.interactivelyIssueNewNxPodOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Line" | "Url" | "Text" | "UniqueFileClickable" | "FSLocation" | "FSUniqueString"])
        return nil if type.nil?
        if type == "Line" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return nil if description == ""
            payload = ""
            NxPods::commitNxPodAttributesToDatabase(uuid, unixtime, description)
            FileSystemAdapter::makeNewNxPod(uuid, description, "Line", description)
            return NxPods::getNxPodOrNull(uuid)
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
            NxPods::commitNxPodAttributesToDatabase(uuid, unixtime, description)
            FileSystemAdapter::makeNewNxPod(uuid, description, "Url", url)
            return NxPods::getNxPodOrNull(uuid)
        end
        if type == "Text" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            text = Utils::editTextSynchronously("")
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
            NxPods::commitNxPodAttributesToDatabase(uuid, unixtime, description)
            FileSystemAdapter::makeNewNxPod(uuid, description, "Text", text)
            return NxPods::getNxPodOrNull(uuid)
        end
        if type == "UniqueFileClickable" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i

            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            filepath = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            return nil if !File.exists?(filepath)

            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""

            NxPods::commitNxPodAttributesToDatabase(uuid, unixtime, description)
            FileSystemAdapter::makeNewNxPod(uuid, description, "UniqueFileClickable", filepath)
            return NxPods::getNxPodOrNull(uuid)
        end
        if type == "FSLocation" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i

            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            return nil if !File.exists?(location)

            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""

            NxPods::commitNxPodAttributesToDatabase(uuid, unixtime, description)
            FileSystemAdapter::makeNewNxPod(uuid, description, "FSLocation", location)
            return NxPods::getNxPodOrNull(uuid)
        end
        if type == "FSUniqueString" then
            raise "FSUniqueString not implemented yet"
        end
        nil
    end

    # NxPods::accessEdit(nxpod)
    def self.accessEdit(nxpod)
        type = FileSystemAdapter::getNxPodType(nxpod["uuid"])

        nxpodFolderPath = FileSystemAdapter::getNxPodFolderpathByUUID(nxpod["uuid"])

        if type == "Line" then
            puts "line: #{NxPods::toString(nxpod)}"
            if LucilleCore::askQuestionAnswerAsBoolean("edit ? : ", false) then

                # Update Description
                description = Utils::editTextSynchronously(nxpod["description"])
                return if description == ""
                nxpod["description"] = description
                NxPods::commitNxPodToDatabase(nxpod)
                File.open("#{nxpodFolderPath}/description.txt", "w") {|f| f.write(description)}

                # Update Manifest
                File.open("#{nxpodFolderPath}/manifest.txt", "w") {|f| f.write(description)}
            end
        end

        if type == "Url" then
            puts "descrition: #{NxPods::toString(nxpod)}"
            puts "url: #{IO.read("#{nxpodFolderPath}/manifest.txt")}"
            system("open '#{IO.read("#{nxpodFolderPath}/manifest.txt")}'")
            if LucilleCore::askQuestionAnswerAsBoolean("edit ? : ", false) then

                # Update Description
                description = Utils::editTextSynchronously(nxpod["description"])
                return if description == ""
                nxpod["description"] = description
                NxPods::commitNxPodToDatabase(nxpod)
                File.open("#{nxpodFolderPath}/description.txt", "w") {|f| f.write(description)}

                # Update Manifest
                url = Utils::editTextSynchronously(IO.read("#{nxpodFolderPath}/manifest.txt"))
                File.open("#{nyxNxPodFolderpath}/manifest.txt", "w") {|f| f.write(url)}
            end
        end

        if type == "Text" then
            system("open '#{nxpodFolderPath}/#{IO.read("#{nxpodFolderPath}/manifest.txt")}'")
            if LucilleCore::askQuestionAnswerAsBoolean("edit description ? : ", false) then

                # Update Description
                description = Utils::editTextSynchronously(nxpod["description"])
                return if description == ""
                nxpod["description"] = description
                NxPods::commitNxPodToDatabase(nxpod)
                File.open("#{nxpodFolderPath}/description.txt", "w") {|f| f.write(description)}
            end
        end

        if type == "UniqueFileClickable" then
            system("open '#{nxpodFolderPath}/#{IO.read("#{nxpodFolderPath}/manifest.txt")}'")
            if LucilleCore::askQuestionAnswerAsBoolean("edit description ? : ", false) then

                # Update Description
                description = Utils::editTextSynchronously(nxpod["description"])
                return if description == ""
                nxpod["description"] = description
                NxPods::commitNxPodToDatabase(nxpod)
                File.open("#{nxpodFolderPath}/description.txt", "w") {|f| f.write(description)}
            end
            if LucilleCore::askQuestionAnswerAsBoolean("edit file ? : ", false) then
                system("open '#{nxpodFolderPath}'")
            end
        end

        if type == "FSLocation" then
            puts "FSLocation: #{NxPods::toString(nxpod)}"
            system("open '#{nxpodFolderPath}/#{IO.read("#{nxpodFolderPath}/manifest.txt")}'")
            if LucilleCore::askQuestionAnswerAsBoolean("edit (description) ? : ", false) then

                # Update Description
                description = Utils::editTextSynchronously(nxpod["description"])
                return if description == ""
                nxpod["description"] = description
                NxPods::commitNxPodToDatabase(nxpod)
                File.open("#{nxpodFolderPath}/description.txt", "w") {|f| f.write(description)}
            end
        end

        if type == "FSUniqueString" then
            puts "FSUniqueString: #{NxPods::toString(nxpod)}"
            location = `atlas locate '#{IO.read("#{nxpodFolderPath}/manifest.txt")}'`
            if location.size > 0 then
                puts location
                LucilleCore::pressEnterToContinue()
            end
            if LucilleCore::askQuestionAnswerAsBoolean("edit ? : ", false) then

                # Update Description
                description = Utils::editTextSynchronously(nxpod["description"])
                return if description == ""
                nxpod["description"] = description
                NxPods::commitNxPodToDatabase(nxpod)
                File.open("#{nxpodFolderPath}/description.txt", "w") {|f| f.write(description)}

                # Update Manifest
                uniquestring = Utils::editTextSynchronously(IO.read("#{nxpodFolderPath}/manifest.txt"))
                File.open("#{nyxNxPodFolderpath}/manifest.txt", "w") {|f| f.write(uniquestring)}
            end
        end
    end

    # NxPods::landing(nxpod)
    def self.landing(nxpod)

        loop {

            nxpod = NxPods::getNxPodOrNull(nxpod["uuid"]) # could have been deleted or transmuted in the previous loop
            return if nxpod.nil?

            puts "-- NxPod -----------------------------"

            puts NxPods::toString(nxpod).green

            puts "uuid: #{nxpod["uuid"]}".yellow
            puts ""

            mx = LCoreMenuItemsNX1.new()

            mx.item("access (edit)".yellow, lambda {
                NxPods::accessEdit(nxpod)
            })

            mx.item("update/set description".yellow, lambda {
                description = Utils::editTextSynchronously(nxpod["description"])
                return if description == ""
                nxpod["description"] = description
                NxPods::commitNxPodToDatabase(nxpod)
            })

            mx.item("attach".yellow, lambda { 
                value = Tags::architectureTagOrNull()
                return if value.nil?
                Tags::commitRecord(SecureRandom.hex, nxpod["uuid"], value)
            })

            mx.item("detach".yellow, lambda {
                values = Tags::pointUUIDToTags(nxpod["uuid"])
                value = LucilleCore::selectEntityFromListOfEntitiesOrNull("classification value", values)
                return if value.nil?
                Tags::deleteRecordsByPointUUIDAndTag(nxpod["uuid"], value)
            })

            mx.item("transmute".yellow, lambda { 
                FileSystemAdapter::transmute(nxpod["uuid"])
            })

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(nxpod)
                LucilleCore::pressEnterToContinue()
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    NxPods::destroyNxPod(nxpod["uuid"])
                end
            })

            puts ""

            Tags::pointUUIDToTags(nxpod["uuid"]).each{|tag|
                mx.item("[*] #{tag}", lambda { 
                    Tags::landing(tag)
                })
            }

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # --------------------------------------------------------------------

    # NxPods::sx19s()
    def self.sx19s()
        NxPods::getNxPods()
            .map{|nxpod|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{NxPods::toString(nxpod)}",
                    "sx15"     => {
                        "type"    => "nxpod",
                        "payload" => nxpod
                    }
                }
            }
    end
end

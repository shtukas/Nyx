
# encoding: UTF-8

# create table _directories_ (_directoryId_ text);

=begin

NxDirectory2 {
    "uuid"        : String
    "entityType"  : "NxDirectory2"
    "datetime"    : DateTime Iso 8601 UTC Zulu

    "description"   : String
    "locationnames" : Array[String]
}

NxDirectoryElement
{
    "uuid"        : String
    "entityType"  : "NxDirectoryElement"
    "datetime"    : DateTime Iso 8601 UTC Zulu
    "parentuuid"  : String # uuid of the parent directory
    "filename"    : String
    "description" : String
}

=end

class NxDirectoryElement
    # NxDirectoryElement::landing(element)
    def self.landing(element)
        parent = NxDirectory2::getNxDirectory2ByIdOrNull(element["parentuuid"])
        if parent.nil? then
            puts "Attempting to display NxDirectoryElement #{element}, could not find parent directory (uuid: #{uuid})"
            LucilleCore::pressEnterToContinue()
            return
        end
        location = Utils::locationByUniqueStringOrNull(element["parentuuid"])
        if location.nil? then
            puts "How did you manage to find parent #{parent}, but not its location? 🤔"
            LucilleCore::pressEnterToContinue()
            return
        end
        elementlocation = "#{location}/#{element["filename"]}"
        if !File.exists?(elementlocation) then
            puts "Element location was determined to be (#{elementlocation}) but we could not find it on disk"
            LucilleCore::pressEnterToContinue()
            return 
        end
        puts "accessing: #{elementlocation}"
        LucilleCore::pressEnterToContinue()
        system("open '#{elementlocation}'")
    end
end

class NxDirectory2

    # NxDirectory2::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/nx-directories-v2.sqlite3"
    end

    # NxDirectory2::register(directoryId)
    def self.register(directoryId)
        db = SQLite3::Database.new(NxDirectory2::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _directories_ (_directoryId_) values (?)", [directoryId]
        db.close
    end

    # NxDirectory2::delete(directoryId)
    def self.delete(directoryId)
        db = SQLite3::Database.new(NxDirectory2::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _directories_ where _directoryId_=?", [directoryId]
        db.close
    end

    # NxDirectory2::directoryIdToNxDirectory2OrNull(directoryId)
    def self.directoryIdToNxDirectory2OrNull(directoryId)
        location = Utils::locationByUniqueStringOrNull(directoryId)
        if location.nil? then
            puts "the directory #{directoryId} cannot be found in Galaxy, let's get rid of the record in Nyx"
            LucilleCore::pressEnterToContinue()
            NxDirectory2::delete(directoryId)
            return nil
        end
        description = File.basename(location)
        elements = Dir.entries(location).select{|filename| filename[0, 1] != "." }
        {
            "uuid"        => directoryId,
            "entityType"  => "NxDirectory2",
            "datetime"    => Time.new.utc.iso8601,
            "description"   => description,
            "locationnames" => elements
        }
    end

    # NxDirectory2::directories(): Array[NxDirectory2]
    def self.directories()
        db = SQLite3::Database.new(NxDirectory2::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        directoryIds = []
        db.execute( "select * from _directories_" , [] ) do |row|
            directoryIds << row["_directoryId_"]
        end
        db.close
        directoryIds.map{|id| NxDirectory2::directoryIdToNxDirectory2OrNull(id) }.compact
    end

    # NxDirectory2::getNxDirectory2ByIdOrNull(id): null or NxDirectory2
    def self.getNxDirectory2ByIdOrNull(id)
        db = SQLite3::Database.new(NxDirectory2::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        directoryId = nil
        db.execute( "select * from _directories_" , [] ) do |row|
            directoryId = row["_directoryId_"]
        end
        db.close
        return nil if directoryId.nil?
        NxDirectory2::directoryIdToNxDirectory2OrNull(directoryId)
    end

    # NxDirectory2::interactivelyRegisterNewNxDirectoryOrNull()
    def self.interactivelyRegisterNewNxDirectoryOrNull()
        directoryId = LucilleCore::askQuestionAnswerAsString("directoryId (empty to abort): ")
        return nil if directoryId == ""
        NxDirectory2::register(directoryId)
        NxDirectory2::getNxDirectory2ByIdOrNull(directoryId)
    end

    # ----------------------------------------------------------------------

    # NxDirectory2::toString(object)
    def self.toString(object)
        "[Directory2] #{object["description"]}"
    end

    # NxDirectory2::selectOneNxDirectory2OrNull()
    def self.selectOneNxDirectory2OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxDirectory2::directories(), lambda{|obj| obj["description"] })
    end

    # NxDirectory2::landing(directory)
    def self.landing(directory)
        loop {
            directory = NxDirectory2::getNxDirectory2ByIdOrNull(directory["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if directory.nil?
            system("clear")

            puts NxDirectory2::toString(directory).gsub("[smart directory]", "[smrd]").green

            puts "uuid: #{directory["uuid"]}"
            puts "directory: #{directory["location"]}"

            puts ""

            connected = []

            Links::entities(directory["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| 
                    connected << entity
                    puts "[#{indx}] [linked] #{NxEntity::toString(entity)}"
                }

            puts ""

            puts "access | connect | disconnect | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = connected[indx]
                next if entity.nil?
                NxEntity::landing(entity)
            end

            if Interpreting::match("access", command) then
                folderpath = Utils::locationByUniqueStringOrNull(directory["uuid"])
                if folderpath then
                    system("open '#{folderpath}'")
                else
                    puts "Interestingly I could not find the location for directory #{directory}"
                    LucilleCore::pressEnterToContinue()
                end
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(directory)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(directory)
            end

            if Interpreting::match("destroy", command) then
                NxDirectory2::delete(directory["uuid"])
            end
        }
    end

    # NxDirectory2::nx19s()
    def self.nx19s()
        NxDirectory2::directories()
            .map{|directory|
                volatileuuid = SecureRandom.hex[0, 8]
                nx19 = {
                    "announce" => "#{volatileuuid} #{NxDirectory2::toString(directory)}",
                    "type"     => "NxDirectory2",
                    "payload"  => directory
                }

                [nx19] + directory["locationnames"].map{|element|
                    directoryElement = {
                        "uuid"        => SecureRandom.hex,
                        "entityType"  => "NxDirectoryElement",
                        "datetime"    => Time.new.utc.iso8601,
                        "parentuuid"  => directory["uuid"],
                        "filename"    => element,
                        "description" => element
                    }
                    volatileuuid = SecureRandom.hex[0, 8]
                    {
                        "announce" => "#{volatileuuid} #{NxDirectory2::toString(directory)} / #{directoryElement["description"]}",
                        "type"     => "NxDirectoryElement",
                        "payload"  => directoryElement
                    }
                }
            }
            .flatten
    end
end

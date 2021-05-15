
# encoding: UTF-8

class NxSD1Element

    # CREATE TABLE _elements_ (_parentId_ text, _locationName_ text, _description_ text, _importId_ text);

    # NxSD1Element::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/NxSD1Element.sqlite3"
    end

    # NxSD1Element::register(parentId, locationName, description, importId)
    def self.register(parentId, locationName, description, importId)
        db = SQLite3::Database.new(NxSD1Element::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _elements_ (_parentId_, _locationName_, _description_, _importId_) values (?, ?, ?, ?)", [parentId, locationName, description, importId]
        db.close
    end

    # NxSD1Element::destroyRecordsByImportId(importId)
    def self.destroyRecordsByImportId(importId)
        db = SQLite3::Database.new(NxSD1Element::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _elements_ where _importId_!=?", [importId]
        db.close
    end

    # NxSD1Element::nxSmartDirectory1ToNxSD1ElementsFromCache(nxSmartDirectory1): Array[NxSD1Element]
    def self.nxSmartDirectory1ToNxSD1ElementsFromCache(nxSmartDirectory1)
        db = SQLite3::Database.new(NxSD1Element::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _elements_ where _parentId_=?" , [nxSmartDirectory1["uuid"]] ) do |row|
            answer << {
                "entityType"    => "NxSD1Element",
                "parentId"      => row["_parentId_"],
                "locationName"  => row["_locationName_"],
                "description"   => row["_description_"]
            }
        end
        db.close
        answer
    end

    # NxSD1Element::nxSmartDirectory1ToNxSD1ElementsFromDisk(nxSmartDirectory1): Array[NxSD1Element]
    def self.nxSmartDirectory1ToNxSD1ElementsFromDisk(nxSmartDirectory1)
        folderpath = NxSmartDirectory1::getDirectoryFolderpathOrNull(nxSmartDirectory1["uuid"])
        return [] if folderpath.nil?
        locationToNxSD1ElementOrNull = lambda{|location|
            return nil if File.basename(location).start_with?('.')
            basename = File.basename(location)
            {
                "entityType"       => "NxSD1Element",
                "parentId"         => nxSmartDirectory1["uuid"],
                "locationName"     => basename,
                "description"      => basename
            }
        }
        LucilleCore::locationsAtFolder(folderpath)
            .map{|location| locationToNxSD1ElementOrNull.call(location)}
            .compact
    end

    # ------------------------------------------------------

    # NxSD1Element::toString(element)
    def self.toString(element)
        "[smart/e] #{element["locationName"]}"
    end

    # NxSD1Element::nx19s(nxSmartDirectory1)
    def self.nx19s(nxSmartDirectory1)
        NxSD1Element::nxSmartDirectory1ToNxSD1ElementsFromCache(nxSmartDirectory1).map{|element|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxSD1Element::toString(element)}",
                "type"     => "NxSD1Element",
                "payload"  => element
            }
        }
    end

    # NxSD1Element::getLocationForNxSD1ElementOrNull(element)
    def self.getLocationForNxSD1ElementOrNull(element)
        parentDirectory = NxSmartDirectory1::getDirectoryFolderpathOrNull(element["parentId"])
        return nil if parentDirectory.nil?
        "#{parentDirectory}/#{element["locationName"]}"
    end

    # NxSD1Element::landing(element)
    def self.landing(element)
        location = NxSD1Element::getLocationForNxSD1ElementOrNull(element)
        if location.nil? then
            puts "Interesting, I could not land on"
            puts JSON.pretty_generate(element)
            LucilleCore::pressEnterToContinue()
        end
        puts "opening: #{location}"
        if File.directory?(location) then
            system("open '#{location}'")
        end
        if File.file?(location) then
            if Utils::fileByFilenameIsSafelyOpenable(File.basename(location)) then
                system("open '#{location}'")
            else
                system("open '#{File.dirname(location)}'")
            end
        end
        LucilleCore::pressEnterToContinue()
    end

end

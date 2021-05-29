
# encoding: UTF-8

class NxFSPermaPoint

    # NxFSPermaPoint::getAll()
    def self.getAll()
        BTreeSets::values(nil, "c68f25ea-f1e5-4724-9e62-27e9cc925536")
    end

    # NxFSPermaPoint::commit(point)
    def self.commit(point)
        BTreeSets::set(nil, "c68f25ea-f1e5-4724-9e62-27e9cc925536", point["uuid"], point)
    end

    # NxFSPermaPoint::getOneByIdOrNull(uuid)
    def self.getOneByIdOrNull(uuid)
        BTreeSets::getOrNull(nil, "c68f25ea-f1e5-4724-9e62-27e9cc925536", uuid)
    end

    # NxFSPermaPoint::issueNewNxFSPermaPoint(location)
    def self.issueNewNxFSPermaPoint(location)
        type = File.directory?(location) ? "directory" : "file"

        point = {}
        point["uuid"]        = SecureRandom.uuid
        point["description"] = File.basename(location)
        point["type"]        = type

        if type == "directory" then
            point["location"] = location
            uuidfile = "#{location}/.NxSD1-3945d937"
            if File.exists?(uuidfile) then
                point["mark"] = IO.read(uuidfile).strip
            else
                mark = SecureRandom.hex
                File.open(uuidfile, "w"){|f| f.write(mark) }
                point["mark"] = mark
            end
        end

        if type == "file" then
            point["location"] = location
            point["inode"]    = File.stat(location).ino
            point["sha256"]   = Digest::SHA256.file(location).hexdigest
        end

        NxFSPermaPoint::commit(point)

        point
    end

    # NxFSPermaPoint::updatePointToBeFullyConformingNoCommit(point)
    def self.updatePointToBeFullyConformingNoCommit(point)
        location = point["location"]
        if point["type"] == "directory" then
            point["description"] = File.basename(location)
            uuidfile = "#{location}/.NxSD1-3945d937"
            if File.exists?(uuidfile) then
                point["mark"] = IO.read(uuidfile).strip
            else
                mark = SecureRandom.hex
                File.open(uuidfile, "w"){|f| f.write(mark) }
                point["mark"] = mark
            end
            return point
        end
        if point["type"] == "file" then
            point["description"] = File.basename(location)
            point["inode"] = File.stat(location).ino
            point["sha256"] = Digest::SHA256.file(location).hexdigest
            return point
        end
        raise "d3a66dc4-0d1a-4d5a-8772-248f2d7f933a: #{point}"
    end

    # NxFSPermaPoint::locationToExistingPossiblyUpdatedNxFSPermaPointIfAnyOrNull(location)
    def self.locationToExistingPossiblyUpdatedNxFSPermaPointIfAnyOrNull(location)
        NxFSPermaPoint::getAll().select{|point| point["location"] == location }.first
    end

    # NxFSPermaPoint::locationToNxFSPermaPoint(location)
    def self.locationToNxFSPermaPoint(location)
        point = NxFSPermaPoint::locationToExistingPossiblyUpdatedNxFSPermaPointIfAnyOrNull(location)
        if point then
            point = NxFSPermaPoint::updatePointToBeFullyConformingNoCommit(point)
            NxFSPermaPoint::commit(point)
            return point
        end
        NxFSPermaPoint::issueNewNxFSPermaPoint(location)
    end

    # ---------------------------------------------------------

    # NxFSPermaPoint::toString(point)
    def self.toString(point)
        "[poin] #{point["description"]}"
    end

    # NxFSPermaPoint::landing(point)
    def self.landing(point)
        location = point["location"]
        if location.nil? then
            puts "Interesting, I could not land on"
            puts JSON.pretty_generate(point)
            LucilleCore::pressEnterToContinue()
            return
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

    # NxFSPermaPoint::nx19s()
    def self.nx19s()
        NxFSPermaPoint::getAll().map{|point|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxFSPermaPoint::toString(point)}",
                "type"     => "NxFSPermaPoint",
                "payload"  => point
            }
        }
    end

    # NxFSPermaPoint::garbageCollection()
    def self.garbageCollection()

    end
end


# encoding: UTF-8

class NxNav

    def initialize(id)
        raise "ad61cae2-7e41-4b99-a792-767d14b31a7a ; #{id}" if !Space::idIsUsed(id)
        @id = id
    end

    # -- Nx Common --------------------------------------------------------

    def id()
        @id
    end

    def folderpath()
        "#{Space::spaceFolderPath()}/#{@id}"
    end

    def unixtime()
        IO.read("#{folderpath()}/unixtime.txt").strip.to_i
    end

    def description()
        IO.read("#{folderpath()}/description.txt").strip
    end

    def toString()
        "[   ] #{description()}"
    end

    def nxType()
        "NxNav"
    end

    def isStillAlive()
        Space::idIsUsed(id)
    end

    def getConnectedIds()
        filepath = "#{folderpath()}/links.json"
        return [] if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    def addConnectedId(id)
        ids = (getConnectedIds() + [id]).uniq.sort
        File.open("#{folderpath()}/links.json", "w"){|f| f.puts(JSON.pretty_generate(ids)) }
    end

    def removeConnectedId(id)
        ids = getConnectedIds() - [id]
        File.open("#{folderpath()}/links.json", "w"){|f| f.puts(JSON.pretty_generate(ids)) }
    end

    # -- NxNav --------------------------------------------------------

end

class NxNavs

    # NxNavs::getNxNavs()
    def self.getNxNavs()
        Space::nxNavIds().map{|id| NxNav.new(id)}
    end

    # NxNavs::getNxNavOrNull(id)
    def self.getNxNavOrNull(id)
        raise "9547b485-809c-4905-b5a9-d72c57b4ae11 ; #{id}" if id[-2, 2] != "02"
        return nil if !Space::idIsUsed(id)
        NxNav.new(id)
    end

    # NxNavs::commitAttributeFileContentAtFolder(id, filename, data)
    def self.commitAttributeFileContentAtFolder(id, filename, data)
        folderpath = "#{Space::spaceFolderPath()}/#{id}"
        raise "722a6ff4-17fb-4999-a7d7-74f6a5674d98 ; #{id}" if !File.exists?(folderpath)
        filepath = "#{folderpath}/#{filename}"
        File.open(filepath, "w"){|f| f.write(data) }
    end

    # --------------------------------------------------------------------

    # NxNavs::interactivelyIssueNewNxNavOrNull()
    def self.interactivelyIssueNewNxNavOrNull()
        id = Space::issueNewId("NxNav")

        FileUtils.mkdir("#{Space::spaceFolderPath()}/#{id}")

        NxNavs::commitAttributeFileContentAtFolder(id, "uuid.txt", id)
        NxNavs::commitAttributeFileContentAtFolder(id, "unixtime.txt", Time.new.to_i)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        if description == "" then
            Space::destroyFolderIfExists(id)
            return nil
        end
        NxPods::commitAttributeFileContentAtFolder(id, "description.txt", description)

        NxNav.new(id)
    end

    # --------------------------------------------------------------------

    # NxNavs::mx19s()
    def self.mx19s()
        NxNavs::getNxNavs()
            .map{|nxnav|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{nxnav.toString()}",
                    "nxpoint"  => nxnav
                }
            }
    end

    # --------------------------------------------------------------------

    # NxNavs::fsckNxNav(id)
    def self.fsckNxNav(id)
        raise "2b7a27bb-798b-4882-ba43-43c0d017148d ; #{id}" if id[-2, 2] != "02"
        folderpath = "#{Space::spaceFolderPath()}/#{id}"
        if !File.exists?(folderpath) then
            raise "fsck fail: did not find nxnav folderpath for id: #{id}"
        end
        if !File.exists?("#{folderpath}/uuid.txt") then
            raise "fsck fail: did not find file uuid.txt for id: #{id}"
        end
        if id != IO.read("#{folderpath}/uuid.txt").strip then
            raise "fsck fail: did not validate uuid in uuid.txt for id: #{id}"
        end
        if !File.exists?("#{folderpath}/description.txt") then
            raise "fsck fail: did not find file description.txt for id: #{id}"
        end
    end
end

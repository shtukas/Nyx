
# encoding: UTF-8

class Space

    # -------------------------------------------------------
    # Config

    # Space::spaceFolderPath()
    def self.spaceFolderPath()
        "/Users/pascal/Galaxy/Documents/NyxSpace"
    end

    # -------------------------------------------------------
    # Ids
    # 024677747775-01

    # Space::nodeTypes()
    def self.nodeTypes()
        ["NxPod", "NxNav"] 
    end

    # Space::nodeTypeToIdSuffix(nodeType)
    def self.nodeTypeToIdSuffix(nodeType)
        raise "b19f0a91-7694-4744-96d8-2c771a684fb1" if !Space::nodeTypes()
        map = {
            "NxPod" => "01",
            "NxNav" => "02"
        }
        map[nodeType]
    end

    # Space::randomDigit()
    def self.randomDigit()
        (0..9).to_a.sample
    end

    # Space::randomPrimaryId()
    def self.randomPrimaryId()
        (1..12).map{|i| Space::randomDigit() }.join()
    end

    # Space::forgeNewId(nodeType)
    def self.forgeNewId(nodeType)
        raise "ed679236-713a-41e9-bed0-b19d4b65986d" if !Space::nodeTypes()
        "#{Space::randomPrimaryId()}-#{Space::nodeTypeToIdSuffix(nodeType)}"
    end

    # Space::existingIds()
    def self.existingIds()
        LucilleCore::locationsAtFolder(Space::spaceFolderPath())
            .map{|location| File.basename(location) }
    end

    # Space::idIsUsed(id)
    def self.idIsUsed(id)
        File.exists?("#{Space::spaceFolderPath()}/#{id}")
    end

    # Space::issueNewId(nodeType)
    def self.issueNewId(nodeType)
        raise "c20aa94c-6689-4a68-b5d3-20160a15b98e : #{nodeType}" if !Space::nodeTypes()
        # This function could possibly not terminate
        # But if it doesn't, we have a much bigger problem anyway 
        loop {
            id = Space::forgeNewId(nodeType)
            next if Space::idIsUsed(id)
            return id
        }
    end

    # -------------------------------------------------------
    # Space Probe

    # Space::idToNxPointOrNull(id)
    def self.idToNxPointOrNull(id)
        if id[-2, 2] == "01" then
            return NxPods::getNxPodOrNull(id)
        end
        if id[-2, 2] == "02" then
            return NxNavs::getNxNavOrNull(id)
        end
        raise "0141b15c-4c00-4102-9c36-81cbaae47b2c ; #{id}"
    end

    # Space::nxFolderpaths()
    def self.nxFolderpaths()
        LucilleCore::locationsAtFolder(Space::spaceFolderPath())
    end

    # Space::nxPodsFolderpaths()
    def self.nxPodsFolderpaths()
        Space::nxFolderpaths().select{|folderpath|
            folderpath[-2, 2] == "01"
        }
    end

    # Space::nxNavsFolderpaths()
    def self.nxNavsFolderpaths()
        Space::nxFolderpaths().select{|folderpath|
            folderpath[-2, 2] == "02"
        }
    end

    # Space::nxIds()
    def self.nxIds()
        Space::nxFolderpaths().map{|folderpath| File.basename(folderpath) }
    end

    # Space::nxPodIds()
    def self.nxPodIds()
        Space::nxPodsFolderpaths().map{|folderpath| File.basename(folderpath) }
    end

    # Space::nxNavIds()
    def self.nxNavIds()
        Space::nxNavsFolderpaths().map{|folderpath| File.basename(folderpath) }
    end

    # Space::destroyFolderIfExists(id)
    def self.destroyFolderIfExists(id)
        location = "#{pace::spaceFolderPath()}/#{id}"
        return if !File.exists?(location)
        LucilleCore::removeFileSystemLocation(location)
    end


    # Search

    # Space::selectOneMx19OrNull()
    def self.selectOneMx19OrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(Space::mx19s(), lambda{|item| item["announce"] })
    end

    # Space::mx19s()
    def self.mx19s()
        searchItems = [
            NxNavs::mx19s(),
            NxPods::mx19s(),
        ]
        .flatten
    end

    # Space::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            mx19 = Space::selectOneMx19OrNull()
            break if mx19.nil? 
            if mx19["mx15"]["type"] == "nxpod" then
                NxPods::landing(mx19["mx15"]["payload"])
            end
            if mx19["mx15"]["type"] == "nxnav" then
                NxNavs::landing(mx19["mx15"]["payload"])
            end
        }
    end
end

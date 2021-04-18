
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
    # Enumerations

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

    # Space::getNxPoints()
    def self.getNxPoints()
        Space::nxNavIds().map{|id| NxNav.new(id)} + Space::nxPodIds().map{|id| NxPod.new(id)}
    end

    # -------------------------------------------------------
    # NxPoints

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

    # Space::destroyFolderIfExists(id)
    def self.destroyFolderIfExists(id)
        location = "#{pace::spaceFolderPath()}/#{id}"
        return if !File.exists?(location)
        LucilleCore::removeFileSystemLocation(location)
    end

    # Space::link(id1, id2)
    def self.link(id1, id2)
        nxpoint1 = Space::idToNxPointOrNull(id1)
        return if nxpoint1.nil?
        nxpoint2 = Space::idToNxPointOrNull(id2)
        return if nxpoint2.nil?
        nxpoint1.addConnectedId(id2)
        nxpoint2.addConnectedId(id1)
    end

    # Space::unlink(id1, id2)
    def self.unlink(id1, id2)
        nxpoint1 = Space::idToNxPointOrNull(id1)
        return if nxpoint1.nil?
        nxpoint2 = Space::idToNxPointOrNull(id2)
        return if nxpoint2.nil?
        nxpoint1.removeConnectedId(id2)
        nxpoint2.removeConnectedId(id1)
    end

    # Space::landing(nxpoint)
    def self.landing(nxpoint)
        loop {
            system("clear")

            return if !nxpoint.isStillAlive()

            puts "-- #{nxpoint.nxType()} -----------------------------"

            puts "#{nxpoint.description().green}"
            puts "(id: #{nxpoint.id()}, datetime: #{Time.at(nxpoint.unixtime()).utc.iso8601})"
            puts ""

            mx = LCoreMenuItemsNX1.new()

            nxpoint.getConnectedIds().each{|id|
                nx = Space::idToNxPointOrNull(id)
                next if nx.nil?
                mx.item(nx.toString(), lambda { 
                    Space::landing(nx)
                })
            }

            puts ""

            if nxpoint.nxType() == "NxPod" then
                mx.item("access".yellow, lambda {
                    NxPods::access(nxpoint)
                })
                mx.item("edit".yellow, lambda {
                    NxPods::edit(nxpod)
                })
            end

            mx.item("update/set description".yellow, lambda {
                description = Utils::editTextSynchronously(nxpoint.description())
                return if description == ""
                NxPods::commitAttributeFileContentAtFolder(nxpoint.id(), "description.txt", description)
            })

            mx.item("edit datetime".yellow, lambda {
                datetime = Utils::editTextSynchronously(Time.at(nxpoint.unixtime()).utc.iso8601)
                return if !Utils::isDateTime_UTC_ISO8601(datetime)
                NxPods::commitAttributeFileContentAtFolder(nxpoint.id(), "unixtime.txt", DateTime.parse(datetime).to_time.to_i)
            })

            mx.item("attach".yellow, lambda { 
                target = Space::architectOneNxPointOrNull()
                return if target.nil?
                Space::link(target.id(), nxpoint.id())
            })

            mx.item("detach".yellow, lambda {
                ns = nxpoint.getConnectedIds().map{|idx| Space::idToNxPointOrNull(idx) }.compact
                n = LucilleCore::selectEntityFromListOfEntitiesOrNull("NxPoint", ns, lambda{|n| n.description() })
                return if n.nil?
                Space::unlink(nxpoint.id(), n.id())
            })

            mx.item("relocate (move a selection of connected points somewhere else)".yellow, lambda {
                puts "(1) target selection ; (2) moving points selection"
                target = Space::architectOneNxPointOrNull()
                return if target.nil?

                connected = nxpoint.getConnectedIds().map{|idx| Space::idToNxPointOrNull(idx) }.compact

                selected, unselected = LucilleCore::selectZeroOrMore("NxPoints", [], connected, lambda{|n| n.toString() })
                selected.each{|n|
                    puts "Connecting   : #{target.description()}, #{n.description()}"
                    Space::link(target.id(), n.id())
                    puts "Disconnecting: #{nxpoint.description()}, #{n.description()}"
                    Space::unlink(nxpoint.id(), n.id())
                }
            })

            if nxpoint.nxType() == "NxPod" then
                mx.item("transmute".yellow, lambda {
                    NxPods::transmute(nxpoint.id())
                })
            end


            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    NxPods::destroyNxPod(nxpoint.id())
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # -------------------------------------------------------
    # Search

    # Space::mx19s()
    def self.mx19s()
        searchItems = [
            NxNavs::mx19s(),
            NxPods::mx19s(),
        ]
        .flatten
    end

    # Space::selectOneMx19OrNull()
    def self.selectOneMx19OrNull()
        Utils::selectOneObjectOrNullUsingInteractiveInterface(Space::mx19s(), lambda{|item| item["announce"] })
    end

    # Space::selectOneNxPointOrNull()
    def self.selectOneNxPointOrNull()
        mx19 = Space::selectOneMx19OrNull()
        return if mx19.nil?
        mx19["nxpoint"]
    end

    # Space::interactivelyMakeNewNxPointOrNull()
    def self.interactivelyMakeNewNxPointOrNull()
        nxType = LucilleCore::selectEntityFromListOfEntitiesOrNull("NxType", ["NxPod", "NxNav"])
        return nil if nxType.nil?
        if nxType == "NxPod" then
            return NxPods::interactivelyIssueNewNxPodOrNull()
        end
        if nxType == "NxNav" then
            return NxNavs::interactivelyIssueNewNxNavOrNull()
        end
    end

    # Space::architectOneNxPointOrNull()
    def self.architectOneNxPointOrNull()
        nxpoint = Space::selectOneNxPointOrNull()
        return nxpoint if nxpoint
        Space::interactivelyMakeNewNxPointOrNull()
    end

    # Space::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            mx19 = Space::selectOneMx19OrNull()
            break if mx19.nil? 
            Space::landing(mx19["nxpoint"])
        }
    end
end


# encoding: UTF-8

class NxSmartDirectory

    # NxSmartDirectory::getUniqueStringOrNull(str)
    def self.getUniqueStringOrNull(str)
        # See NxSmartDirectory.txt for the assumptions we can work with
        return nil if !str.include?('[')
        return nil if !str.include?(']')
        while str.include?('[') do
            str = str[1, str.size]
        end
        str = str[0, str.size-1]
        str
    end

    # NxSmartDirectory::getDescriptionFromFilename(filename)
    def self.getDescriptionFromFilename(filename)
        filename
    end

    # NxSmartDirectory::getNxQuarkIdByUniqueStringOrNull(uniquestring)
    def self.getNxQuarkIdByUniqueStringOrNull(uniquestring)
        useTheForce = lambda{|uniquestring|
            NxQuarks::ids().each{|id|
                next if !["FSUniqueString", "NxSmartDirectory"].include?(NxQuarks::nxType(id))
                next if Marbles::get(NxQuarks::filepathOrNull(id), "uniquestring") != uniquestring
                return id
            }
            nil
        }
        id = KeyValueStore::getOrNull(nil, "453a81bf-b5e0-4cb2-9beb-8a11f74824e5:#{uniquestring}")
        return id if id
        id = useTheForce.call(uniquestring)
        return nil if id.nil?
        KeyValueStore::set(nil, "453a81bf-b5e0-4cb2-9beb-8a11f74824e5:#{uniquestring}", id)
        id
    end

    # NxSmartDirectory::trueIfBothIdsAreUniqueStringCarriersWithTheSameUniqueString(id1, id2)
    def self.trueIfBothIdsAreUniqueStringCarriersWithTheSameUniqueString(id1, id2)
        return false if !["FSUniqueString", "NxSmartDirectory"].include?(NxQuarks::nxType(id1))
        return false if !["FSUniqueString", "NxSmartDirectory"].include?(NxQuarks::nxType(id2))
        uniquestring1 = Marbles::get(NxQuarks::filepathOrNull(id1), "uniquestring")
        uniquestring2 = Marbles::get(NxQuarks::filepathOrNull(id2), "uniquestring")
        uniquestring1 == uniquestring2
    end

    # NxSmartDirectory::smartDirectorySync(id, filepath)
    def self.smartDirectorySync(id, filepath)

        # We start by checking that we can find the smart folder on disk.
        uniquestring = Marbles::get(filepath, "uniquestring")
        folderpath = Utils::locationByUniqueStringOrNull(uniquestring)
        if folderpath.nil? then
            puts "Could not determine location for NxSmartDirectory '#{NxQuarks::description(id)}' uniquestring: #{uniquestring}"
            LucilleCore::pressEnterToContinue()
            return
        end


        # We convert the arrow kids to unique strings kids with a presence on disk
        # Note that we ca manually, in Nyx, create (non unique string kids), but we can still transmute another quark type to NxSmartDirectory
        # Resulting in possibly non arrow kids of type FSUniqueString
        Arrows::childrenIds2(id).each{|idx|
            next if NxQuarks::nxType(idx) == "NxSmartDirectory"
            next if NxQuarks::nxType(idx) == "FSUniqueString"
            if NxQuarks::nxType(idx) == "Url" then
                uniquestring1 = Marbles::get(filepath, "uniquestring")
                folderpath1 = Utils::locationByUniqueStringOrNull(uniquestring1)
                if folderpath1.nil? then
                    puts "Could not determine location for NxSmartDirectory '#{NxQuarks::description(id)}' uniquestring: #{uniquestring1}"
                    LucilleCore::pressEnterToContinue()
                    return
                end
                filepathx = NxQuarks::filepathOrNull(idx)
                urlx = Marbles::get(filepathx, "url")
                uniquestring2 = SecureRandom.hex(6)
                filename2 = "URL [#{uniquestring2}].txt"
                filepath2 = "#{folderpath1}/#{filename2}"
                File.open(filepath2, "w"){|f| f.puts(urlx) }
                # We now need to transmute the child into FSUniqueString
                Marbles::set(filepathx, "nxType", "FSUniqueString")
                Marbles::set(filepathx, "uniquestring", uniquestring2)
                next
            end
            puts "I do not know how to run this export operation for type #{NxQuarks::nxType(idx)}"
            LucilleCore::pressEnterToContinue()
        }


        # We check that each fs child has a unique string in its filename
        status1 = LucilleCore::locationsAtFolder(folderpath).any?{|childlocation| NxSmartDirectory::getUniqueStringOrNull(File.basename(childlocation)).nil? }
        if status1 then
            puts "You have file system children of this smart folder which do not have a unique string, let me send you there..."
            LucilleCore::pressEnterToContinue()
            system("open '#{folderpath}'")
            return

        end
        
        # Now we need to make sure that each fs child is an arrow child
        LucilleCore::locationsAtFolder(folderpath).each{|childlocation| 
            childuniquestring = NxSmartDirectory::getUniqueStringOrNull(File.basename(childlocation))
            childid = NxSmartDirectory::getNxQuarkIdByUniqueStringOrNull(childuniquestring)
            next if (childid and Arrows::childrenIds2(id).include?(childid))
            # The childid is either null or the childid is not an arrow child
            if childid.nil? then
                childdescription = NxSmartDirectory::getDescriptionFromFilename(File.basename(childlocation))
                puts "childuniquestring: #{childuniquestring}"
                puts "I am about to make a new arrow child with description: #{childdescription}"
                LucilleCore::pressEnterToContinue()
                childid = NxQuarks::makeNewFSUniqueStringNxQuark(childdescription, childuniquestring)
            end
            Arrows::link(id, childid)
        }

        # Now we make sure that each arrow child is on disk, otherwise we remove it
        Arrows::childrenIds2(id).each{|idx|
            uniquestringx = Marbles::getOrNull(NxQuarks::filepathOrNull(idx), "uniquestring")
            next if uniquestringx.nil? # looks like we have a arrow kid that is not standard
            if !LucilleCore::locationsAtFolder(folderpath).map{|childlocation| NxSmartDirectory::getUniqueStringOrNull(File.basename(childlocation)) }.compact.include?(uniquestringx) then
                # We have an arrow kid carrying a unique string that is not in the folder. Kill it!
                puts "Destroying arrow child (no longer in folder): #{NxQuarks::description(idx)}"
                LucilleCore::pressEnterToContinue()
                NxQuarks::destroy(idx)
            end
        }

        # Now we make sure that we do not have duplicate arrow kids with the same unique string
        Arrows::childrenIds2(id).reduce([]){|selectedIds, cursorId|
            if selectedIds.any?{|id1| NxSmartDirectory::trueIfBothIdsAreUniqueStringCarriersWithTheSameUniqueString(id1, cursorId) } then
                puts "Destroying arrow child (duplicate unique string): #{NxQuarks::description(cursorId)}"
                LucilleCore::pressEnterToContinue()
                NxQuarks::destroy(cursorId)
            else
                selectedIds << cursorId
            end
            selectedIds
        }
    end
end

raise "138f15e4-b62d-01" if NxSmartDirectory::getUniqueStringOrNull("something [1234567]") != "1234567"
raise "138f15e4-b62d-02" if !NxSmartDirectory::getUniqueStringOrNull("something [1234567").nil?
raise "138f15e4-b62d-03" if NxSmartDirectory::getUniqueStringOrNull("[128] Many URLs [22b6aaf2f072]") != "22b6aaf2f072"



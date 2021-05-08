# encoding: UTF-8

class NxEntities

    # -------------------------------------------------------
    # Ids (eg: 024677747775-07)

    # NxEntities::randomDigit()
    def self.randomDigit()
        (0..9).to_a.sample
    end

    # NxEntities::randomId(length)
    def self.randomId(length)
        (1..length).map{|i| NxEntities::randomDigit() }.join()
    end

    # NxEntities::forgeNewId()
    def self.forgeNewId()
        raise "ed679236-713a-41e9-bed0-b19d4b65986d" if !NxQuarks::nxQuarkTypes()
        "#{NxEntities::randomId(12)}-#{NxEntities::randomId(2)}"
    end

    # NxEntities::ids()
    def self.ids()
        LucilleCore::locationsAtFolder(NxQuarks::nxQuarkFolderpath())
            .map{|location| File.basename(location) }
            .select{|s| s[-7, 7] == ".marble" }
            .map{|s| s[0, 15] }
    end

    # NxEntities::issueNewId()
    def self.issueNewId()
        loop {
            id = NxEntities::forgeNewId()
            next if NxQuarks::exists?(id)
            return id
        }
    end

end

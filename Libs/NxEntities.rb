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

    # NxEntities::getNxEntityByIdOrNull(id)
    def self.getNxEntityByIdOrNull(id)
        # We have two types of Entities: NxQuarks which are data carriers and NxListings
        # This function returns either 
        #    ["NxQuark", id]
        #    ["NxListing", id, Nx21]
        if File.exists?("#{NxQuarks::nxQuarkFolderpath()}/#{id}.marble") then
            return ["NxQuark", id]
        end
        nx21 = NxListings::getListingByIdOrNull(id)
        if nx21 then
            return ["NxListing", id, nx21]
        end
        nil
    end

    # NxEntities::idIsNxQuark(id)
    def self.idIsNxQuark(id)
        File.exists?("#{NxQuarks::nxQuarkFolderpath()}/#{id}.marble")
    end

    # NxEntities::idIsNxListing(id)
    def self.idIsNxListing(id)
        !NxListings::getListingByIdOrNull(id).nil?
    end

    # NxEntities::landing(id)
    def self.landing(id)
        if NxEntities::idIsNxQuark(id) then
            NxQuarks::landing(id)
            return
        end
        if NxEntities::idIsNxListing(id) then
            NxListings::landing(id)
            return
        end
    end

end

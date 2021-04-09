
# encoding: UTF-8

class Olivia

    # Olivia::interactivelyIssueNewElementOrNull()
    def self.interactivelyIssueNewElementOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Line" | "Url" | "Text" | "UniqueFileClickable" | "FSLocation" | "FSUniqueString"])
        return nil if type.nil?
        if type == "Line" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return nil if description == ""
            payload = ""
            NereidDatabaseDataCarriers::commitElementComponents(uuid, unixtime, description)
            FileSystemAdapter::makeNewElement(uuid, description, "Line", description)
            return NereidInterface::getElementOrNull(uuid)
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
            NereidDatabaseDataCarriers::commitElementComponents(uuid, unixtime, description)
            FileSystemAdapter::makeNewElement(uuid, description, "Url", url)
            return NereidInterface::getElementOrNull(uuid)
        end
        if type == "Text" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            text = Utils::editTextSynchronously("")
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
            NereidDatabaseDataCarriers::commitElementComponents(uuid, unixtime, description)
            FileSystemAdapter::makeNewElement(uuid, description, "Text", text)
            return NereidInterface::getElementOrNull(uuid)
        end
        if type == "UniqueFileClickable" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i

            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            filepath = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            return nil if !File.exists?(filepath)

            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""

            NereidDatabaseDataCarriers::commitElementComponents(uuid, unixtime, description)
            FileSystemAdapter::makeNewElement(uuid, description, "UniqueFileClickable", filepath)
            return NereidInterface::getElementOrNull(uuid)
        end
        if type == "FSLocation" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i

            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            return nil if !File.exists?(location)

            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""

            NereidDatabaseDataCarriers::commitElementComponents(uuid, unixtime, description)
            FileSystemAdapter::makeNewElement(uuid, description, "FSLocation", location)
            return NereidInterface::getElementOrNull(uuid)
        end
        if type == "FSUniqueString" then
            raise "FSUniqueString not implemented yet"
        end
        nil
    end

    # Olivia::destroyElement(uuid)
    def self.destroyElement(uuid)
        FileSystemAdapter::destroyElementOnDisk(uuid)
        NereidDatabaseDataCarriers::destroyElement(uuid)
    end

    # Olivia::nx19s()
    def self.nx19s()
        NereidInterface::getElements()
            .map{|element|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{NereidInterface::toString(element)}",
                    "nx15"     => {
                        "type"    => "neiredElement",
                        "payload" => element
                    }
                }
            }
    end

    # Olivia::landing(element)
    def self.landing(element)

        loop {

            puts "-- Olivia -----------------------------"

            element = NereidInterface::getElementOrNull(element["uuid"]) # could have been deleted or transmuted in the previous loop
            return if element.nil?

            puts "[nyx] #{NereidInterface::toString(element)}".green

            puts "uuid: #{element["uuid"]}".yellow
            puts "payload: #{element["payload"]}".yellow

            puts ""

            mx = LCoreMenuItemsNX1.new()

            puts ""

            mx.item("access".yellow, lambda { 
                FileSystemAdapter::access(element["uuid"])
            })

            mx.item("update/set description".yellow, lambda {
                description = Utils::editTextSynchronously(element["description"])
                return if description == ""
                raise "not implemented yet"
            })

            mx.item("attach".yellow, lambda { 

            })

            mx.item("detach".yellow, lambda {

            })

            mx.item("transmute".yellow, lambda { 
                FileSystemAdapter::transmute(element["uuid"])
            })

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(element)
                LucilleCore::pressEnterToContinue()
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy ? : ") then
                    Olivia::destroyElement(element["uuid"])
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

end

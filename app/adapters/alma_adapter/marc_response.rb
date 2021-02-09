class AlmaAdapter
  # Responsible for converting an Alma::BibSet to an array of unsuppressed MARC
  # records.
  class MarcResponse
    attr_reader :bibs
    # @param bibs [Alma::BibSet]
    def initialize(bibs:)
      @bibs = bibs
    end

    def unsuppressed_marc
      marc_records.reject(&:suppressed?)
    end

    class MarcRecord < SimpleDelegator
      attr_reader :bib, :marc_record
      # @param bib [Alma::Bib]
      # @param marc_record [MARC::Record]
      # @note We accept these two separately because parsing a bunch of MARC
      # records at once is more performant than doing one at a time, so it's
      # done before initializing this.
      def initialize(bib, marc_record)
        super(marc_record)
        @marc_record = marc_record
        @bib = bib
      end

      def suppressed?
        bib["suppress_from_publishing"] == "true"
      end

      def linked_record_ids
        linked_record_fields = marc_record.fields.select do |field|
          field.tag == "774"
        end
        linked_record_fields.map do |field|
          field["w"]
        end
      end

      def enrich_with_item(item)
        item = ::AlmaAdapter::AlmaItem.new(item)
        marc_record.append(item.enrichment_876)
      end

      # Remove source record 852s and 86Xs, to reduce confusion when holding
      # data is added.
      def delete_conflicting_holding_data!
        marc_record.fields.delete_if { |f| ['852', '866', '867', '868'].include? f.tag }
      end

      def enrich_with_holding(holding, recap: false)
        holding = ::AlmaAdapter::AlmaHolding.for(holding, recap: recap)
        marc_record.fields.concat(holding.marc_record_enrichment)
      end

      # Strips non-numeric tags for ReCAP, whose parser can't handle them.
      # Integer() is faster than to_i, per
      # https://stackoverflow.com/questions/5661466/test-if-string-is-a-number-in-ruby-on-rails
      def strip_non_numeric!
        marc_record.fields.delete_if do |field|
          Integer(field.tag)
          false
        rescue
          true
        end
      end
    end

    private

      def marc_records
        @marc_records ||=
          begin
            MARC::XMLReader.new(bib_marc_xml).to_a.each_with_index.map do |record, idx|
              MarcRecord.new(bibs[idx], record)
            end
          end
      end

      def bib_marc_xml
        StringIO.new(
          bibs.flat_map do |bib|
            bib["anies"]
          end.join("")
        )
      end
  end
end

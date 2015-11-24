require 'json'
require 'traject'

describe 'From traject_config.rb' do
  before(:all) do

    def fixture_record(fixture_name)
      f=File.expand_path("../../fixtures/#{fixture_name}.mrx",__FILE__)
      MARC::XMLReader.new(f).first
    end
    c=File.expand_path('../../../lib/traject_config.rb',__FILE__)
    @indexer = Traject::Indexer.new
    @indexer.load_config_file(c)
    @sample1=@indexer.map_record(fixture_record('sample1'))
    @sample2=@indexer.map_record(fixture_record('sample2'))
    @sample3=@indexer.map_record(fixture_record('sample3'))
    @related_names=@indexer.map_record(fixture_record('sample27'))
    @online_at_library=@indexer.map_record(fixture_record('sample29'))
    @online=@indexer.map_record(fixture_record('sample30'))
	end

  describe 'the id field' do
    it 'has exactly 1 value' do
      expect(@sample1['id'].length).to eq 1
    end
  end
  describe 'the title_sort field' do
    it 'does not have initial articles' do
      expect(@sample1['title_sort'][0].start_with?('advanced concepts')).to be_truthy
    end
  end
  describe 'the author_display field' do
    it 'takes from the 100 field' do
      expect(@sample1['author_display'][0]).to eq 'Singh, Digvijai, 1934-'
    end
    it 'shows only 100 field' do
      expect(@sample2['author_display'][0]).to eq 'White, Michael M.'
    end
    it 'shows 110 field' do
      expect(@sample3['author_display'][0]).to eq 'World Data Center A for Glaciology'
    end
  end
  describe 'the author_citation_display field' do
    it 'shows only the 100 a subfield' do
      expect(@sample1['author_citation_display'][0]).to eq 'Singh, Digvijai'
    end
    it 'shows only the 700 a subfield' do
      expect(@sample2['author_citation_display']).to include 'Jones, Mary'
    end
  end
  describe 'the pub_citation_display field' do
    it 'shows the the 260 a and b subfields' do
      expect(@sample2['pub_citation_display']).to include 'London: Firethorn Press'
    end
  end
  describe 'related_name_json_1display' do
    it 'trims punctuation the same way as author_s facet' do
      rel_names = JSON.parse(@related_names['related_name_json_1display'][0])
      rel_names['Related name'].each {|n| expect(@related_names['author_s']).to include(n)}
    end
  end
  describe 'access_facet' do
    it 'value is at the library for all non-online holding locations' do
      expect(@sample3['location_code_s'][0]).to eq 'scidoc' # Lewis Library
      expect(@sample3['access_facet']).to include 'At the Library'
      expect(@sample3['access_facet']).not_to include 'Online'
    end
    it 'value is online for elf holding locations' do
      expect(@online['location_code_s'][0]).to eq 'elf1'
      expect(@online['access_facet']).to include 'Online'
      expect(@online['access_facet']).not_to include 'At the Library'
    end
    it 'value can be both at the library and online when there are multiple holdings' do
      expect(@online_at_library['location_code_s']).to include 'elf1'
      expect(@online_at_library['location_code_s']).to include 'rcpph'
      expect(@online_at_library['access_facet']).to include 'Online'
      expect(@online_at_library['access_facet']).to include 'At the Library'
    end
  end
  describe 'holdings_1display' do
  end
end

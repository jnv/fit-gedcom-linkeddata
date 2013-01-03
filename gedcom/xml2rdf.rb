#!/usr/bin/env ruby

require 'linkeddata'
require 'rexml/document'
require 'active_support/all'
include RDF

BIO = Vocabulary.new('http://purl.org/vocab/bio/0.1/')
REL = Vocabulary.new('http://purl.org/vocab/relationship')

$individuals = {}
$families = {}

def clean_id(value)
  value.delete('@').strip
end
class Individual
  # type FOAF.Person
  # property :id, predicate: RDF.ID
  # property :name,  predicate: FOAF.name
  # property :givenname, predicate: FOAF.givenname
  # property :surname, predicate: FOAF.family_name
  # property :gender, predicate: FOAF.gender
  #property :death, type: Native, predicate: BIO.Event
  #include RDF::Enumerable
  attr_accessor :id, :name, :givennames, :surname, :gender, :family_ids, :families

  TYPE = FOAF.Person

  PROPERTIES = {
    id: RDF.ID,
    name: FOAF.name,
    surname: FOAF.familyName,
    gender: FOAF.gender
    #givennames, events
  }

  def self.from_xml(e)
    id = clean_id(e.attributes['id'])
    indi = self.new(id).tap do |i|
      i.name = e.elements['NAME'].text.strip
      i.givennames = e.elements.to_a('NAME/GIVN').map(&:text)
      i.surname = e.elements['NAME/SURN'].text.strip
      i.gender = case e.elements['SEX'].text.strip
      when 'M' then 'male'
      when 'F' then 'female'
      else 'unknown'
      end

      families = e.elements.to_a('FAMS')
      unless families.blank?
        i.family_ids = families.map(&:text).map {|fam| clean_id(fam)}
      end
      #deat = e.elements['DEAT']
      #i.death = Death.from_xml(deat) unless deat.nil?
    end
    indi
  end

  def initialize(id)
    @id = id
    @givennames = []
    @subject = RDF::Node(id)
  end

  def givennames=(names = [])
    @givennames = names.map(&:strip)
  end

  def name=(name)
    #also could be reconstructed from @givennames in getter...
    @name = name.delete('/')
  end

  def to_rdf
    # self #RDF::Enumerable
    repo = Repository.new
    repo << [@subject, RDF.type, TYPE]
    PROPERTIES.each do |prop, predicate|
      value = self.send(prop)
      repo.insert(Statement.new(@subject, predicate, value))
    end
    @givennames.each do |value|
      repo << [@subject, FOAF.givenName, value]
    end
    repo
  end

  # def each(*args, &block)
  # end

end

class Family
  # has_many :individuals, predicate: FOAF.Member
  def initialize(id)
    @id = id
    @subject = RDF::Node(id)
    @members = []
  end

  def add_member(member)
    @members << member
  end

  def each(*args, &block)
    #XXX support RDF::Enumerable
  end
end

class Groups
  def initialize
    @collection = {}
  end

  def add_individual(indi)
    indi.family_ids.each do |fam_id|
      family = add_family(fam_id)
      family.add_member(indi)
    end
  end

  def add_family(id)
    family = @collection.fetch(id, Family.new(id))
    @collection[id] = family unless @collection.key?(id)
    family
  end
end

# Raw XML processing & Graph
input = File.new('sample.xml')
doc = REXML::Document.new(input, {compress_whitespace: :all})
graph = Graph.new

doc.elements.each("/gedcom/INDI") do |element|
  indi = Individual.from_xml(element)
  $individuals[indi.id] = indi
  #puts indi.id
  graph << indi
  # puts indi.inspect
  #indi.save!
end

puts graph.dump(:rdfxml, standard_prefixes: true, max_depth: 10, attributes: :untyped, base_uri: 'http://example.com/')

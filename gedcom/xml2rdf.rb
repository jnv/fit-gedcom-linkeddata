#!/usr/bin/env ruby

require 'linkeddata'
require 'rexml/document'
require 'active_support/all'
include RDF

BIO = Vocabulary.new('http://purl.org/vocab/bio/0.1/')
REL = Vocabulary.new('http://purl.org/vocab/relationship/')

$individuals = {}
$families = {}

def clean_id(value)
  value.delete('@').strip
end

def fragment_uri(uri)
  ::RDF::URI.new("\##{clean_id(uri)}")
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
    @family_ids = []
    @subject = RDF::Node(id)
    @repo = Repository.new
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
    @repo << [@subject, RDF.type, TYPE]
    PROPERTIES.each do |prop, predicate|
      value = self.send(prop)
      @repo.insert(Statement.new(@subject, predicate, value))
    end
    @givennames.each do |value|
      @repo << [@subject, FOAF.givenName, value]
    end
    @repo
  end

  def to_uri
    ::RDF::URI.new("\##{id}")
  end

  def add_child(id)
    @repo << [@subject, REL.parentOf, fragment_uri(id)]
  end

  def add_spouse(id)
    @repo << [@subject, REL.spouseOf, fragment_uri(id)]
  end

  def add_parents(*ids)
    ids.each do |id|
      @repo << [@subject, REL.childOf, fragment_uri(id)]
    end
  end

  def add_siblings(ids = [])
    ids.each do |id|
      next if id == @id
      @repo << [@subject, REL.siblingOf, fragment_uri(id)]
    end
  end

  # def each(*args, &block)
  # end


end

class Family
  TYPE = FOAF.Group
  attr_accessor :id
  # has_many :individuals, predicate: FOAF.Member
  def self.from_xml(e)
    id = clean_id(e.attributes['id'])
    f = Family.new(id)
    children = []
    e.elements.each('CHIL') do |elem|
      children << clean_id(elem.text)
    end

    husb_id = clean_id(e.elements['HUSB'].text)
    wife_id = clean_id(e.elements['WIFE'].text)
    husb = $individuals[husb_id]
    wife = $individuals[wife_id]

    husb.add_spouse(wife_id)
    wife.add_spouse(husb_id)

    children.each do |cid|
      husb.add_child(cid)
      wife.add_child(cid)
      child = $individuals[cid]
      child.add_parents(husb_id, wife_id)
      child.add_siblings(children)
    end

    f
  end

  def initialize(id)
    @id = id
    @subject = RDF::Node(id)
    @members = []
    @repo = Repository.new
  end

  def add_member(member)
    @members << member
    @repo << [@subject, FOAF.member, member.to_uri]
  end

  # def each(*args, &block)
    #XXX support RDF::Enumerable
  # end

  def to_rdf
    @repo << [@subject, RDF.type, TYPE]
    @repo << [@subject, RDF.ID, @id]
    @repo
  end
end

class Groups
  attr_reader :collection
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

  def add_family_xml(e)
    #id = clean_id(e.attributes['id'])
    #add_family(id)
    family = Family.from_xml(e)
    @collection[family.id] = family
  end
end

# Raw XML processing & Graph
input = File.new('sample.xml')
doc = REXML::Document.new(input, {compress_whitespace: :all})
graph = Graph.new
groups = Groups.new
doc.elements.each("/gedcom/INDI") do |element|
  indi = Individual.from_xml(element)
  $individuals[indi.id] = indi

  #puts indi.id
  #graph << indi
  # puts indi.inspect
  #indi.save!
end

doc.elements.each("/gedcom/FAM") do |element|
  groups.add_family_xml(element)
end

$individuals.each do |id, indi|
  graph << indi
end

groups.collection.each do |id, group|
  graph << group
end


puts graph.dump(:rdfxml, standard_prefixes: true, max_depth: 10, attributes: :untyped, base_uri: 'http://example.com/')

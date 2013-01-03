#!/usr/bin/env ruby

require 'linkeddata'
require 'rexml/document'
require 'active_support/all'
include RDF

INPUT = 'sample.xml'

BIO = Vocabulary.new('http://purl.org/vocab/bio/0.1/')
REL = Vocabulary.new('http://purl.org/vocab/relationship/')

$individuals = {}
$families = {}

def clean_id(value)
  value.delete('@').strip
end

def fragment_uri(obj)
  if obj.respond_to?(:id)
    id = obj.id
  else
    id = clean_id(obj)
  end
  ::RDF::URI.new("\##{id}")
end

class Event
  TYPE = BIO.event

  PROPERTIES = {
    date: BIO.date,
    place: BIO.place
  }

  attr_accessor :date, :place
  attr_reader :subject

  def self.from_xml(e)
    type = case e.name
    when 'DEAT' then :Death
    when 'BIRT' then :Birth
    else
      raise "Unknown event type #{e.name}"
    end

    date = e.elements['DATE'].try(:text).try(:strip)
    place = e.elements['PLAC'].try(:text).try(:strip)

    event = self.new(type, date, place)

    event
  end

  def initialize(type, date = nil, place = nil)
    @subtype = BIO[type]
    @date = date if date #Date.new(date) if date
    @place = place if place
    @repo = Repository.new
    @subject = Node.uuid
  end

  def to_rdf
    @repo << [@subject, RDF.type, @subtype]
    PROPERTIES.each do |prop, predicate|
      value = self.send(prop)
      next if value.nil?
      @repo << [@subject, predicate, value]
    end
    @repo
  end

  def empty?
    date.nil? and place.nil?
  end
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
  attr_accessor :id, :name, :givennames, :surname, :gender, :fams_ids, :famc_ids

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
      i.surname = e.elements['NAME/SURN'].try(:text).try(:strip)
      i.gender = case e.elements['SEX'].try(:text).try(:strip)
      when 'M' then 'male'
      when 'F' then 'female'
      else 'unknown'
      end

      fams = e.elements.to_a('FAMS')
      unless fams.blank?
        i.fams_ids = fams.map(&:text).map {|fam| clean_id(fam)}
      end

      famc = e.elements.to_a('FAMC')
      unless famc.blank?
        i.famc_ids = famc.map(&:text).map {|fam| clean_id(fam)}
      end
      #deat = e.elements['DEAT']
      #i.death = Death.from_xml(deat) unless deat.nil?

      e.elements.each('BIRT|DEAT') do |element|
        i.add_event(Event.from_xml(element))
      end

    end
    indi
  end

  def initialize(id)
    @id = id
    @givennames = []
    @famc_ids = []
    @fams_ids = []
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
      next if value.nil?
      @repo.insert(Statement.new(@subject, predicate, value))
    end
    @givennames.each do |value|
      next if value.nil?
      @repo << [@subject, FOAF.givenName, value]
    end
    @repo
  end

  def to_uri
    ::RDF::URI.new("\##{id}")
  end

  def add_event(event)
    #return if event.empty?
    @repo << [@subject, Event::TYPE, event.subject]
    @repo << event.to_rdf
  end

  def add_child(id)
    @repo << [@subject, REL.parentOf, fragment_uri(id)]
  end

  def add_spouses(spouses = [])
    spouses.each do |sp|
      next if sp.id == @id
      @repo << [@subject, REL.spouseOf, sp.to_uri]
    end
  end

  def add_parents(parents = [])
    parents.each do |parent|
      @repo << [@subject, REL.childOf, parent.to_uri]
    end
  end

  def add_siblings(siblings = [])
    siblings.each do |sib|
      next if sib.id == @id
      @repo << [@subject, REL.siblingOf, sib.to_uri]
    end
  end

  def add_children(children = [])
    children.each do |ch|
      @repo << [@subject, REL.parentOf, ch.to_uri]
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
    @spouses = []
    @children = []
    @repo = Repository.new
  end

  def add_member(member)
    @members << member
    @repo << [@subject, FOAF.member, member.to_uri]
  end

  def add_spouse(individual)
    @spouses << individual
    add_member(individual)
  end

  def add_child(individual)
    @children << individual
    add_member(individual)
  end

  def resolve_siblings
    #resolve_relations(@children, :add_siblings)
    @children.each {|ch| ch.add_siblings(@children)}
  end

  def resolve_spouses
    #resolve_relations(@spouses, :add_spouses)
    @spouses.each {|sp| sp.add_spouses(@spouses)}
  end

  def resolve_parents
    @children.each do |child|
      child.add_parents(@spouses)
    end
  end

  def resolve_children
    @spouses.each do |spouse|
      spouse.add_children(@children)
    end
  end

  def resolve_all
    resolve_siblings
    resolve_spouses
    resolve_parents
    resolve_children
  end

  def resolve_relations(source, method, target = nil)
    source = target if target.nil?

    target.each do |t|
      t.send(method, source)
    end
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
    indi.famc_ids.each do |fam_id|
      family = add_family(fam_id)
      family.add_child(indi)
    end

    indi.fams_ids.each do |fam_id|
      family = add_family(fam_id)
      family.add_spouse(indi)
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

  def resolve!
    @collection.each do |id, family|
      family.resolve_all
    end
  end
end

# Raw XML processing & Graph
input = File.new(INPUT)
doc = REXML::Document.new(input, {compress_whitespace: :all})
graph = Graph.new
groups = Groups.new

$stderr.puts "Processing individuals..."

doc.elements.each("/gedcom/INDI") do |element|
  indi = Individual.from_xml(element)
  $individuals[indi.id] = indi

  #puts indi.id
  #graph << indi
  # puts indi.inspect
  #indi.save!
end

$stderr.puts "Processing families..."

$individuals.each do |id, indi|
  groups.add_individual(indi)
end

$stderr.puts "Resolving families..."
groups.resolve!

# doc.elements.each("/gedcom/FAM") do |element|
# groups.add_family_xml(element)
# end

$stderr.puts "Adding individuals to graph..."
$individuals.each do |id, indi|
  graph << indi
end

$stderr.puts "Adding families to graph..."
groups.collection.each do |id, group|
  graph << group
end

$stderr.puts "Dumping..."
puts graph.dump(:rdfxml, standard_prefixes: true, max_depth: 10, attributes: :untyped, base_uri: 'http://example.com/')

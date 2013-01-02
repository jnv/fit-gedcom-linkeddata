#!/usr/bin/env ruby

require 'linkeddata'
require 'rexml/document'
require 'spira'
include RDF

BIO = Vocabulary.new('http://purl.org/vocab/bio/0.1/')
REL = Vocabulary.new('http://purl.org/vocab/relationship')

Spira.add_repository!(:default, Repository.load('sample.nt'))

class Death
  include Spira::Resource
  type BIO.Death
  property :date, predicate: BIO.date
  property :place, predicate: BIO.place

  def self.from_xml(e)
    ev = self.new
    date = e.elements['DATE']
    ev.date = date.text.strip unless date.nil?

    plac = e.elements['PLAC']
    ev.place = plac.text.strip unless plac.nil?
    ev
  end

end


class Individual
  include Spira::Resource
  type FOAF.Person
  property :id, predicate: RDF.ID
  property :name,  predicate: FOAF.name
  property :givenname, predicate: FOAF.givenname
  property :surname, predicate: FOAF.family_name
  property :gender, predicate: FOAF.gender
  property :death, type: :Death, predicate: BIO.Event

  def self.from_xml(e)
    id = e.attributes['id'].delete('@').strip
    indi = self.new
    indi.id = id
    indi.name = e.elements['NAME'].text.strip
    #TODO: There can be more than one givn
    indi.givenname = e.elements['NAME/GIVN'].text.strip
    indi.surname = e.elements['NAME/SURN'].text.strip
    indi.gender = case e.elements['SEX'].text.strip
    when 'M' then 'male'
    when 'F' then 'female'
    else 'unknown'
    end

    deat = e.elements['DEAT']
    indi.death = Death.from_xml(deat) unless deat.nil?

    indi
  end
end

module Event
end

class Birth
end

# Raw XML processing & Graph
input = File.new('sample.xml')
doc = REXML::Document.new(input, {compress_whitespace: :all})
individuals = {}
graph = Graph.new

doc.elements.each("/gedcom/INDI") do |element|
  indi = Individual.from_xml(element)
  individuals[indi.id] = indi
  #puts indi.id
  graph << indi
  #indi.save!
end

puts graph.dump(:rdf)

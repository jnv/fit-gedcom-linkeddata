# GEDCOM→XML→Linked Data

This is quick & dirty GEDCOM to Linked Data (RDF) convertor in Ruby (MRI 1.9.3).

The conversion works in two steps.

## GEDCOM→XML (ged2xml)

First, the GEDCOM is converted to the equivalent XML representation:

```xml
<gedcom>
<INDI id='@I1@'>
  <NAME>John Douglas /Cochrane/
    <GIVN>John Douglas</GIVN>
    <SURN>Cochrane</SURN>
  </NAME>
  <SEX>M</SEX>
  <BIRT>
    <DATE>21 Oct 1884</DATE>
    <PLAC>Drummond Terrace, Ottawa, Ontario, Canada</PLAC>
  </BIRT>
  …
```

The script is based on [the solution to the GEDCOM Parser quiz](http://www.rubyquiz.com/quiz6.html).

### Usage

```sh
./ged2xml.rb <input.ged> > output.xml
```

## XML→Linked Data (xml2rdf)

The XML representation of GEDCOM can be then converted to the Linked Data using the following ontologies:

* [FOAF](http://xmlns.com/foaf/spec/) for basic definitions of Persons and Families (as Groups)
* [BIO](http://vocab.org/bio/0.1/.html) for life events such as birth and death
* [RELATIONSHIP](http://vocab.org/relationship/.html) for parent/children, sibling and spouse relations between Persons

This is heavily inspired by [Gedcom::FOAF](http://search.cpan.org/~bricas/Gedcom-FOAF-0.05/lib/Gedcom/FOAF.pm) for Perl by Brian Cassidy and [the script by danbri](http://danbri.org/words/2009/01/18/390).

The script has a few dependencies, most notably the [Linked Data gem](http://ruby-rdf.github.com/linkeddata/)  with an awesome [RDF.rb](http://ruby-rdf.github.com/rdf/) library. Dependencies are managed with [Bundler](http://gembundler.com/).

### Usage

```sh
bundle install
bundle exec ./xml2rdf.rb <input.xml> > output.rdf
```

See `sample.rdf.xml` for a sample output of this script.

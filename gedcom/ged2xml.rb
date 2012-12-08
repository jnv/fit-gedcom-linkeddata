#!/usr/bin/env ruby
# Based on http://www.rubyquiz.com/quiz6.html
require 'rexml/document'

doc = REXML::Document.new "<gedcom/>"
stack = [doc.root]
i = 0
file = File.open(ARGV[0], 'r:bom|utf-8')

file.each_line do |line|
  i += 1
  next if line =~ /^\s*$/

  # parse line
  line =~ /^\s*(\d+)\s+(@\S+@|\S+)(\s(.*))?$/ or raise "Invalid GEDCOM at #{i}: #{line}"
  level = $1.to_i
  tag = $2
  data = $4

  # pop off the stack until we get the parent
  while (level+1) < stack.size
    stack.pop
  end
  parent = stack.last

  # create XML tag
  el = nil
  if tag =~ /@.+@/
    el = parent.add_element data
    el.attributes['id'] = tag
  else
    el = parent.add_element tag
    el.text = data
  end

  stack.push el
end
file.close

doc.write($stdout,0)
puts

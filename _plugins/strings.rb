print "Loading strings.rb\n"

$_strings = nil

def get_string(string_id)
  if $_strings.nil?
    $_strings = Jekyll.configuration({})["strings"]
  end

  if $_strings[string_id].nil?
    print "Warning: string not found: '#{string_id}'\n"
    return "MISSING: #{string_id}"
  end

  $_strings[string_id]
end

module Jekyll
  class StringsTag < Liquid::Tag

    def initialize(tag_name, args, tokens)
      super
      @arg = args.strip
    end

    def render(context)
      get_string(@arg)
    end
  end

  module StringsFilter
    def str(input)
      get_string(input.strip)
    end
  end
end

Liquid::Template.register_tag('str', Jekyll::StringsTag)
Liquid::Template.register_filter(Jekyll::StringsFilter)

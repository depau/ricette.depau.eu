require 'liquid/variable'

def parse_markup(markup, parse_context)
  params = {}
  regex = /(\w+):\s*(\([^)]+\)|"[^"]+"|[^,]+)/

  markup.scan(regex) do |param_name, expression|
    params[param_name] = Liquid::Variable.new(expression.strip, parse_context)
  end

  params
end

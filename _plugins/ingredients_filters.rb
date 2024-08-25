print "Loading quantities_filter.rb\n"

module Jekyll
  module QuantitiesFilter
    def fractions(input)
      case input
      when 0.5
        "½"
      when 0.25
        "¼"
      when 0.75
        "¾"
      when 0.33
        "⅓"
      when 0.66
        "⅔"
      when 0.2
        "⅕"
      when 0.4
        "⅖"
      when 0.6
        "⅗"
      when 0.8
        "⅘"
      else
        input
      end
    end

    def ingredient_name(input)
      res = input["name"]
      if input["notes"]
        unless input["notes"][0] == "("
          res += ","
        end
        res += " " + input["notes"]
      end
      res
    end

    def quantities(input)
      entries = []

      if input["amount"]
        entries << fractions(input["amount"])
      end
      if input["unit"]
        entries << input["unit"]
      end
      if input["approx_qty"]
        entries << input["approx_qty"]
      end

      if input["qty"]
        if entries.empty?
          entries << input["qty"]
        else
          entries.unshift("×")
          entries.unshift(input["qty"])
        end
      end

      if entries.empty?
        "q.b."
      else
        entries.join(" ")
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::QuantitiesFilter)
  
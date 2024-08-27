print "Loading photoswipe_tag.rb\n"

require 'liquid/variable'
require 'mini_magick'

module Jekyll
  class PhotoSwipeTag < Liquid::Tag
    def initialize(tag_name, markup, parse_context)
      super
      @params = parse_markup(markup, parse_context)
    end

    def render(context)
      site = context.registers[:site]

      image_path = @params["image"].render(context)
      thumb_size = @params["thumb_size"] && @params["thumb_size"].render(context) || 600
      alt = @params["alt"] && @params["alt"].render(context) || ""

      abs_image_path = File.join(site.source, image_path)
      raise "File not found: #{image_path}" unless File.exist?(abs_image_path)

      thumb = gen_thumbnail(site, image_path, thumb_size)

      image = MiniMagick::Image.open(abs_image_path)
      raise "Failed to open image: #{image_path}" if image.nil?

      escaped_path = ("/" + image_path).gsub('"', '\"').gsub("//", "/")
      escaped_thumb = ("/" + thumb).gsub('"', '\"').gsub("//", "/")
      escaped_alt = CGI.escapeHTML(alt)

      "<a href=\"#{site.baseurl}#{escaped_path}\" data-pswp-width=\"#{image.width}\" data-pswp-height=\"#{image.height}\">" +
        "<img src=\"#{site.baseurl}#{escaped_thumb}\" alt=\"#{escaped_alt}\">" +
        "</a>"
    end
  end
end

Liquid::Template.register_tag('photoswipe_img', Jekyll::PhotoSwipeTag)

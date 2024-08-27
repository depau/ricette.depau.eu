print "Loading thumb_tag.rb\n"

require 'mini_magick'
require 'set'
require 'in_threads'
require 'etc'

$_thumbs = Set.new

def gen_thumbnail(site, src_path, size)
  dest_path = File.join("thumbs", size.to_s, src_path)
  abs_src_path = File.join(site.source, src_path)
  raise "Image file not found: #{src_path}" unless File.exist?(abs_src_path)

  $_thumbs.add([src_path, dest_path, size])

  "#{site.baseurl}/#{dest_path}"
end

def crop_square(image, size)
  if image.width < image.height
    new_size = "#{size}x"
  else
    new_size = "x#{size}"
  end
  image.resize new_size

  image.combine_options do |c|
    c.gravity "center"
    c.extent "#{size}x#{size}"
  end
end

def scale(image, size)
  image.resize "#{size}x#{size}"
end

def cache
  $_cache ||= Jekyll::Cache.new("ConvertMarkdown")
end

Jekyll::Hooks.register :site, :post_write do |site|
  source = site.source
  dest = site.dest

  $_thumbs.in_threads(Etc.nprocessors).each do |src_path, dest_path, size|
    original_image_path = File.join(source, src_path)
    raise "File not found: #{original_image_path}" unless File.exist?(original_image_path)

    thumb_image_path = File.join(dest, dest_path)
    thumb_image_dir = File.dirname(thumb_image_path)
    FileUtils.mkdir_p(thumb_image_dir) unless Dir.exist?(thumb_image_dir)

    mtime = File.mtime(original_image_path)
    if !File.exist?(thumb_image_path) || mtime > File.mtime(thumb_image_path)
      file_written = false

      img_bytes = cache.getset("#{original_image_path}:#{size}:#{mtime.to_f}") do
        print "Generate thumbnail: #{thumb_image_path}\n"

        image = MiniMagick::Image.open(original_image_path)
        raise "Failed to open image: #{original_image_path}" if image.nil?

        scale(image, size)
        image.write(thumb_image_path)

        file_written = true
        File.read(thumb_image_path)
      end

      unless file_written
        print "Cached thumbnail: #{thumb_image_path}\n"
        File.open(thumb_image_path, "wb") do |f|
          f.write(img_bytes)
        end
      end

      reader = Jekyll::StaticFileReader.new(site, File.dirname(dest_path))
      site.static_files.concat(reader.read([File.basename(thumb_image_path)]))
    end
  end
end

module Jekyll
  class ThumbTag < Liquid::Tag
    def initialize(tag_name, markup, parse_context)
      super
      @params = parse_markup(markup, parse_context)
    end

    def render(context)
      site = context.registers[:site]

      image_path = @params["image"].render(context)
      size = @params["size"].render(context).to_i

      gen_thumbnail(site, image_path, size)
    end
  end
end

Liquid::Template.register_tag('thumb', Jekyll::ThumbTag)

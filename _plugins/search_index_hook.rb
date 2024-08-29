# frozen_string_literal: true

print "Loading search_index_hook.rb\n"

require 'json'

def add_keywords(index, string, page)
  string.downcase.split(/[^a-z0-9]/).each do |word|
    next if word.empty?

    index[word] << page
  end
end

def flatten_ingredients(page_data)
  return [] unless page_data['ingredients']

  page_data['ingredients'].map { |ingredient_group|
    ingredient_group.values.map { |ingredients|
      ingredients.map { |ingredient|
        ingredient['name']
      }
    }
  }.flatten.compact
end

def get_page_data(page)
  {
    'url' => page.url,
    'title' => page.data['title'],
    'thumbnail' => page.data['images'] && gen_thumbnail(page.site, page.data['images'][0], 300) || nil,
    'prepTime' => page.data['eta']['preparation'],
    'cookTime' => page.data['eta']['cooking'],
    'restTime' => page.data['eta']['resting'],
    'ingredients' => flatten_ingredients(page.data),
  }
end

def gen_index(pages)
  pages.map { |page| get_page_data(page) }
end

Jekyll::Hooks.register :site, :post_write do |site|
  print "Generating search index\n"

  pages_by_tag = {}
  pages_by_tag.default_proc = proc { |h, k| h[k] = [] }

  all_pages = []
  site.collections.each_value do |collection|
    collection.docs.each do |doc|
      all_pages << doc
      doc.data['tags'].each do |tag|
        pages_by_tag[tag] << doc
      end
    end
  end
  pages_by_tag['root'] = all_pages

  pages_by_tag.each do |tag, pages|
    search_index = gen_index(pages)

    FileUtils.mkdir_p(File.join(site.dest, 'assets'))
    dest_path = File.join('assets', "search_index_#{tag}.json")
    File.open(File.join(site.dest, dest_path), 'w') do |file|
      file.write(JSON.generate(search_index))
    end

    reader = Jekyll::StaticFileReader.new(site, File.dirname(dest_path))
    site.static_files.concat(reader.read([File.basename(dest_path)]))
  end
end

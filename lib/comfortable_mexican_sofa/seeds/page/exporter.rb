module ComfortableMexicanSofa::Seeds::Page
  class Exporter < ComfortableMexicanSofa::Seeds::Exporter

    def initialize(from, to = from)
      super
      self.path = ::File.join(ComfortableMexicanSofa.config.seeds_path, to, "pages/")
    end

    def export!
      prepare_folder!(self.path)

      self.site.pages.each do |page|
        page.slug = 'index' if page.slug.blank?
        page_path = File.join(path, page.ancestors.reverse.map{|p| p.slug.blank?? 'index' : p.slug}, page.slug)
        FileUtils.mkdir_p(page_path)

        path = ::File.join(page_path, "content.html")
        data = []

        attrs = {
          "label"        => page.label,
          "layout"       => page.layout.try(:identifier),
          "target_page"  => page.target_page.try(:full_path),
          "categories"   => page.categories.map{|c| c.label},
          "is_published" => page.is_published,
          "position"     => page.position
        }.to_yaml

        data << {header: "attributes", content: attrs}

        page.fragments.each do |frag|

          header = "#{frag.tag} #{frag.identifier}"
          content = case frag.tag
          when "datetime", "date"
            frag.datetime
          when "checkbox"
            frag.boolean
          when "file", "files"
            frag.attachments.map do |attachment|
              ::File.open(::File.join(page_path, attachment.filename.to_s), "wb") do |f|
                f.write(attachment.download)
              end
              attachment.filename
            end.join("\n")
          else
            frag.content
          end
          data << {header: header, content: content}
        end

        write_file_content(path, data)

        message = "[CMS SEEDS] Exported Page \t #{page.full_path}"
        ComfortableMexicanSofa.logger.info(message)
      end
    end
  end
end
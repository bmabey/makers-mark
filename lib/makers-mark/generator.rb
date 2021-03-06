module MakersMark
  class Generator
    def initialize(markdown)
      @markdown = markdown
    end

    def to_html
      highlight!
      doc.search('body > *').to_html
    end

    private

    def doc
      @doc ||= Nokogiri::HTML(markup)
    end

    def highlight!
      doc.search('div.code').each do |div|
        lexer = div['rel'] || :ruby

        text, lines_to_defocus = extract_defocus_marks(div.text)
        lexted_text = Albino.new(text, lexer).to_s

        highlighted = Nokogiri::HTML(lexted_text).at('div')

        klasses = highlighted['class'].split(/\s+/)
        klasses << lexer
        klasses << 'code'
        klasses << 'highlight'
        highlighted['class'] = klasses.join(' ')

        div.replace(highlighted)
      end
    end


    def extract_defocus_marks(text)
      lines_to_defocus = []
      text.strip.split("\n").each_with_index do |line, index|
        lines_to_defocus << index if line =~ /~~\s*$/
      end
      [text.gsub(/~~\s*$/,''), lines_to_defocus]
    end

    def markup
      @markup ||= begin
        logger.info "WRITING!"
        t = BlueCloth.new(@markdown.dup).to_html
        t.gsub!(/^(?:<p>)?@@@(?:<\/p>)?$/, '</div>')
        t.gsub!(/^(?:<p>)?@@@\s*([\w\+]+)(?:<\/p>)?$/, '<div class="code" rel="\1">')
        t
      end
    end

    def logger
      @logger ||= Class.new {
        def info(msg)
          say msg
        end

        private

        def say(msg)
          $stdout.puts msg if $VERBOSE
        end
      }.new
    end
  end
end

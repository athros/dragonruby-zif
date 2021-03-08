module Zif
  module UI
    # A basic label which is aware of it's size and can be truncated
    class Label
      include Zif::Actions::Actionable

      ALIGNMENT = {
        left:   0,
        center: 1,
        right:  2
      }

      # @return [Numeric] X axis position
      attr_accessor :x
      # @return [Numeric] Y axis position
      attr_accessor :y
      # @return [Numeric] Red color (+0-255+)
      attr_accessor :r
      # @return [Numeric] Green color (+0-255+)
      attr_accessor :g
      # @return [Numeric] Blue color (+0-255+)
      attr_accessor :b
      # @return [Numeric] Alpha channel (Transparency) (+0-255+)
      attr_accessor :a
      # @return [String] The complete text of the label before truncation
      attr_accessor :full_text
      # @return [String] The current visible text of the label
      attr_reader :text
      # @return [Integer] The maximum width of the full text
      attr_reader :max_width
      # @return [Integer] The minimum width of the text truncated down to just the ellipsis
      attr_reader :min_width
      # @return [Integer] The minimum height of the text truncated down to just the ellipsis
      attr_reader :min_height
      # @return [Integer] The size value to render the text at
      attr_accessor :size
      # @return [String] A character to use to indicate the text has been truncated
      attr_accessor :ellipsis
      # @return [String] Path to the font file
      attr_accessor :font

      alias size_enum size

      # @param [String] text {full_text}
      # @param [Integer] size {size}
      # @param [Symbol, Integer] alignment {align} +:left+, +:center+, +:right+ or +0+, +1+, +2+. See {ALIGNMENT}
      # @param [String] font {font}
      # @param [String] ellipsis {ellipsis}
      # @param [Integer] r {r}
      # @param [Integer] g {g}
      # @param [Integer] b {b}
      # @param [Integer] a {a}
      def initialize(text="", size: -1, alignment: :left, font: "font.tff", ellipsis: "…", r: 51, g: 51, b: 51, a: 255)
        @text = text
        @full_text = text
        @size = size
        @alignment = ALIGNMENT.fetch(alignment, alignment)
        @ellipsis = ellipsis
        @font = font
        @r = r
        @g = g
        @b = b
        @a = a
        recalculate_minimums
      end

      def text=(new_text)
        @full_text = new_text
        @text = new_text
      end

      # Set alignment using either symbol names or the enum integer values.
      # @param [Symbol, Integer] new_alignment {align} +:left+, +:center+, +:right+ or +0+, +1+, +2+. See {ALIGNMENT}
      # @return [Integer] The integer value for the specified alignment
      def align=(new_alignment)
        @alignment = ALIGNMENT.fetch(new_alignment, new_alignment)
      end

      # @return [Integer] The integer value for the specified alignment.  See {ALIGNMENT}
      # @example This always returns an integer, even if you set it using a symbol
      #   mylabel.align = :center # => 1
      #   mylabel.align           # => 1
      def align
        @alignment
      end

      alias alignment_enum align

      # @return [Array<Integer>] 2-element array [+w+, +h+] of the current text
      def rect
        $gtk.calcstringbox(@text, @size, @font).map(&:round)
      end

      # @return [Array<Integer>] 2-element array [+w+, +h+] of the full sized text
      def full_size_rect
        $gtk.calcstringbox(@full_text, @size, @font).map(&:round)
      end

      # Recalculate {min_width} {max_width} {min_height}
      # You should invoke this if the text is changing & you care about truncation
      def recalculate_minimums
        @min_width, @min_height = $gtk.calcstringbox(@ellipsis, @size, @font)
        @max_width, = full_size_rect
      end

      # Determine the largest possible portion of the text we can display
      # End the text with an ellispsis if truncation occurs
      # @param [Integer] width The allowable width of the text, will be truncated until it fits
      def truncate(width)
        if @max_width <= width
          @text = @full_text
          return
        end

        (@full_text.length - 1).downto 0 do |i|
          truncated = "#{@full_text[0..i]}#{@ellipsis}"
          cur_width, = $gtk.calcstringbox(truncated, @size, @font)
          if cur_width <= width
            @text = truncated
            return # rubocop:disable Lint/NonLocalExitFromIterator
          end
        end

        @text = ''
      end

      # Recalculate minimums and then truncate
      def retruncate(width)
        recalculate_minimums
        truncate(width)
      end

      # Reposition {x} and {y} to center the text
      # @param [Integer] w Width
      # @param [Integer] h Height
      # @param [Integer] offset Y-Offset
      def recenter_in(w, h, offset: 0)
        @x = w.idiv(2)
        @y = (h + min_height).idiv(2) + offset
      end

      # @api private
      def primitive_marker
        :label
      end
    end
  end
end

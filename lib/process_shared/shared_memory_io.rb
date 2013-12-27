module ProcessShared
  # Does some bounds checking for EOF, but assumes underlying memory
  # object (FFI::Pointer) will do bounds checking, in particular the
  # {#_putbytes} method relies on this.
  #
  # Note: an unbounded FFI::Pointer may be converted into a bounded
  # pointer using +ptr.slice(0, size)+.
  class SharedMemoryIO

    attr_accessor :pos
    attr_reader :mem

    def initialize(mem)
      @mem = mem
      @pos = 0
      @closed = false           # TODO: actually pay attention to this
    end
    
    def <<(*args)
      raise NotImplementedError
    end

    def advise(*args)
      # no-op
    end
    
    def autoclose=(*args)
      raise NotImplementedError
    end

    def autoclose?
      raise NotImplementedError
    end

    def binmode
      # no-op; always in binmode
    end

    def binmode?
      true
    end

    def bytes
      if block_given?
        until eof?
          yield _getbyte
        end
      else
        raise NotImplementedError
      end
    end
    alias_method :each_byte, :bytes

    def chars
      raise NotImplementedError
    end
    alias_method :each_char, :chars

    def close
      @closed = true
    end

    def close_on_exec=(bool)
      raise NotImplementedError
    end

    def close_on_exec?
      raise NotImplementedError
    end

    def close_read
      raise NotImplementedError
    end

    def close_write
      raise NotImplementedError
    end

    def closed?
      @closed
    end

    def codepoints
      raise NotImplementedError
    end
    alias_method :each_codepoint, :codepoints

    def each
      raise NotImplementedError
    end
    alias_method :each_line, :each
    alias_method :lines, :each

    def eof?
      pos == mem.size
    end
    alias_method :eof, :eof?

    def external_encoding
      raise NotImplementedError
    end

    def fcntl
      raise NotImplementedError
    end

    def fdatasync
      raise NotImplementedError
    end

    def fileno
      raise NotImplementedError
    end
    alias_method :to_i, :fileno

    def flush
      # no-op
    end

    def fsync
      raise NotImplementedError
    end

    def getbyte
      return nil if eof?
      _getbyte
    end

    # {#getc} in Ruby 1.9 returns String or nil.  In 1.8, it returned
    # Fixnum of nil (identical to getbyte).
    #
    # FIXME: should this be encoding/character aware?
    def getc19
      if b = getbyte
        '' << b
      end
    end
    # FIXME: ignores versions prior to 1.8.
    if RUBY_VERSION =~ /^1.8/
      alias_method :getc, :getbyte
    else
      alias_method :getc, :getc19
    end

    def gets
      raise NotImplementedError
    end

    def internal_encoding
      raise NotImplementedError
    end

    def ioctl
      raise NotImplementedError
    end

    def tty?
      false
    end
    alias_method :isatty, :tty?

    def lineno
      raise NotImplementedError
    end

    def lineno=
      raise NotImplementedError
    end

    def lines
      raise NotImplementedError
    end

    def pid
      raise NotImplementedError
    end

    alias_method :tell, :pos

    def print(*args)
      raise NotImplementedError
    end
    def printf(*args)
      raise NotImplementedError
    end

    def putc(arg)
      raise NotImplementedError
    end

    def puts(*args)
      raise NotImplementedError
    end

    # FIXME: this doesn't match IO#read exactly (corner cases about
    # EOF and whether length was nil or not), but it's enough for
    # {Marshal::load}.
    def read(length = nil, buffer = nil)
      length ||= (mem.size - pos)
      buffer ||= ''
      buffer.force_encoding('ASCII-8BIT') unless RUBY_VERSION.start_with?('1.8')
      
      actual_length = [(mem.size - pos), length].min
      actual_length.times do
        buffer << _getbyte
      end
      buffer
    end

    def read_nonblock(*args)
      raise NotImplementedError
    end

    def readbyte
      raise EOFError if eof?
      _getbyte
    end

    def readchar
      raise NotImplementedError
    end

    def readline
      raise NotImplementedError
    end

    def readlines
      raise NotImplementedError
    end

    def readpartial
      raise NotImplementedError
    end

    def reopen
      raise NotImplementedError
    end

    def rewind
      pos = 0
    end

    def seek(amount, whence = IO::SEEK_SET)
      case whence
      when IO::SEEK_CUR
        self.pos += amount
      when IO::SEEK_END
        self.pos = (mem.size + amount)
      when IO::SEEK_SET
        self.pos = amount
      else
        raise ArgumentError, "bad seek whence #{whence}"
      end
    end

    def set_encoding
      raise NotImplementedError
    end

    def stat
      raise NotImplementedError
    end

    def sync
      true
    end

    def sync=
      raise NotImplementedError
    end

    def sysread(*args)
      raise NotImplementedError
    end

    def sysseek(*args)
      raise NotImplementedError
    end

    def syswrite(*args)
      raise NotImplementedError
    end

    def to_io
      raise NotImplementedError
    end

    def ungetbyte
      raise IOError if pos == 0
      pos -= 1
    end

    def ungetc
      raise NotImplementedError
    end

    def write(str)
      s = str.to_s
      _putbytes(s)
      s.size
    end

    def write_nonblock(str)
      raise NotImplementedError
    end

    private

    # Like {#getbyte} but does not perform eof check.
    def _getbyte
      b = mem.get_uchar(pos)
      self.pos += 1
      b
    end

    def _putbytes(str)
      mem.put_bytes(pos, str, 0, str.size)
      self.pos += str.size
    end

  end
end

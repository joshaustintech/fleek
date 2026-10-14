# Fleek exposes native CLI usage and reference identities.
class Fleek
  VERSION = "0.1.0"
  FLAY_REFERENCE = "2.14.4"
  REEK_REFERENCE = "6.6.0"
  SPINEL_RELEASE = "2026.09.12"

  # Provides the native Prism parser adapter.
  module NativePrism
    ffi_source <<~C
    #include "prism.h"
    #include <stdint.h>
    #include <stdio.h>

    static char fleek_parse_message_buffer[512];

    int fleek_parse_ruby4(const char *source, size_t length) {
      fleek_parse_message_buffer[0] = 0;
      const uint8_t *nul = (const uint8_t *) memchr(source, 0, length);
      if (nul != NULL) return -2;
      pm_options_t options = {0};
      options.line = 1;
      options.version = PM_OPTIONS_VERSION_CRUBY_4_0;
      pm_parser_t parser;
      pm_parser_init(&parser, (const uint8_t *) source, length, &options);
      pm_parse(&parser);
      int result = -1;
      if (parser.error_list.head != NULL) {
        pm_diagnostic_t *diagnostic = (pm_diagnostic_t *) parser.error_list.head;
        result = (int) (diagnostic->location.start - (const uint8_t *) source);
        snprintf(fleek_parse_message_buffer, sizeof(fleek_parse_message_buffer), "%s", diagnostic->message);
      } else if (parser.comment_list.size > 0) {
        result = -3;
      }
      pm_parser_free(&parser);
      pm_options_free(&options);
      return result;
    }

    const char *fleek_parse_message(void) {
      return fleek_parse_message_buffer;
    }
    C

    ffi_func :fleek_parse_ruby4, [:str, :size_t], :int
    ffi_func :fleek_parse_message, [], :str
  end

  def self.print_help
    puts "Usage: fleek [--help | --version]"
    puts "       fleek --parse-ruby4 SOURCE (parser prototype; runs no checks)"
    puts "Fleek #{VERSION} is a native Ruby analysis CLI. Checks are not available yet."
    puts "References: Flay #{FLAY_REFERENCE}; Reek #{REEK_REFERENCE}."
    puts "Compiler: Spinel #{SPINEL_RELEASE}."
  end

  def self.help_requested?(arguments)
    first_argument = arguments[0]
    arguments.length == 1 && (first_argument == "--help" || first_argument == "-h")
  end

  def self.version_requested?(arguments)
    first_argument = arguments[0]
    arguments.length == 1 && first_argument == "--version"
  end

  def self.print_version
    puts "Fleek #{VERSION} (Flay #{FLAY_REFERENCE}; Reek #{REEK_REFERENCE}; Spinel #{SPINEL_RELEASE})"
    0
  end

  def self.input_error(arguments)
    if arguments.empty?
      "ERROR: Select supported checks and source inputs."
    else
      "ERROR: Requested check or input is unsupported in this release."
    end
  end

  def self.print_help_if_requested(arguments)
    if help_requested?(arguments)
      print_help
      true
    else
      false
    end
  end

  def self.print_version_if_requested(arguments)
    if version_requested?(arguments)
      print_version
      true
    else
      false
    end
  end

  def self.print_usage_error(message)
    warn message
    warn "Usage: fleek [--help | --version]"
    1
  end

  def self.parse_ruby4_requested?(arguments)
    arguments.length == 2 && arguments[0] == "--parse-ruby4"
  end

  def self.parse_ruby4_file(path)
    unless File.file?(path) && File.readable?(path)
      warn "ERROR: Cannot read source file: #{path}"
      return 1
    end

    source = File.binread(path)
    parse_ruby4_source(path, source)
  end

  def self.parse_ruby4_source(path, source)
    offset = NativePrism.fleek_parse_ruby4(source, source.bytesize)
    return report_parse_failure(path, source, offset) unless parse_succeeded?(offset)

    comment_status = offset == -3 ? "; comments retained" : ""
    print_parse_success("PARSE OK (Ruby 4.0 syntax only; no checks ran#{comment_status})")
  end

  def self.print_parse_success(message)
    puts message
    0
  end

  def self.parse_succeeded?(offset)
    offset < 0 && offset != -2
  end

  def self.report_parse_failure(path, source, offset)
    if offset == -2
      warn "#{path}: embedded NUL byte is unsupported"
    else
      report_syntax_error(path, source, offset)
    end
    1
  end

  def self.report_syntax_error(path, source, offset)
    prefix = source.byteslice(0, offset)
    line = prefix.count("\n") + 1
    column = offset - (prefix.rindex("\n") || -1)
    diagnostic = NativePrism.fleek_parse_message
    warn "#{path}:#{line}:#{column}: #{diagnostic} (byte #{offset})"
  end

  def self.run(arguments)
    return parse_ruby4_file(arguments[1]) if parse_ruby4_requested?(arguments)
    return 0 if print_help_if_requested(arguments)
    return 0 if print_version_if_requested(arguments)

    print_usage_error(input_error(arguments))
  end
end

exit Fleek.run(ARGV)

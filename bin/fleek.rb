# Fleek exposes native CLI usage and reference identities.
class Fleek
  VERSION = "0.1.0"
  FLAY_REFERENCE = "2.14.4"
  REEK_REFERENCE = "6.6.0"
  SPINEL_RELEASE = "2026.09.12"

  def self.print_help
    puts "Usage: fleek [--help | --version]"
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

  def self.run(arguments)
    return 0 if print_help_if_requested(arguments)
    return 0 if print_version_if_requested(arguments)

    print_usage_error(input_error(arguments))
  end
end

exit Fleek.run(ARGV)

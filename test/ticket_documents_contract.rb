# Proves the local ticket checker accepts valid graphs and rejects malformed documents.
# :reek:InstanceVariableAssumption
# :reek:RepeatedConditional
# :reek:TooManyStatements
class TicketDocumentsContract
  TEMPORARY_ROOT = "/tmp/fleek-ticket-documents-#{Process.pid}"

  def run
    create_directory
    verifies_repository
    verifies_valid_graph
    rejects_malformed_graph
    puts "Ticket documents contract: pass"
  ensure
    remove_directory
  end

  def verifies_valid_graph
    write_issue("01-first.md", issue(1, "First ticket", "None (can start immediately)."))
    write_issue("02-second.md", issue(2, "Second ticket", "01: First ticket."))
    status = check
    raise "ticket checker rejected valid documents: #{output}" unless status.success?
    raise "ticket checker omitted success result: #{output}" unless output.include?("Ticket documents: 2 valid")
  end

  def verifies_repository
    status = check(".scratch")
    raise "repository tickets are invalid: #{output}" unless status.success?
  end

  def rejects_malformed_graph
    write_issue("01-first.md", issue(1, "First ticket", "02: Second ticket."))
    malformed = issue(2, "Mismatch", "09: Missing blocker, 10: Missing second blocker, nonexistent ticket 99.").sub("**Triage:** ready-for-agent", "**Triage:** invalid")
    write_issue("03-mismatch.md", malformed.sub("**Category:** enhancement\n", ""))
    status = check
    raise "ticket checker accepted malformed documents" if status.success?
    ["filename/heading number mismatch", "invalid triage", "missing Category", "missing blocker 9", "missing blocker 10", "invalid blocker reference nonexistent ticket 99", "dependency cycle"].each do |message|
      raise "ticket checker omitted #{message}: #{output}" unless output.include?(message)
    end
  end

  def issue(number, title, blockers)
    "# #{number}: #{title}\n\n**What to build:** A test ticket.\n\n**Blocked by:** #{blockers}\n**Status:** open\n**Type:** task\n**Category:** enhancement\n**Triage:** ready-for-agent\n\n- [ ] Verify behavior.\n"
  end

  def create_directory
    process_id = Process.spawn("mkdir", "-p", issues_directory)
    Process.waitpid2(process_id)
  end

  def write_issue(name, contents)
    File.write("#{issues_directory}/#{name}", contents)
  end

  def check(root = TEMPORARY_ROOT)
    @output_path = "#{TEMPORARY_ROOT}.out"
    @error_path = "#{TEMPORARY_ROOT}.err"
    checker = ENV.fetch("FLEEK_TICKET_CHECK", "bin/ticket_check.rb")
    process_id = Process.spawn(ENV.fetch("SPINEL", "spinel"), "-E", checker, root,
      out: @output_path, err: @error_path)
    _, status = Process.waitpid2(process_id)
    @output = File.read(@output_path) + File.read(@error_path)
    status
  end

  def output
    @output || ""
  end

  def issues_directory
    "#{TEMPORARY_ROOT}/sample/issues"
  end

  def remove_directory
    Process.spawn("rm", "-rf", TEMPORARY_ROOT)
    [@output_path, @error_path].compact.each { |path| File.delete(path) if File.file?(path) }
  end
end

TicketDocumentsContract.new.run

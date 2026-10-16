# Checks author rejection and exact co-author trailer normalization.
class CommitIdentityContract
  AUTHOR_NAME = "Josh Austin"
  AUTHOR_EMAIL = "83935880+joshaustintech@users.noreply.github.com"
  COAUTHOR_TRAILER = "Co-authored-by: Codex <codex@openai.com>"
  TEMPORARY_PATH = "/tmp/fleek-commit-identity-#{Process.pid}"

  def run
    rejects_other_authors
    adds_and_normalizes_trailer
    puts "Commit identity contract: pass"
  ensure
    [message_path, output_path, error_path].each do |path|
      File.delete(path) if File.exist?(path)
    end
  end

  def rejects_other_authors
    File.write(message_path, "invalid author probe\n")
    status = self.class.run_hook("Wrong Author", "wrong@example.com", message_path)
    raise "commit hook accepted a different author" if status.success?
    raise "commit hook failure was unclear" unless File.read(error_path).include?("commit author must be Josh Austin")
  end

  def adds_and_normalizes_trailer
    File.write(message_path, "valid author probe\n\nCo-authored-by: Codex <noreply@openai.com>\n")
    status = self.class.run_hook(AUTHOR_NAME, AUTHOR_EMAIL, message_path)
    raise "commit hook rejected the configured author" unless status.success?
    verify_normalized_trailer(File.read(message_path))
  end

  def verify_normalized_trailer(message)
    raise "commit hook did not normalize the Codex trailer" unless message.include?(COAUTHOR_TRAILER)
    raise "commit hook left an incorrect Codex trailer" if message.include?("noreply@openai.com")
    raise "commit hook duplicated the Codex trailer" unless self.class.trailer_count(message) == 1
  end

  def message_path
    "#{TEMPORARY_PATH}.msg"
  end

  def output_path
    "#{TEMPORARY_PATH}.out"
  end

  def error_path
    "#{TEMPORARY_PATH}.err"
  end

  def self.run_hook(name, email, path)
    process_id = Process.spawn("env", "GIT_AUTHOR_NAME=#{name}", "GIT_AUTHOR_EMAIL=#{email}", ".githooks/commit-msg", path, out: "#{TEMPORARY_PATH}.out", err: "#{TEMPORARY_PATH}.err")
    _, status = Process.waitpid2(process_id)
    status
  end

  def self.trailer_count(message)
    count = 0
    message.each_line do |line|
      count += 1 if line.chomp == COAUTHOR_TRAILER
    end
    count
  end
end

CommitIdentityContract.new.run

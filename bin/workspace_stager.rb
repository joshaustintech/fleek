# frozen_string_literal: true

# :reek:IrresponsibleModule
class WorkspaceStager
  def self.copy(source, destination)
    process_id = Process.spawn("rsync", "-a", "--exclude=/.git", "--exclude=/dist",
      "--exclude=/build/mutation-*", "--exclude=/build/mutation-reference-cache", "#{source}/", destination,
      out: "/dev/null", err: "/dev/null")
    _, status = Process.waitpid2(process_id)
    status.success?
  end
end

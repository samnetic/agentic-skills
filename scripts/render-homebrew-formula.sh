#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"
SHA256="${2:-}"
OUTFILE="${3:-Formula/agentic-skills.rb}"

if [[ -z "$VERSION" || -z "$SHA256" ]]; then
  echo "Usage: $0 <version> <sha256> [outfile]" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTFILE")"

cat > "$OUTFILE" <<EOF
class AgenticSkills < Formula
  desc "Portable multi-agent skills toolkit for Claude Code, OpenCode, Cursor, and Codex"
  homepage "https://github.com/samnetic/agentic-skills"
  url "https://github.com/samnetic/agentic-skills/archive/refs/tags/v${VERSION}.tar.gz"
  sha256 "${SHA256}"
  license "MIT"

  depends_on "bash"

  def install
    libexec.install Dir["*"]
    (bin/"agentic-skills").write <<~EOS
      #!/usr/bin/env bash
      exec "#{libexec}/agentic-skills.sh" "\$@"
    EOS
  end

  test do
    output = shell_output("#{bin}/agentic-skills version").strip
    assert_equal "${VERSION}", output
  end
end
EOF

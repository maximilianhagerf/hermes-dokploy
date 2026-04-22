FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:${PATH}"

# Base tools. xz-utils needed by Hermes installer for Node.
# ripgrep + ffmpeg are optional Hermes extras; installing here since
# the installer runs apt without refreshing package lists.
RUN apt-get update && apt-get install -y \
    curl git ca-certificates bash sudo xz-utils ripgrep ffmpeg \
 && rm -rf /var/lib/apt/lists/*

# --- Hermes Agent (also installs uv + Python 3.11 + Node.js 22 + Playwright) ---
# Redirect stdin from /dev/null so the interactive setup wizard at the end
# of the installer exits cleanly instead of trying to read from a TTY.
RUN curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash < /dev/null || true

# --- Browser Harness ---
WORKDIR /root
RUN git clone https://github.com/browser-use/browser-harness \
 && cd browser-harness \
 && /root/.local/bin/uv tool install -e .

# --- Register Browser Harness as a Hermes skill ---
RUN mkdir -p /root/.hermes/skills/browser-harness \
 && ln -sf /root/browser-harness/SKILL.md /root/.hermes/skills/browser-harness/SKILL.md \
 && ln -sf /root/browser-harness/interaction-skills /root/.hermes/skills/browser-harness/interaction-skills \
 && ln -sf /root/browser-harness/domain-skills /root/.hermes/skills/browser-harness/domain-skills

# First-run script: writes config from env vars
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /root
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
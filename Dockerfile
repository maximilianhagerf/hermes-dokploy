FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:${PATH}"

# --- System packages (base tools + skill deps + gh from GitHub's repo) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl git ca-certificates bash sudo xz-utils ripgrep ffmpeg tesseract-ocr \
 && mkdir -p -m 755 /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
 && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
 && apt-get update \
 && apt-get install -y gh \
 && rm -rf /var/lib/apt/lists/*

# --- Hermes Agent (installs uv + Python 3.11 + Node.js 22 + Playwright) ---
# Redirect stdin so the interactive setup wizard exits on EOF. `|| true`
# allows the wizard's non-zero exit; the `test` lines then verify the
# install actually landed, so silent breakage still fails the build.
RUN curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh -o /tmp/hermes-install.sh \
 && bash /tmp/hermes-install.sh </dev/null || true \
 && rm /tmp/hermes-install.sh \
 && test -x /root/.local/bin/uv \
 && test -d /root/.hermes/hermes-agent \
 && echo "Hermes install verified."

# --- Python skill dependencies ---
RUN /root/.local/bin/uv pip install --system --break-system-packages \
      youtube-transcript-api \
      yt-dlp

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

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /root
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["hermes", "gateway", "run"]
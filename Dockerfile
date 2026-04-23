FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:${PATH}"

RUN apt-get update && apt-get install -y \
    curl git ca-certificates bash sudo xz-utils ripgrep ffmpeg \
 && rm -rf /var/lib/apt/lists/*

# --- Hermes Agent (installs uv + Python 3.11 + Node.js 22 + Playwright) ---
# Download script first, then run with stdin redirected so the interactive
# setup wizard at the end exits on EOF instead of hanging on /dev/tty.
# `|| true` allows the wizard's non-zero exit, but we verify critical bits
# landed on disk right after, so silent breakage fails the build.
RUN curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh -o /tmp/hermes-install.sh \
 && bash /tmp/hermes-install.sh </dev/null || true \
 && rm /tmp/hermes-install.sh \
 && test -x /root/.local/bin/uv \
 && test -d /root/.hermes/hermes-agent \
 && echo "Hermes install verified."

# --- Skill dependencies ---
# Keep this minimal. Add more only when a skill actually fails for lack of them.
RUN apt-get update && apt-get install -y --no-install-recommends \
    tesseract-ocr \
 && rm -rf /var/lib/apt/lists/*

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
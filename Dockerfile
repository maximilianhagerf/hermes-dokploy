FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:${PATH}"

# Base tools
RUN apt-get update && apt-get install -y \
    curl git ca-certificates bash sudo \
 && rm -rf /var/lib/apt/lists/*

# --- Hermes Agent ---
# NOTE: piping curl to bash. Review the script at the URL before building
# if you haven't already: raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh
RUN curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

# --- uv (Python package manager) ---
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

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

# First-run script: writes config from env vars if not already configured
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /root
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
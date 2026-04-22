# Deploying via Dokploy

In Dokploy, create a new Compose project, point it at your git repo (or paste the compose file), and set these three env vars in the UI:

OPENROUTER_API_KEY — your OpenRouter key
BROWSER_USE_API_KEY — your Browser Use Cloud key
HERMES_MODEL=openrouter/free

Deploy. Then to actually use Hermes, SSH into your VPS box and run:

```bash
docker exec -it hermes hermes
```

## Switching models later

Three tiers depending on how permanent the change is:
One-off test — inside the container, just run hermes with a flag or re-run hermes setup. Nothing persists past the next restart since the entrypoint rewrites config.

Semi-permanent — update HERMES_MODEL in Dokploy's env var UI, hit restart. Entrypoint picks up the new value.

Swap through openrouter/free → qwen/qwen3-coder:free → openai/gpt-oss-120b:free to see which handles the browser tool loop best, then graduate to anthropic/claude-opus-4.7 (or a cheaper paid tier like anthropic/claude-haiku-4-5 or anthropic/claude-sonnet-4.6 — both are meaningfully cheaper than Opus and usually plenty for agent work) once you know it works.

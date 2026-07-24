# story: e61s01
# Gateway hook template — copy directory to ~/.hermes/hooks/session-log/
# Docs: https://hermes-agent.nousresearch.com/docs/user-guide/features/hooks

async def handle(event_type: str, context: dict) -> None:
    """Observer-only; errors are caught by Hermes and never crash the agent."""
    _ = event_type, context

# story: e61s01
# Plugin hook template — install as a Hermes plugin (CLI + gateway).
# Docs: https://hermes-agent.nousresearch.com/docs/developer-guide/plugins

DANGEROUS = {"terminal", "write_file", "patch"}


def warn_dangerous(tool_name, **kwargs):
    if tool_name in DANGEROUS:
        print(f"⚠ Executing potentially sensitive tool: {tool_name}")


def register(ctx):
    ctx.register_hook("pre_tool_call", warn_dangerous)

# Project README Template

Combined from dbader/readme-template and jehna/readme-best-practices. No TOC.

## Navigation

| Lines | Section |
|-------|---------|
| 1 | Title |
| 5–40 | Navigation |
| 41–42 | Sections |
| 43–54 | 1. Title + Badges |
| 55–60 | 2. Tagline |
| 61–64 | 3. Description |
| 65–67 | 4. Prerequisites |
| 68–75 | Prerequisites |
| 76–78 | 5. Installation |
| 79–89 | Installation |
| 90–92 | 6. Usage |
| 93–102 | Usage |
| 103–105 | 7. Features |
| 106–113 | Features |
| 114–116 | 8. Configuration |
| 117–125 | Configuration |
| 126–128 | 9. Development Setup |
| 129–139 | Development |
| 140–142 | 10. Running Tests |
| 143–152 | Tests |
| 153–155 | 11. Contributing |
| 156–164 | Contributing |
| 165–167 | 12. Changelog |
| 168–172 | Changelog |
| 173–175 | 13. Links |
| 176–181 | Links |
| 182–184 | 14. License |
| 185–191 | License |
| 192–194 | 15. Credits (optional) |
| 195–199 | Credits |
| 200–202 | Verify |

## Sections

### 1. Title + Badges

```markdown
# Project Name

![License](https://img.shields.io/badge/License-MIT-yellow.svg)
![npm version](https://img.shields.io/npm/v/your-package.svg)

```

Fill badges from CLAUDE.md stack info if available. Default to license + version badges.

### 2. Tagline

```markdown
> One-line description of what this project does and why it matters.
```

### 3. Description

2-3 paragraphs: what problem it solves, who it's for, and what makes it different.

### 4. Prerequisites

```markdown
## Prerequisites

- **Runtime**: Node.js v18+ (from CLAUDE.md)
- **Package manager**: npm (or pnpm/yarn)
```

Auto-fill from CLAUDE.md commands section when possible.

### 5. Installation

```markdown
## Installation

```bash
npm install -g your-package
# or
npx your-package
```
```

Prefer npx one-shot if applicable; list global install as alternative.

### 6. Usage

```markdown
## Usage

```bash
your-command --help
your-command do-something
```
```

Include the most common 1-2 commands. Link to full docs if they exist.

### 7. Features

```markdown
## Features

- Feature 1: short description
- Feature 2: short description
```

3-6 bullet points of what the project does. Derived from the project's purpose.

### 8. Configuration

```markdown
## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `VAR_NAME` | `value` | What it controls |
```

Use `TODO` markers if unknown.

### 9. Development Setup

```markdown
## Development

```bash
git clone <repo-url>
cd project
npm install
```
```

Auto-fill from CLAUDE.md `Run` and `Build` commands.

### 10. Running Tests

```markdown
## Tests

```bash
npm test
npm run lint
```
```

Auto-fill from CLAUDE.md `Test` and `Lint` commands.

### 11. Contributing

```markdown
## Contributing

1. Fork the repo.
2. Create a feature branch (`git checkout -b feature/my-thing`).
3. Commit changes (`git commit -am 'Add my thing'`).
4. Push (`git push origin feature/my-thing`).
5. Open a Pull Request.
```

### 12. Changelog

```markdown
## Changelog

See [CHANGELOG.md](../../CHANGELOG.md) or [Releases](https://github.com/user/repo/releases).
```

### 13. Links

```markdown
## Links

- Repository: https://github.com/user/repo
- Issue tracker: https://github.com/user/repo/issues
```

### 14. License

```markdown
## License

MIT — see [LICENSE](../../LICENSE) for details.
```

Detect from CLAUDE.md or project LICENSE file.

### 15. Credits (optional)

```markdown
## Credits

Built with [bigpowers](https://www.npmjs.com/package/bigpowers).
```

## Verify

After generation, run: `grep -c "^## " README.md` — expect ≥ 7 section headings.

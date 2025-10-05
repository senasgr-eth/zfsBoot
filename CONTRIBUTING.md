# Contributing to NSBoot

Thank you for your interest in contributing to NSBoot! This document provides guidelines and instructions for contributing.

## 🤝 Code of Conduct

By participating in this project, you agree to:
- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## 🎯 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title** and description
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Environment details** (OS, version, hardware)
- **Logs** if applicable

**Bug Report Template:**
```markdown
**Description:**
Brief description of the bug

**Steps to Reproduce:**
1. Step one
2. Step two
3. Step three

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Environment:**
- OS: Ubuntu 22.04
- NSBoot Version: 4.1.0
- Docker Version: 24.0.0

**Logs:**
```
Paste relevant logs here
```
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title** and detailed description
- **Use case** explaining why this would be useful
- **Possible implementation** if you have ideas

### Pull Requests

1. **Fork** the repository
2. **Create a branch** from `develop`:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Make your changes** following our coding standards
4. **Test** your changes thoroughly
5. **Commit** with clear messages:
   ```bash
   git commit -m "feat: add amazing feature"
   ```
6. **Push** to your fork:
   ```bash
   git push origin feature/amazing-feature
   ```
7. **Open a Pull Request** against `develop` branch

## 📝 Development Guidelines

### Branch Naming

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Adding tests
- `chore/` - Maintenance tasks

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance

**Examples:**
```
feat(api): add image upload endpoint
fix(ui): resolve dark mode toggle issue
docs(readme): update installation instructions
```

### Code Style

#### Lua
- Use 4 spaces for indentation
- Follow [Lua Style Guide](https://github.com/luarocks/lua-style-guide)
- Add comments for complex logic
- Use meaningful variable names

```lua
-- Good
local function get_system_info()
    local info = {
        version = "4.1.0",
        uptime = get_uptime()
    }
    return info
end

-- Bad
local function gsi()
    local i = {v = "4.1.0", u = gu()}
    return i
end
```

#### Vue.js/TypeScript
- Use 2 spaces for indentation
- Follow [Vue.js Style Guide](https://vuejs.org/style-guide/)
- Use TypeScript for type safety
- Use Composition API with `<script setup>`

```vue
<!-- Good -->
<script setup lang="ts">
import { ref, computed } from 'vue'

const count = ref(0)
const doubled = computed(() => count.value * 2)
</script>

<!-- Avoid -->
<script>
export default {
  data() {
    return { count: 0 }
  }
}
</script>
```

#### Shell Scripts
- Use `#!/bin/bash` shebang
- Use `set -e` for error handling
- Add comments explaining complex commands
- Use meaningful variable names in UPPER_CASE

```bash
#!/bin/bash
set -e

POOL_NAME="${POOL_NAME:-nsboot0}"
ARC_MAX="${ARC_MAX:-8589934592}"

echo "Configuring ZFS pool: $POOL_NAME"
```

### Testing

#### Frontend Tests
```bash
cd frontend
npm run test:unit      # Unit tests
npm run test:e2e       # E2E tests
npm run lint           # Linting
```

#### Lua Tests
```bash
lua test/run_tests.lua
```

#### Integration Tests
```bash
./scripts/test-integration.sh
```

### Documentation

- Update documentation for any user-facing changes
- Add JSDoc/LuaDoc comments for functions
- Update API documentation if endpoints change
- Include examples in documentation

## 🏗️ Project Structure

```
NSBoot-/
├── api/                    # Lua API layer
│   ├── init.lua           # Core API functions
│   └── router.lua         # Route handling
├── bin/                   # Executable scripts
│   ├── client.lua
│   ├── server.lua
│   └── nsbctl.lua
├── docs/                  # MkDocs documentation
│   ├── getting-started/
│   ├── user-guide/
│   └── api/
├── frontend/              # Vue.js frontend
│   ├── src/
│   │   ├── components/
│   │   ├── views/
│   │   ├── stores/
│   │   └── services/
│   └── package.json
├── monitoring/            # Monitoring configs
│   ├── prometheus.yml
│   └── grafana/
├── nginx/                 # Nginx configurations
├── scripts/               # Helper scripts
│   ├── zfs-tune.sh
│   ├── benchmark.sh
│   └── setup-monitoring.sh
├── src/                   # Core Lua source
│   └── cfg.lua
├── Dockerfile
├── docker-compose.yml
└── README.md
```

## 🧪 Testing Your Changes

### Local Testing

1. **Build Docker image:**
   ```bash
   docker build -t nsboot:test .
   ```

2. **Run locally:**
   ```bash
   docker-compose up -d
   ```

3. **Test the web UI:**
   ```bash
   open http://localhost
   ```

4. **Check logs:**
   ```bash
   docker-compose logs -f
   ```

### Manual Testing Checklist

- [ ] Web UI loads correctly
- [ ] All navigation links work
- [ ] API endpoints respond correctly
- [ ] Dark mode toggles properly
- [ ] Mobile responsive design works
- [ ] No console errors
- [ ] Performance is acceptable

## 📚 Resources

- [Vue.js Documentation](https://vuejs.org/)
- [Lua Reference Manual](https://www.lua.org/manual/5.3/)
- [OpenResty Documentation](https://openresty.org/)
- [ZFS Documentation](https://openzfs.github.io/openzfs-docs/)
- [Docker Documentation](https://docs.docker.com/)

## 🎓 Learning Resources

New to the project? Start here:

1. **Read the documentation**: [docs/](docs/)
2. **Explore the codebase**: Start with `api/init.lua` and `frontend/src/App.vue`
3. **Run locally**: Follow the Quick Start guide
4. **Pick a good first issue**: Look for `good-first-issue` label
5. **Ask questions**: Use GitHub Discussions

## 🏆 Recognition

Contributors will be:
- Listed in the README
- Mentioned in release notes
- Credited in documentation

## 📞 Getting Help

- **GitHub Discussions**: For questions and discussions
- **GitHub Issues**: For bugs and feature requests
- **Discord**: Join our community server (coming soon)

## 📄 License

By contributing, you agree that your contributions will be licensed under the AGPL-3.0 License.

---

Thank you for contributing to NSBoot! 🚀

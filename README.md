# Erbee

**Erbee** is a simple gem that generates Mermaid-based ER diagrams for your existing Rails or ActiveRecord projects.  
You run a single command, get a `.md` file (in Mermaid format), then convert it to `.svg` via Docker if you wish.

---

## 1. Quick Installation & Setup

1. **Add Erbee to your Gemfile** (in your existing project):
  ```ruby
  # Gemfile
  gem 'erbee'
  ```
2. **Install the gem**:
  ```bash
  bundle install
  ```
3. **Run the CLI (inside your project directory)**:
  ```bash
  bundle exec erbee User --depth=1
  ```
  - This outputs a Mermaid .md file (e.g. er_diagram.md) with your database entities and associations.

## 2. Converting Mermaid .md to .svg

To view the diagram as an SVG, you can use Docker and the mermaid-cli container:

```bash
# Example: Using the minlag/mermaid-cli Docker image
# - Mount the current directory so Mermaid can read/write files
docker run -it --rm \
-v "$PWD":/data \
minlag/mermaid-cli \
-i er_diagram.md -o er_diagram.svg
```

Now you have er_diagram.svg in your project folder—open it in any browser or image viewer.

## 3. View the SVG in Your Browser

Depending on your OS, run one of these commands:
- **macOS**:
```bash
open er_diagram.svg
```
- **Linux**:
```bash
xdg-open er_diagram.svg
```

After that, your browser (or default viewer) should display the diagram.

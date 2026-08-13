set default-list := true

add-external repo:
    #!/usr/bin/env bash
    set -euo pipefail
    name=$(basename "{{repo}}" .git)
    if [ -d "external/$name" ]; then
        echo "Error: Directory external/$name already exists." >&2
        exit 1
    fi
    echo "Adding submodule {{repo}} to external/$name..."
    git submodule add "{{repo}}" "external/$name"

    if grep -q "^_build-external-$name:" Justfile; then
        echo "Recipe build-external-$name already exists in Justfile."
    else
        echo "Adding build-external-$name recipe to Justfile..."
        printf '%s\n' "" \
            "_build-external-$name:" \
            "    #!/usr/bin/env bash" \
            "    set -euo pipefail" \
            "    rm -rf skills/$name" \
            "    mkdir -p skills/$name/skills" \
            "    if [ -d \"external/$name/.claude-plugin\" ]; then" \
            "        cp -r \"external/$name/.claude-plugin\" \"skills/$name/\"" \
            "    fi" \
            "    for dir in \"external/$name/skills\"/*; do" \
            "        if [ -d \"\$dir\" ] && [ -f \"\$dir/SKILL.md\" ]; then" \
            "            skill_name=\$(basename \"\$dir\")" \
            "            echo \"Copying skill: \$skill_name\"" \
            "            cp -r \"\$dir\" \"skills/$name/skills/\$skill_name\"" \
            "        fi" \
            "    done" >> Justfile
    fi

    if jq --arg name "$name" '.plugins[] | select(.name == $name)' .claude-plugin/marketplace.json | grep -q .; then
        echo "Plugin $name already registered in .claude-plugin/marketplace.json"
    else
        echo "Registering plugin $name in .claude-plugin/marketplace.json..."
        jq --arg name "$name" --arg source "./skills/$name" '.plugins += [{"name": $name, "source": $source}]' .claude-plugin/marketplace.json > .claude-plugin/marketplace.tmp && mv .claude-plugin/marketplace.tmp .claude-plugin/marketplace.json
    fi

remove-external repo:
    #!/usr/bin/env bash
    set -euo pipefail
    
    if [ ! -d "external/{{repo}}" ]; then
        echo "Error: Directory external/{{repo}} does not exist." >&2
        exit 1
    fi

    echo "De-initializing and removing submodule external/{{repo}}..."
    git submodule deinit -f "external/{{repo}}" || true
    git rm -f "external/{{repo}}" || true
    rm -rf ".git/modules/external/{{repo}}"

    echo "Removing _build-external-{{repo}} recipe from Justfile..."
    node -e "
    const fs = require('fs');
    const repo = '{{repo}}';
    const lines = fs.readFileSync('Justfile', 'utf8').split('\n');
    const out = [];
    let skipping = false;
    for (const line of lines) {
        if (line.startsWith('_build-external-' + repo + ':')) {
            skipping = true;
            continue;
        }
        if (skipping) {
            if (!line.trim() || line.startsWith(' ') || line.startswith('\t')) {
                continue;
            } else {
                skipping = false;
            }
        }
        out.push(line);
    }
    fs.writeFileSync('Justfile', out.join('\n'));
    "

    echo "Removing plugin {{repo}} from .claude-plugin/marketplace.json..."
    jq --arg name "{{repo}}" '.plugins |= map(select(.name != $name))' .claude-plugin/marketplace.json > .claude-plugin/marketplace.tmp && mv .claude-plugin/marketplace.tmp .claude-plugin/marketplace.json
    
    echo "Successfully removed external module: {{repo}}"

list-external:
    #!/usr/bin/env bash
    set -euo pipefail
    for dir in external/*; do
        if [ -d "$dir" ]; then
            basename "$dir"
        fi
    done

update-external:
    git submodule update --init --recursive

build-external module="":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -z "{{module}}" ]; then
        for dir in external/*; do
            if [ -d "$dir" ]; then
                mod=$(basename "$dir")
                echo "Building external module: $mod"
                just _build-external-"$mod"
            fi
        done
    else
        just _build-external-"{{module}}"
    fi

_build-external-taste-skill:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf skills/taste-skill
    mkdir -p skills/taste-skill/skills
    if [ -d "external/taste-skill/.claude-plugin" ]; then
        cp -r "external/taste-skill/.claude-plugin" "skills/taste-skill/"
    fi
    for dir in "external/taste-skill/skills"/*; do
        if [ -d "$dir" ] && [ -f "$dir/SKILL.md" ]; then
            name=$(basename "$dir")
            echo "Copying skill: $name"
            cp -r "$dir" "skills/taste-skill/skills/$name"
        fi
    done

_build-external-mattpocock-skills:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf skills/mattpocock-skills
    mkdir -p skills/mattpocock-skills/skills
    if [ -d "external/mattpocock-skills/.claude-plugin" ]; then
        cp -r "external/mattpocock-skills/.claude-plugin" "skills/mattpocock-skills/"
    fi
    for category in productivity engineering; do
        for dir in "external/mattpocock-skills/skills/$category"/*; do
            if [ -d "$dir" ] && [ -f "$dir/SKILL.md" ]; then
                name=$(basename "$dir")
                echo "Copying skill: $name (from $category)"
                cp -r "$dir" "skills/mattpocock-skills/skills/$name"
            fi
        done
    done

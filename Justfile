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
            "    mkdir -p skills/$name" \
            "    for dir in \"external/$name/skills/\$category\"/*; do" \
            "        if [ -d \"\$dir\" ] && [ -f \"\$dir/SKILL.md\" ]; then" \
            "            name=\$(basename \"\$dir\")" \
            "            echo \"Copying skill: \$name (from \$category)\"" \
            "            rm -rf \"skills/$name/\$name\"" \
            "            cp -r \"\$dir\" \"skills/$name/\$name\"" \
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

list-externals:
    #!/usr/bin/env bash
    set -euo pipefail
    for dir in external/*; do
        if [ -d "$dir" ]; then
            basename "$dir"
        fi
    done

update-external:
    git submodule update --init --recursive

build-external module:
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

# Dennis' Skill Collections

This repository manages skills for AI agents, tailored for [OMP](https://github.com/can1357/oh-my-pi).
It uses git submodules to pin skills from other repositories down to commits for dependency management.

> A marketplace is a list of pointers; the code that runs on your machine is whatever the plugin entries resolve to. There is no signing, no sandbox, no central review. A catalog can ship a plugin that registers hooks firing on every prompt or custom tools the model calls without confirmation.
> 
> -- [oh-my-pi](https://omp.sh/docs/marketplace#:~:text=Trust-,A,confirmation)

## Overview

- **Add skills**: Download skills from other repositories.
- **Build skills**: Copy skills to the local `skills` folder.
- **Remove skills**: Delete skills you do not need.

## Instructions

Use `just` commands to manage these skills.

### 1. Download and Update Skills
Download or update the repository submodules:
```bash
just update-external
```

### 2. Add a New Repository
Add an external repository to this manager:
```bash
just add-external <git-repository-url>
```
*Note: This command writes a build recipe in the `Justfile`. You might need to adjust the new build recipe before proceeding to step 3.*

### 3. Build the Skills
Copy all downloaded skills to the local `skills` folder:
```bash
just build-external
```
To copy only one module:
```bash
just build-external <module-name>
```

### 4. List Installed Repositories
Show all installed skill repositories:
```bash
just list-external
```

### 5. Remove a Repository
Remove an external repository from this manager:
```bash
just remove-external <repository-name>
```


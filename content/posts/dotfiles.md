---
title: "Dotfiles"
summary: How to automate your system installs and keep your application configuration in dotfiles
date: 2023-10-02
tags: [ "Linux" ]
draft: false
---

# Introduction

Dotfiles are user-specific application configuration files that your filesystem does not display by default, and they
start with a dot (ie `~/.gitconfig`). It is common to host them in a git repository in order to keep a consistent
environment across machines. We are going to automate some of our application installs and symlink our system dotfiles
to a git repository.

# Repository structure and Dotfiles

Firstly initialize a git repository, ie my GitHub repo has the following structure.

> A handy linux package is `tree`, a recursive directory listing program that lists contents in a tree-like format. I've
> used it with the option `-a` which prints all files including dotfiles, and `-I` which ignores the given
> directories. The command used for the tree generated bellow is `tree -a -I .git`.

```markdown
.
├── git
│ └── .gitconfig
├── .idea
│ ├── dotfiles.iml
│ ├── .gitignore
│ ├── modules.xml
│ ├── vcs.xml
│ └── workspace.xml
├── install.sh
├── LICENSE
├── logiops
│ └── logid.cfg
├── pop
│ └── .config
│ └── pop-shell
│ └── config.json
├── scripts
│ ├── apts.sh
│ ├── directs.sh
│ ├── flatpaks.sh
│ └── snaps.sh
└── zsh
└── .zshrc
```

At the top level we have the `install.sh` file which is the entry point of our script, and a directory for each of the
configuration files. Let's have a deeper look at `install.sh`.

```bash
#!/bin/bash

if [ ! -f /usr/bin/stow ]
then
	sudo apt-get install stow
fi

if [ "$1" == "apps" ]
then
	source ./scripts/apts.sh
	source ./scripts/directs.sh
	source ./scripts/snaps.sh
	source ./scripts/flatpaks.sh
fi

rm ../.zshrc \
	../.config/pop-shell/config.json \
	../.gitconfig \
	/etc/logid.cfg

stow zsh \
	pop \
	git

stow -t /etc logiops

echo "Done!"
```

The first line of the script is a shebang - it tells our system what interpreter to use. Afterward we are
going to check if stow is installed. Stow is a symlink farm manager that was originally used to manage software
packages. Despite that not being the case today - as there are more sophisticated package managers available - it is
still being used to manage configuration files in a controlled and organized way, exactly what we need!

Using stow is quite simple, just append the configuration file you want to symlink after the command and voilà! If the
directory you want to symlink from is not the working dir you can change that with the `- t` option. The way stow
symlinks is quite interesting, be sure to read the [man page](https://linux.die.net/man/8/stow).

The dotfiles are application specific. Copy the respective file and customize it to your needs.

# Installation automation

Installing apps in a fresh system can get tedious, shouldn't we automate much of that with a simple script?

```bash
#!/bin/bash

echo "Installing snapd..."
apt install -y snapd

echo "Installing speedtest..."
apt install -y speedtest-cli

echo "Installing restic..."
apt install -y restic

echo "Installing curl..."
apt install -y curl

echo "Installing httpie"
apt install -y httpie

echo "Installing termius..."
curl -OL https://www.termius.com/download/linux/Termius.deb
dpkg -i Termius.deb

# ...
```

The applications will be installed serially, just like they would when installing them standalone in the terminal. Make
sure to provide any input that an app might need (ie `- y` for apt packages). You can also test them
in a [Multipass](https://multipass.run/) virtual machine.

# Repository

- https://github.com/xrazis/dotfiles/

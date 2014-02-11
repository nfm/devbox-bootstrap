#!/usr/bin/env bash

RELEASE=`lsb_release -sc`
LATEST_LTS_RELEASE="precise"

# Add PPAs
# - Firefox
sudo add-apt-repository -y ppa:ubuntu-mozilla-daily/firefox-aurora &> /dev/null

# - Chrome
sudo sh -c "echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list"
wget --quiet -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

# - Docker
sudo sh -c "echo 'deb https://get.docker.io/ubuntu docker main' > /etc/apt/sources.list.d/docker.list"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9 &> /dev/null

# - Dropbox
sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E &> /dev/null
sudo add-apt-repository "deb http://linux.dropbox.com/ubuntu ${RELEASE} main"

# - HipChat
sudo sh -c "echo 'deb http://downloads.hipchat.com/linux/apt stable main' > /etc/apt/sources.list.d/atlassian-hipchat.list"
wget --quiet -O - https://www.hipchat.com/keys/hipchat-linux.key | sudo apt-key add -

# - Heroku toolbelt
sudo sh -c "echo 'deb http://toolbelt.heroku.com/ubuntu ./' > /etc/apt/sources.list.d/heroku.list"
wget --quiet -O - https://toolbelt.heroku.com/apt/release.key | sudo apt-key add -

# - Postgresql
sudo sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ ${LATEST_LTS_RELEASE}-pgdg main' > /etc/apt/sources.list.d/postgresql.list"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update apt and install packages
sudo apt-get update -q=2
sudo apt-get install -q=2 -y --force-yes build-essential zlib1g-dev libssl-dev libreadline-dev curl git-core vim zsh firefox\
  postgresql-9.3 heroku-toolbelt redis-server gnome-shell htop memcached dropbox google-chrome-beta tmux libtcmalloc-minimal4\
  password-gorilla

# Clone dotfiles, if necessary
if [[ ! -e ~/.dotfiles ]]
then
  git clone git://github.com/nfm/dotfiles.git ~/.dotfiles
	~/.dotfiles/bootstrap.sh
fi

# Set up rbenv and ruby-build, install ruby
if [[ ! -e ~/.rbenv ]]
then
  git clone git://github.com/sstephenson/rbenv.git ~/.rbenv
 	mkdir -p ~/.rbenv/plugins/ruby-build
  git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
  ~/.rbenv/bin/rbenv install 2.1.0
fi

# Set up Solarized colors for gnome-terminal
git clone git://github.com/sigurdga/gnome-terminal-colors-solarized.git /tmp/gnome-terminal-colors-solarized
cd /tmp/gnome-terminal-colors-solarized && ./solarize dark

# Install vundle and vim plugins
if [[ ! -e ~/.vim/bundle/vundle ]]
then
	mkdir -p ~/.vim/bundle
	git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
	vim +BundleInstall +qall
fi

# Use zsh
ZSH=`which zsh`
if [[ ${SHELL} != ${ZSH} ]]
then
	chsh --shell ${ZSH}
fi

echo "Done. You'll need to:"
echo "* Log out and back in to change your shell and desktop environment"
echo "* Manually copy in SSH keys and config"
echo "* Manually copy in files for ~/.local/bin"

#!/usr/bin/env bash

RELEASE=`lsb_release -sc`
LATEST_LTS_RELEASE="bionic"
POSTGRES_VERSION="9.6"
RUBY_VERSION="2.5.3"

# Add PPAs
# - Firefox
sudo add-apt-repository -y ppa:ubuntu-mozilla-daily/ppa &> /dev/null

# - Chrome
sudo sh -c "echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list"
wget --quiet -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

# - Dropbox
sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E &> /dev/null
sudo add-apt-repository "deb http://linux.dropbox.com/ubuntu ${RELEASE} main"

# - Heroku toolbelt
sudo sh -c "echo 'deb http://toolbelt.heroku.com/ubuntu ./' > /etc/apt/sources.list.d/heroku.list"
wget --quiet -O - https://toolbelt.heroku.com/apt/release.key | sudo apt-key add -

# - Postgresql
sudo sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ ${LATEST_LTS_RELEASE}-pgdg main' > /etc/apt/sources.list.d/postgresql.list"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# - Neovim
sudo add-apt-repository ppa:neovim-ppa/unstable

# - Git
sudo add-apt-repository ppa:git-core/ppa

# - Yarn
sudo apt-key adv --keyserver pgp.mit.edu --recv D101F7899D41F3C3
echo "deb http://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Update apt and install packages
THESILVERSEARCHER="automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev"
NOKOGIRI="libxml2-dev libxslt1-dev"
POSTGRESQL="postgresql-${POSTGRES_VERSION} postgresql-contrib-${POSTGRES_VERSION} libpq-dev"
YOUCOMPLETEME="cmake python-dev"
DEJA_DUP_S3_STORAGE="python-boto python-cloudfiles dconf-editor"
NEOVIM="neovim xclip python-dev python-pip python3-dev python3-pip"
PHOENIX="inotify-tools"
sudo apt-get update -q=2
sudo apt-get install -q=2 -y --force-yes build-essential zlib1g-dev libssl-dev libreadline-dev curl git-core vim zsh firefox-trunk\
  heroku-toolbelt redis-server htop memcached dropbox google-chrome-beta tmux libjemalloc1\
  password-gorilla msttcorefonts imagemagick colordiff libsqlite3-dev exuberant-ctags flashplugin-installer\
  ${THESILVERSEARCHER} ${NOKOGIRI} ${POSTGRESQL} ${YOUCOMPLETEME} ${DEJA_DUP_S3_STORAGE} ${NEOVIM} ${PHOENIX}

# Install neovim python package
pip install --user neovim

# Configure postgresql
sudo sh -c "echo 'local all all trust\nhost all all 127.0.0.1/32 trust' > /etc/postgresql/${POSTGRES_VERSION}/main/pg_hba.conf"
sudo -u postgres psql -c "CREATE ROLE `whoami` SUPERUSER LOGIN;"
sudo service postgresql restart

# Configure deja-dup backup location
gsettings set org.gnome.DejaDup.S3 bucket 'nfm-backups'

# Clone dotfiles, if necessary
if [[ ! -e ~/.dotfiles ]]
then
  git clone git://github.com/nfm/dotfiles.git ~/.dotfiles
	~/.dotfiles/bootstrap.sh
fi

# Install rubies using ruby-install
if [[ ! -e ~/.rubies ]]
then
  ~/.local/bin/ruby-install ruby ${RUBY_VERSION} 
  ~/.local/bin/chruby-exec ${RUBY_VERSION} -- gem install bundler gem-ripper-tags gem-browse
fi

# Set up nvm, install node
if [[ ! -e ~/.nvm ]]
then
  git clone https://github.com/creationix/nvm.git ~/.nvm
  source ~/.nvm/nvm.sh
  nvm install 5.11.0
  npm install -g diff-so-fancy
fi

# Set up Solarized colors for gnome-terminal
git clone git://github.com/sigurdga/gnome-terminal-colors-solarized.git /tmp/gnome-terminal-colors-solarized
cd /tmp/gnome-terminal-colors-solarized && ./set_dark.sh

# Install vundle and vim plugins
if [[ ! -e ~/.vim/bundle/vundle ]]
then
	mkdir -p ~/.vim/bundle
	git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
	vim +PluginInstall +qall
fi

# Use zsh
ZSH=`which zsh`
if [[ ${SHELL} != ${ZSH} ]]
then
	chsh --shell ${ZSH}
fi

# Enable and configure workspaces
gsettings set org.compiz.core:/org/compiz/profiles/unity/plugins/core/ hsize 1
gsettings set org.compiz.core:/org/compiz/profiles/unity/plugins/core/ vsize 4

# Increase the number of available inotify watchers
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

echo "Done. You'll need to:"
echo "* Log out and back in to change your shell and desktop environment"
echo "* Set DNS servers to 8.8.4.4 and 8.8.8.8"
echo "* Manually copy in SSH keys and config"
echo "* Manually copy in GPG keys"
echo "* Run dropbox to download and configure dropbox"
echo "* Set up backups (http://blog.domenech.org/2013/01/backing-up-ubuntu-using-deja-dup-backup-and-aws-s3.html) (ignore Dropbox, downloads, tmp, .rubies, .gem, .berkshelf, .cache, .dropbox, .dropbox-dist, .npm, .nvm, .vim/bundle, .heroku, possibly others!)"
echo "* Install watchman (http://choorucode.com/2015/02/10/how-to-install-and-use-watchman/)"
echo "* Configure compiz config settings to change the Ubuntu Unity plugin edge stop velocity to not block the mouse from moving between monitors when trying to reveal the launcher with the mouse"

#!/usr/bin/env bash

set -x
set -e

RELEASE=`lsb_release -sc`
LATEST_LTS_RELEASE="bionic"
POSTGRES_VERSION="9.6"
RUBY_VERSION="2.5.3"
NODE_VERSION="11.6.0"

function add_apt_repository {
  sudo add-apt-repository --yes --no-update $1 &> /dev/null
}

# Don't run this script as root, doing so will result in files being owned by
# root that shouldn't be. We call out to sudo where necessary.
if [[ `whoami` = 'root' ]]
then
  echo "Don't run this script as root"
  exit 1
fi

sudo apt update && sudo apt install -y wget curl apt-transport-https ca-certificates software-properties-common

# Add PPAs
# - Firefox
add_apt_repository ppa:ubuntu-mozilla-daily/ppa

# - Chrome
sudo sh -c "echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome-beta.list"
wget --quiet -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

# - Heroku toolbelt
sudo sh -c "echo 'deb http://toolbelt.heroku.com/ubuntu ./' > /etc/apt/sources.list.d/heroku.list"
wget --quiet -O - https://toolbelt.heroku.com/apt/release.key | sudo apt-key add -

# - Postgresql
sudo sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ ${LATEST_LTS_RELEASE}-pgdg main' > /etc/apt/sources.list.d/postgresql.list"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# - Neovim
add_apt_repository ppa:neovim-ppa/unstable

# - Git
add_apt_repository ppa:git-core/ppa

# - Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# - VScode
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

# - Insync

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ACCAF35C
echo "deb http://apt.insynchq.com/ubuntu ${RELEASE} non-free contrib" | sudo tee /etc/apt/sources.list.d/insync.list

# - Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# At the time of writing, docker for cosmic was unavailable, see https://github.com/docker/for-linux/issues/442
sudo sh -c "echo 'deb [arch=amd64] https://download.docker.com/linux/ubuntu ${LATEST_LTS_RELEASE} stable' > /etc/apt/sources.list.d/docker.list"

# Update apt and install packages
THESILVERSEARCHER="automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev"
NOKOGIRI="libxml2-dev libxslt1-dev"
POSTGRESQL="postgresql-${POSTGRES_VERSION} postgresql-contrib-${POSTGRES_VERSION} libpq-dev"
YOUCOMPLETEME="cmake python-dev"
DEJA_DUP_S3_STORAGE="python-boto python-cloudfiles dconf-editor"
NEOVIM="neovim xclip python-dev python-pip python3-dev python3-pip"
PHOENIX="inotify-tools"
VSCODE="apt-transport-https"
sudo apt update --quiet
sudo apt install --quiet --yes build-essential zlib1g-dev libssl-dev libreadline-dev curl git-core vim zsh firefox-trunk\
  heroku-toolbelt redis-server htop memcached google-chrome-beta tmux libjemalloc2\
  password-gorilla msttcorefonts imagemagick colordiff libsqlite3-dev exuberant-ctags code insync docker-ce yarn\
  ${THESILVERSEARCHER} ${NOKOGIRI} ${POSTGRESQL} ${YOUCOMPLETEME} ${DEJA_DUP_S3_STORAGE} ${NEOVIM} ${PHOENIX} ${VSCODE}

# Install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Install neovim python package
pip install --user neovim

# Configure postgresql
sudo sh -c "echo 'local all all trust\nhost all all 127.0.0.1/32 trust' > /etc/postgresql/${POSTGRES_VERSION}/main/pg_hba.conf"
sudo -u postgres psql -c "DROP ROLE IF EXISTS `whoami`; CREATE ROLE `whoami` SUPERUSER LOGIN;"
sudo service postgresql restart

# Allow docker to be run as non-root
sudo usermod -aG docker $USER

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
  nvm install ${NODE_VERSION}
  npm install -g diff-so-fancy
fi

# Set up Solarized colors for gnome-terminal
git clone git://github.com/sigurdga/gnome-terminal-colors-solarized.git /tmp/gnome-terminal-colors-solarized
cd /tmp/gnome-terminal-colors-solarized && ./set_dark.sh

# Install vundle and vim plugins
VUNDLE_DIR="~/.vim/bundle/Vundle.vim"
if [[ ! -e ${VUNDLE_DIR} ]]
then
	mkdir -p ~/.vim/bundle
	git clone https://github.com/gmarik/Vundle.vim.git ${VUNDLE_DIR}
	vim +PluginInstall +qall
fi

# Use zsh
ZSH=`which zsh`
if [[ ${SHELL} != ${ZSH} ]]
then
	chsh --shell ${ZSH}
fi

# Disable crazy default Mac behaviour of touchpad so that right-click behaves traditionally
# See https://wayland.freedesktop.org/libinput/doc/1.11.3/clickpad_softbuttons.html for details
gsettings set org.gnome.desktop.peripherals.touchpad click-method areas

# Autohide the dock when there are fullscreen windows
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false

# Increase the number of available inotify watchers
echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

echo "Done. You'll need to:"
echo "* Log out and back in to change your shell and desktop environment"
echo "* Manually copy in SSH keys and config"
echo "* Manually copy in GPG keys"
echo "* Set up backups (http://blog.domenech.org/2013/01/backing-up-ubuntu-using-deja-dup-backup-and-aws-s3.html) (ignore downloads, tmp, .rubies, .gem, .berkshelf, .cache, .npm, .nvm, .vim/bundle, .heroku, possibly others!)"
echo "* Configure compiz config settings to change the Ubuntu Unity plugin edge stop velocity to not block the mouse from moving between monitors when trying to reveal the launcher with the mouse"

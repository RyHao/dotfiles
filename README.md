#### Set yarn global bin

    $ yarn config set prefix ~/.yarn

#### Set zsh to default

    $ sudo sh -c "echo $(which zsh) >> /etc/shells" 
    $ chsh -s $(which zsh)

#### Install java 8 via homebrew    

    $ brew tap caskroom/versions

    $ brew cask install java8

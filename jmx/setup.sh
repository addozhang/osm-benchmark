#!/bin/bash

set -aueo pipefail

# install jdk via sdkman
sudo apt install -y unzip zip
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk version
sdk install java 8.0.352-zulu
java -version

# jmeter
curl https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-5.5.zip -o $HOME/apache-jmeter-5.5.zip
unzip $HOME/apache-jmeter-5.5.zip -d $HOME/
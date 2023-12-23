# aws related CLI installation and configuration

This documentation is tested on Ubuntu 20.04. and on macOS 12.

I use the MacPorts package manager on macOS, I recommend it to users who are also coming from Linux background.

## awscli

**Installation on Linux**

Only version 1 of awscli is available via packages, so I used the official method and there is no builtin upgrade like for regular packages.

Installation:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

The default values are these, it's possible to install to user's home directory without sudo

```bash
./aws/install --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin
```

Autocompletion:

Add the following line to ~/.bashrc

```bash
complete -C '/usr/local/bin/aws_completer' aws
```

**Installation on macOS with Macports**

Installation:

The default installer is similar to the Linux, but I use Macports as package manager.

The port select command needs the actual version as the second parameter!

```bash
sudo port install py-awscli2
sudo port select --set awscli py310-awscli2
```

'''Installation on macOS with aws installer'''

This is the official method for current user without sudo rights.

First create an xml file, name it choices.xml, replace the /Users/myusername with the target path where the aws-cli directory will be created.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <array>
    <dict>
      <key>choiceAttribute</key>
      <string>customLocation</string>
      <key>attributeSetting</key>
      <string>/Users/myusername</string>
      <key>choiceIdentifier</key>
      <string>default</string>
    </dict>
  </array>
</plist>
```

Download the installer and run it with the custom xml config.

```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"

installer -pkg AWSCLIV2.pkg -target CurrentUserHomeDirectory -applyChoiceChangesXML choices.xml
```

Create symlinks or modify path variable for aws cli. I this example  create symlinks to my personal bin directory which already created and added to PATH variable.

```bash
ln -s /Users/myusername/aws-cli/aws /Users/myusername/bin/aws
ln -s /Users/myusername/aws-cli/aws_completer /Users/myusername/bin/aws_completer
```

Autocompletion:

Add the following lines to ~/.zshrc

```bash
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit
complete -C '/opt/local/bin/aws_completer' aws
```

**configuration**

My configuration file:

```ini
[profile username]
region = eu-north-1
output = table
cli_auto_prompt = on

[profile service_role]
source_profile = username
role_arn = arn:aws:iam::****:role/service-role
mfa_serial = arn:aws:iam::****:mfa/username
```

The most readable output types are table and yaml.

cli_auto_prompt will provide dropdown lists of commands and parameters, it's a bit different from tab autocompletion.

## terraform

Terraform is used by me to create infrastructure as code (instead of cloudformation).

**Installation on Linux**

Installation:

```bash
sudo apt-get install -y gnupg software-properties-common
curl -L https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
echo "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install terraform
```

Autocompletion:

```bash
touch ~/.bashrc
terraform -install-autocomplete
```

**Installation on macOS with Macports**

I use the MacPorts package manager, the official documentation recommends Homebrew which is similar software.

Installation:

The port select command needs the actual version as the second parameter!

```bash
sudo port install terraform-1.3
sudo port select --set terraform terraform1.3
```

'''Installation on macOS with Homebrew'''

Add the terraform package repository

```bash
brew tap hashicorp/tap
```

Install package

```bash
brew install hashicorp/tap/terraform
```

'''Autocompletion:'''

```bash
touch ~/.zshrc
```

If the .zshrc doesn't contain this line then add it:

```bash
echo "autoload -Uz compinit && compinit" >> ~/.zshrc
```

Then set up the autocompletion:

```bash
terraform -install-autocomplete
```

## jq

jq is used to manipulate awscli json output for example convert access tokens to proper format for the configuration files.

**Installation on Linux**

```bash
sudo apt-get install jq
```

**Installation on macOS**

```bash
sudo port install jq
```

## ennvironment variables

These variables are used in the documentation and in the json files, it safe to simply replace the example commands with the values also.

The variable names don't have AWS_ prefix to prevent collision with official AWS variables. For example there is AWS_REGION for general use and REGION for these examples only.

```bash
export ACCOUNT_ID="used aws account ID without dash characters"
export TERRAFORM_BUCKET_NAME="s3 bucket to hold terraform files"
export GIT_REPO_ROOT="the path to the root of the git repository in the file system"
export PROJECT_NAME="name of the actual project eg. dvdstore" 
export REGION="region for s3 bucket"
export USER_NAME="name of the user who will be the developer"
export CLOUDTRAIL_BUCKET_NAME="s3 bucket to hold cloudtrail logs"
```

Additionally it's possible to add these into a separate file (like) and source the variables:

```bash
source ${GIT_REPO_ROOT}/general/scripts/environment_variables.sh 
```

Or add the variables to the users .profile, .bashrc, etc.

# aws related CLI installation and configuration

This documentation is tested on Ubuntu 20.04. and on macOS 12.

I use the MacPorts package manager on macOS, I recommend it to users who are also coming from Linux background.

## awscli

### Installation on Linux

Only version 1 of awscli  is available via packages, so I used the official method and there is no builtin upgrade like for regular packages.

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

### Installation on macOS

Installation:

The default installer is similar to the Linux, but I use Macports as package manager.

The port select command needs the actual version as the second parameter!

```bash
sudo port install py-awscli2
sudo port select --set awscli py310-awscli2
```

Autocompletion:

Add the following lines to ~/.zshrc

```bash
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit
complete -C '/opt/local/bin/aws_completer' aws
```

### configuration

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

### Installation on Linux

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

### Installation on macOS

I use the MacPorts package manager, the official documentation recommends Homebrew which is similar software.

Installation:

The port select command needs the actual version as the second parameter!

```bash
sudo port install terraform-1.3
sudo port select --set terraform terraform1.3
```

Autocompletion:

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

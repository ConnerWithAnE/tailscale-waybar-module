# Tailscale Waybar Module
A simple and sleek Waybar module for Tailscale that shows your current status, toggles on click and allows for quick and easy login when needed
<img width="654" height="27" alt="image" src="https://github.com/user-attachments/assets/2fafe561-d941-477a-beba-58b82aca7efe" />

## How it works
This module uses the tailscale cli commands to enable, disable and get the status of aspects of the tailnet. A custom icon is implemented via css and icon images stored in the `icons` sub directory.

## Display Options

### - Text
By default the module has text enabled and will display whether you are **Connected**, **Disconnected** or **Logged Out***.

<img width="114" height="25" alt="image" src="https://github.com/user-attachments/assets/a48df60d-46dd-40d0-b47d-11dbffa9863f" />

<img width="132" height="25" alt="image" src="https://github.com/user-attachments/assets/850262e3-dca8-4efc-a57a-f45908705196" />

<img width="115" height="25" alt="image" src="https://github.com/user-attachments/assets/d78dca63-42ee-40ab-b380-39828824e9f5" />

### - Logos
It is also possible to disable the text and just have the logo, but then you only get the connected and disconnected indicators. (Except for the tooltip)

<img width="25" height="25" alt="image" src="https://github.com/user-attachments/assets/04a3937b-9b80-47ba-8942-bd8e60b1263e" />  <img width="25" height="25" alt="image" src="https://github.com/user-attachments/assets/a52fedf0-dbe7-4fa2-ba0a-1b57a920a95f" />

### - Tooltips
Depending on your status the tooltip will display different information. 
#### Connected
The Tailnet IP will be shown

<img width="144" height="73" alt="image" src="https://github.com/user-attachments/assets/842a432e-d9b6-4a90-a830-39c692b42d00" />

#### Disconnected
The current status is shown

<img width="130" height="80" alt="image" src="https://github.com/user-attachments/assets/374224cd-d39b-4add-b3ec-669405f0c0e5" />

#### Logged Out
A prompt informing the user to 'Click to Login' is shown (This only works if the `tailscale set --operator` is set, how to permentatnyl enable this is shown in the [Configuration](#configuration) section below).

<img width="150" height="78" alt="image" src="https://github.com/user-attachments/assets/61916de7-16c0-432a-99d6-c8fc0da0b3cc" />

## Interactions

Really there is only one type of interaction, left click. When a user is logged into Tailscale and clicks on the module their connection state will be toggled, if the user is logged out a browser window will be opened to perform the authentication. Once authentication is complete the module will automatically update to **Connected**. 

The click to login function only works if `tailscale set --operator=$USER` is set or tailscale is configured to not need it, this is explain in the [Configuration](#configuration) section below.



## Requirements
- [Waybar](https://github.com/Alexays/Waybar)
- [Tailscale](https://tailscale.com/kb/1031/install-linux)
- [jq](https://jqlang.org/)
- [libnotify](https://gitlab.gnome.org/GNOME/libnotify)
**Optional**
- A notifier agent

## Installation

First ensure that you have all of the dependencies.

Next, to install the module either clone or download the repo to `$HOME/.config/waybar/tailscale`. You can also set the tailscale operator which will remove the `sudo` requirement. 
```sh
sudo tailscale set --operator=$USER
```
This will need to be done each time you are logged out of tailscale, there is a way to avoid needing to do this and it is explained in the configuration section

## Configuration

There are a few different areas which need to be configured all dependent how you want the module to function

### Sudo Priveledves

To enable the module to login on click Tailscale must be given the ability to run without sudo. This can be done by running
```sh
sudo tailscale set --operator=$USER
```
But this needs to be run EACH time the user is logged out. The module will not crash if this is not set but it will not complete the login. The user will be notified that the operation cannot be completed and the value can either be set and then the login attempted again or the login can be done manually.

The other option is to allow tailscale to execute sudo commands without a password. This *can* lower your overall system security but this is left up to your own discretion. To do this you need to edit `/etc/sudoers`. First ensure that you either have `vi` installed or you have a text editor (vim, nvim, nano) set (`export EDITOR=vim`).

Find where Tailscale is installed with 
```sh
which tailscale
```
It is often installed at `/usr/bin/tailscale`

Next run `sudo visudo` to open the sudoers file. This can really be put anywhere but to keep things consistent find the 'User priviledge specification' section. Now enter a new rule
```sh
<your-user-name> ALL=(ALL) NOPASSWD: /usr/bin/tailscale
```
and save the file. Now when you click on the tailscale module to login, the current user will be set to the operator (if it is not already set).


### Configuring the Module

The application comes with its own configuration file called `config.json` located at `$HOME/.config/waybar/tailscale/config.json`. The location can be altered by changing the config_file variable in `tailscale.sh`.

| key | Function |
|-----|----------|
| `tailscale-up-flags` | This is a list of flags which will be used when a tailscale connection is made. By default the flag `--accept-routes` is set (just because this is something I need) |
| `display-status-text` | This is boolean, if `true` **Connected**, **Disconnected** and **Logged Out** will be displayed alongside the logo |

### Adding to the Waybar Config

Finally the module needs to be added to the Waybar `config.jsonc` file. There is an example configuration provided in `waybar-config-example.jsonc` but it will also be shown below.

Edit the `waybar/config.jsonc` file and add the following to the bottom as a custom module
```jsonc
"custom/tailscale": {
  "format" : "{}",
  "return-type": "json",
  "on-click" : "$HOME/.config/waybar/tailscale/tailscale.sh toggle",
  "restart-interval": 0, // Set to 0 for faster updates
  "exec" : "$HOME/.config/waybar/tailscale/tailscale.sh status"
}
```
ensure it is named `custom/tailscale` as this is what the custom css looks for.
The 'restart-interval` can be increased but it will of course cause there to be a delay when updating.

Now insert the module on the bar
```jsonc
"modules-right": [
  "custom/tailscale"
]
```



# depenguin-builder

Build tool for custom mfsBSD images

## How to use

### Clone this repo
```
git clone --recurse-submodules https://github.com/depenguin-me/depenguin-builder.git
```

### Set your remote host settings
Set remote host settings in ```~.ssh/config```, then set remote host and path as follows:
```
cd depenguin-builder
cp settings.sh.sample settings.sh
```
and configure `settings.sh`
```
#!/usr/bin/env bash
CFG_SSH_REMOTEHOST="your.remote.host"
CFG_SSH_REMOTEPATH="/path/to/www"
```
The script will ```scp``` the output image file to the location specified if set to do so with the ```-u``` parameter.

### Configure your local customisations
You can edit the files in ```customfiles/*``` to make flavour changes for `depenguin-me`. 

### Configure variables in build script
You can set various parameters in the build script, such as output filename and source files.

### Run the build script
When ready run the build script. On first run it will download the FreeBSD-DVD install disk at 4GB!

To build the basic setup and upload to your remote destination:
```
chmod +x build.sh
./build.sh -u
```

# depenguin-builder

Build tool for custom mfsBSD images

Work in progress!

## How to use

### Clone this repo
```
git clone https://github.com/depenguin-me/depenguin-builder.git
```

### Set your remote host settings
Set remote host settings
```
cd depenguin-builder
cp settings.cfg.sample settings.cfg
```
and configure your details in `settings.cfg`
```
remoteuser="username"
remotehost="your.remote.host"
remoteport="22"
remotepath="/path/to/www/files/"
```
The script will ```scp``` the output image file to the location specified if set to do so.

### Configure your local customisations
You can edit the files in ```customfiles/*``` to make flavour changes for `depenguin-me`. 

### Configure variables in build scriot
You can set various parameters in the build script, such as output filename and source files.

### Run the build script
When ready run the build script. On first run it will download the FreeBSD-DVD install disk at 4GB!

To build the basic setup and upload to your remote destination:
```
./build.sh -u 1
```


# depenguin-builder
Build tool for custom mfsBSD images

## How to use

### Clone this repo
Clone the report with the submodules command:

    git clone --recurse-submodules \
    https://github.com/depenguin-me/depenguin-builder.git

### Set your remote host settings
Set remote host settings in `~/.ssh/config`:

    Host depenguin-me-builder
      User myuser
      HostName myactualhost.example.org
      IdentityFile ~/.ssh/id_rsa

Then set remote host and path in `settings.sh`; this file must be created:

    cd depenguin-builder
    cat >settings.sh <<EOF
    CFG_SSH_REMOTEHOST="your.remote.host"
    CFG_SSH_REMOTEPATH="/path/to/www"
    EOF

The script will `rsync` the output image file to the location specified when
the `-u` flag is added to `build.sh`.

### Configure your local customisations
Optionally edit the files in `customfiles/*` to make flavour changes for `depenguin-me`. 

### Configure custom packages
You can edit the file `customfiles/depenguin_packages.txt` if you have additional packages to include. 

Beware file size of resulting image is a potential concern, see mfsBSD documentation.

### Configure variables in build script
Optionally configure variables in `build.sh`, such as output filename and
source files.

### Run the build script
When ready, run `build.sh` with flags.

> First-time script is run will download a FreeBSD install cd at 750MiB!

To build the basic setup and upload to your remote destination:

    ./build.sh -u 14.2

End of File

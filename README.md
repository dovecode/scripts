# Scripts
This repository contains a variety of scripts that I use in various places.

```
├── badblocks.sh              # Stress-test and check a hard drive before adding it to the NAS
├── ssh-agent-bridge.sh       # Launch socket bridge to PLINK to Windows named pipe for Windows OpenSSH Agent
├── usbcheck.sh               # 
└── movies                    # Various movie-related scripts
    ├── change-show-name.sh   # Locate TV Show and rename its directory and all files
    ├── checkshasum.sh        # Check the SHA-256 sum for all files in the tree
    ├── doitall.sh            # Run reorg.sh, mkshasum.sh, syncFromDufva.sh and remotecheck.sh in sequence
    ├── reorg.sh              # Move any movie or show files in the current directory to its according video directory
    ├── mkshasum.sh           # Create SHA-256 sum files for all video files in video directories
    ├── syncFromDufva.sh      # Synchronize all video files from this host to bananas
    ├── remotecheck.sh        # Remotely check SHA-256 sums on bananas
    ├── syncFromAlex.sh       # 
    ├── parallelizeit.sh      # 
    ├── fix-utf8.sh           # 
    ├── fixshasums.sh         # 
    ├── util-progress.sh      # Utility script that provides a progress bar
    └── util-videos.sh        # Utility script that defines common info for movie scripts (extensions and dirs)
```

# README

This repository contains a Golang program for securely deleting files using the shred command and a setup script for setting up a Linux image using QEMU.

## Get the Repo


1. Clone the repository:

```
bash git clone https://github.com/Chake96/interview_submissions.git
```

## Build and Run the Shred Program

To build and run the shred program, follow these steps:

1. CD into the Shred Directory

```
cd interview_submissions/canonical/shred
```

2. Build and run test program

```
go build test .
```



## Run the QEMU Linux Image

To build and run the shred program, follow these steps:

1. CD into the Core Directory

```
cd interview_submissions/canonical/core
```
2. Ensure the Script is Executable
```
chmod +x setup.sh
```

3. Run the script

```
./setup.sh
```
### Post Steps and Troubleshoot
#### if you want to get rid of the downloaded files or you are running into other issues:
```
./clean.sh
```
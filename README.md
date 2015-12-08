# Simple helper script for [acme-tiny](https://github.com/diafygi/acme-tiny/)
Personal helper script to run acme-tiny for multiple domains in one run.  

After cloning run `git submodule update --init --recursive` to clone the submodules  
or clone with `git clone --recursive https://github.com/farfelu/acme-tiny-helper.git`

## config
it reads domains and settings from *config.cfg*  
see *config.example.cfg*

## files
files in *certificates/example.com/*

| file          | description                                                                 |
|---------------|-----------------------------------------------------------------------------|
| privkey.key   | private key                                                                 |
| request.csr   | request file                                                                |
| cert.pem      | certificate itself                                                          |
| fullchain.pem | certificate and the letsencrypt certificate in one file  required for nginx |

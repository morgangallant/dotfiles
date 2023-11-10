#!/bin/bash

# Run on initial setup for a new macOS machine
sudo scutil --set HostName mbp
sudo scutil --set LocalHostName mbp
sudo scutil --set ComputerName mbp
dscacheutil -flushcache

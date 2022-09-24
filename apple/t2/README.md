# NixOS Support for Macs with T2 Chips

This is based on the [T2 Linux Project](https://t2linux.org).

For a complete list of Macs with T2 chips see [this link](https://support.apple.com/en-us/HT208862).

Currently everything except suspend works (which is disabled by default) out of the box.

## Installation
Since the keyboard driver and the changes to the WiFi driver are not mainlined yet, you cannot install NixOS from the official iso's without an external keyboard and another way of connecting to internet. You can get a prebuilt iso from the releases page of [this repo](https://github.com/kekrby/nixos-t2-iso).

The rest is same as any NixOS installation, just don't forget to import this module in your `configuration.nix`!

## Firmware
T2 Macs require firmware for WiFi (the models with the BCM4377 chip also need firmware for bluetooth). Because the firmware is not provided with a redistrubutable license, you have to get it from macOS. How to do that, along with other things, is explained in detail at the [installation guide](https://wiki.t2linux.org/distributions/nixos/installation/).

# NixOS Support for Macs with T2 Chips

This is based on the [T2 Linux Project](https://t2linux.org).

For a complete list of Macs with T2 chips see [this link](https://support.apple.com/en-us/HT208862).

Currently everything except audio (on certain models) and suspend works (which is disabled by default) out of the box and audio can be configured easily.

## Installation
Since the keyboard driver and the changes to the WiFi driver are not mainlined yet, you cannot install NixOS from the official iso's without an external keyboard and another way of connecting to internet. You can get a prebuilt iso from the releases page of [this repo](https://github.com/kekrby/nixos-t2-iso).

The rest is same as any NixOS installation, just don't forget to import this module in your `configuration.nix`!

## Audio
On certain Macs, you need have to set the `hardware.apple.t2.audioModel` to get audio working, most models don't need this though. See `default.nix` for the list of models that do require the option being set for audio to function correctly.

Support for both PulseAudio and PipeWire is included, but you should prefer using PipeWire as it works much better unless you have other reasons. For example, on this machine PulseAudio does not work at all with headphones while PipeWire works flawlessly.

## Firmware
T2 Macs require firmware for WiFi (the models with the BCM4377 chip also need firmware for bluetooth). The firmware will be extracted from Apple's official recovery images which might take a while (`building <...>.dmg`) but this will only happen during the initial build and won't happen if you install from a prebuilt iso. The firmware package (`pkgs.t2-firmware`) is unfree and `nixpkgs.config.allowUnfreePredicate` is set to a function that allows it to be installed.

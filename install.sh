#!/bin/bash

pkg update && pkg upgrade
pkg install sdl2 sdl2-image sdl2-mixer sdl2-ttf freetype libjpeg-turbo libpng
pip3 install pygame

### Table of contents

- [Energy-Core-reader](#energy-core-reader)
- [Computer setup](#computer-setup)
  * [standalone.lua](#standalonelua)
  * [host.lua and client.lua](#hostlua-and-clientlua)
- [Installing programs to OpenComputers computer](#installing-programs-to-opencomputers-computer)
- [Running the program](#running-the-program)



# Energy-Core-reader
This repository contains three LUA programs that read the amount of energy stored inside an Energy Core multiblock object from Minecraft mod Draconic Evolution. The code is run by using another Minecraft mod, OpenComputers.

The programs have been tested to work on Minecraft version 1.12.2.

![2022-02-23_16 50 50](https://user-images.githubusercontent.com/59032142/155346665-d7bae10a-b199-4030-9627-ae6e7751829f.png)

The code is split into three pieces with quite self explanatory names:
- standalone.lua
- client.lua
- host.lua



# Computer setup
Build your computer like shown on the tutorial [here](https://ocdoc.cil.li/tutorial), or follow the tutorial found on the book item "OpenComputers Manual" inside the game.

Other than that, you require an Adapter block from OpenComputers to be directly connected to Energy Pylon block Draconic Evolution like in the following picture **on the computer that reads the contents of the core**. The connected computer will read the energy contents.

![2022-02-23_16 51 18](https://user-images.githubusercontent.com/59032142/155346751-b8393bf0-9c4f-4b40-b898-0150ae019630.png)

## standalone.lua

This program will run on a computer directly connected to the the core. The computer will read the contents, and show it on the screen. Thus it provides easy access to the contents of the core but allows only one computer to monitor the state of the core at a time.

## host.lua and client.lua

These version allows multiple computers to simultaneously monitor the contents of the core. People in different locations will be able to monitor energy status from remote locations. As if there were a centralized energy storage on a server and multiple people siphoning energy from it.

![2022-02-23_17 19 11](https://user-images.githubusercontent.com/59032142/155349064-2d5a8bb9-80be-460b-b3c3-27d0bca15ed5.png)

By connecting multiple computers through a relay block from OpenComputers, the computers are able to communicate with each other through "internet", using Network Cards. The computers running the Client program will try to search for a computer running the Host program. Upon finding the Host, they will start polling for updates every 5 seconds.

![2022-02-23_16 52 20](https://user-images.githubusercontent.com/59032142/155349288-09732fe7-6294-4ec3-8252-378ed02a00ad.png)



# Installing programs to OpenComputers computer
Easiest way to install a program to these virtual computers is by using wget on the computer like with the following commands. Simply copy the command into your clipboard and press middle mouse button when using the computer. This will store the program as a {name}.lua file into the home directory.

> wget https://raw.githubusercontent.com/mrlaresi/Energy-Core-reader/main/standalone.lua

> wget https://raw.githubusercontent.com/mrlaresi/Energy-Core-reader/main/client.lua

> wget https://raw.githubusercontent.com/mrlaresi/Energy-Core-reader/main/host.lua

Another way is to copy the contents of one of the files found on this repository. Then open the editor on your computer using 
> edit {program_name}

and middle mouse click to paste your code into the computer. Then simply ctrl-s and ctrl-w to save.



# Running the program
Simply type the programs name like ***standalone*** into the pc and it will start.
